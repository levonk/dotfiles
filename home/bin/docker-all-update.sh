#!/bin/bash

# Script to update Docker containers and images with extensive options.

set -euo pipefail

# --- Configuration ---

SCRIPT_NAME="docker-all-update"
XDG_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CONTAINERS_IGNORE_FILE="${XDG_CONFIG_DIR}/bin/${SCRIPT_NAME}/containers-ignore.txt"  # Changed extension
IMAGES_IGNORE_FILE="${XDG_CONFIG_DIR}/bin/${SCRIPT_NAME}/images-ignore.txt"    # Changed extension

DRY_RUN=false  # Default: Check Only (Notify)
CHECK_ONLY=true #Explicit Flag -This is default
PULL_ONLY=false
PULL_RESTART=false
ALL_CONTAINERS_IMAGES=true #Default.
IMAGES_ONLY=false
CONTAINERS_ONLY=false
CONTAINERS_SCOPE="all" # "all", "running", "stopped"
IMAGES_SCOPE="all" # "all", "used", "unused"

IGNORE_INI_IMAGES=""
IGNORE_INI_CONTAINERS=""

# --- Helper Functions ---

log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S'): $1"
}

# Function to check if Docker is installed
check_docker_installed() {
  if ! command -v docker &> /dev/null; then
    log "ERROR: Docker is not installed. Please install Docker before running this script."
    exit 1
  fi
  return 0
}

# Function to read ignore list from text file (one entry per line), supporting comments.
read_ignore_list() {
  local file="$1"
  local array_name="$2"  # Name of the array to populate (e.g., `ignored_images`)
  declare -g "$array_name" # Declare the array as global
  eval "$array_name=()"     # Initialize the array

  if [[ -f "$file" ]]; then
    while IFS= read -r line; do
      line="${line%%#*}"   # Remove comments (if any)
      line=$(echo "$line" | tr -d '[:space:]')  # Trim whitespace
      if [[ -n "$line" ]]; then #Ignore empty lines
        eval "$array_name+=(\"$line\")"  # Add the value to the array
      fi
    done < "$file"
    log "Loaded ignore list from: $file"
  else
    log "Ignore file not found: $file"
  fi
}

# Function to check if an item is ignored
is_ignored() {
  local item="$1"
  local ignore_list_array="$2"

  for ignored_item in "${!ignore_list_array[@]}"; do
     if [[ "$item" == "${ignore_list_array[$ignored_item]}" ]]; then
      return 0 # Item is ignored
    fi
  done
  return 1 # Item is not ignored
}

# Function to check if an image is updatable. This function only reports what *could* be done and does not do any changes unless a pull or restart is initiated
is_image_updatable() {
  local image_name="$1"
  local current_image_id

  if is_ignored "$image_name" "ignored_images[@]"; then
    log "Image '$image_name' is ignored. Skipping."
    return 1
  fi

  current_image_id=$(docker images -q "$image_name")

  if [[ -z "$current_image_id" ]]; then
    log "Image '$image_name' not found locally.  Skipping."
    return 1 # Image not found. Not updatable.
  fi

  local new_image_id=$( docker inspect --type=image "$image_name" --format '{{.Id}}' 2>/dev/null ) #Get latest online image ID

  if [[ "$new_image_id" != "$current_image_id" ]]; then
      log "Image '$image_name' has an update available. Local: $current_image_id, Remote: $new_image_id"
  else
      log "Image '$image_name' is already up to date."
  fi

  return 0 # Image found, proceed to update check
}

# Function to update an image
update_image() {
  local image_name="$1"
  local restart_required=false

  log "Updating image: $image_name"

  if ! is_image_updatable "$image_name"; then
     return 1
  fi

  local current_image_id=$(docker images -q "$image_name")

  if $DRY_RUN; then
      log "Dry-run: Would pull image '$image_name'"
  else
      docker pull "$image_name"
  fi

  if [[ $? -ne 0 ]]; then
    log "Failed to pull image: $image_name"
    return 1
  fi

  # Check if image ID changed (meaning an update occurred)
  local new_image_id=$(docker images -q "$image_name")
  if [[ "$new_image_id" != "$current_image_id" ]]; then
      restart_required=true
      log "Image '$image_name' updated."
  else
      log "Image '$image_name' is already up to date."
  fi

  if $restart_required && $PULL_RESTART && ! $DRY_RUN; then #Check DRY_RUN so restarting does not happen with --dry-run flag
    restart_containers_using_image "$image_name"
  fi
}

# Function to restart containers that use a specific image.
restart_containers_using_image() {
    local image_name="$1"
    local containers_to_restart

    containers_to_restart=$(docker ps -aqf "ancestor=$image_name")

    if [[ -z "$containers_to_restart" ]]; then
      log "No running containers found using image '$image_name'."
      return 0
    fi

    log "Found containers using image '$image_name': $containers_to_restart"

    for container_id in $containers_to_restart; do
        restart_container "$container_id"
    done
}


# Function to restart a single container.
restart_container() {
    local container_id="$1"
    local container_name

    container_name=$(docker inspect --format='{{.Name}}' "$container_id" | sed 's/^.//;s/.$//') #Extract the name

    # Check if the container is in the ignore list
    if is_ignored "$container_name" "ignored_containers[@]"; then
      log "Container '$container_name' is ignored. Skipping."
      return 1
    fi


    log "Restarting container: $container_name ($container_id)"

    # Check if the container is managed by Docker Compose.
    local compose_file=$(docker inspect --format='{{index .Config.Labels "com.docker.compose.project.config_files"}}' "$container_id" 2>/dev/null)
    if [[ -n "$compose_file" ]]; then
      # If managed by Compose, restart using docker-compose.
      local compose_project_name=$(docker inspect --format='{{index .Config.Labels "com.docker.compose.project"}}' "$container_id")

      if [[ -z "$compose_project_name" ]]; then
          log "ERROR: Could not determine Docker Compose project name for container $container_id. Skipping compose restart."
          return 1
      fi

      local compose_dir=$(dirname "$compose_file") # Extract directory so -f works correctly.
      pushd "$compose_dir" > /dev/null # Change directory temporarily

      if $DRY_RUN; then
          log "Dry-run: Would execute docker-compose -p $compose_project_name -f \"$compose_file\" up -d"
      else
          docker-compose -p "$compose_project_name" -f "$compose_file" up -d
      fi

      popd > /dev/null  # Return to original directory
    else
        # If not managed by Compose, restart using docker run (more complex)

        local container_config=$(docker inspect "$container_id")

        if $DRY_RUN; then
          log "Dry-run: Would try to restart the container with docker run (not implemented in dry-run)"
        else
            # Fetch the essential information from the existing container
            local image_name=$(echo "$container_config" | jq -r '.[0].Config.Image')
            local port_mappings=$(echo "$container_config" | jq -r '.[0].HostConfig.PortBindings | to_entries | map("\(.key):\(.[].HostPort)") | join(" -p ")')
            local volume_mounts=$(echo "$container_config" | jq -r '.[0].Mounts | map("--mount type=\(.Type),source=\(.Source),target=\(.Destination)") | join(" ")')
            local env_vars=$(echo "$container_config" | jq -r '.[0].Config.Env | map("--env \(. | split("=",2) | first)=\(. | split("=",2) | last)") | join(" ")')
            local entrypoint=$(echo "$container_config" | jq -r '.[0].Config.Entrypoint | join(" ")')
            local cmd=$(echo "$container_config" | jq -r '.[0].Config.Cmd | join(" ")')
            local restart_policy=$(echo "$container_config" | jq -r '.[0].HostConfig.RestartPolicy.Name')

            log "Using image '$image_name', and trying to reconstruct docker run arguments."

            # Construct the docker run command.
            local docker_run_command="docker run -d --name \"$container_name\" --restart $restart_policy $port_mappings $volume_mounts $env_vars $image_name $entrypoint $cmd" #Recreate the command.

            # Stop the container
            docker stop "$container_id"

            # Remove the container
            docker rm "$container_id"

            #Run the docker run command.
            eval "$docker_run_command"

        fi
    fi
}

# --- Argument Parsing ---
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
      -d|--dry-run)
        DRY_RUN=true
        CHECK_ONLY=false # Override CHECK_ONLY. --dry-run specifies the intention to change the system if specified
        PULL_ONLY=false
        PULL_RESTART=false
        shift
        ;;
      --check-only)
        DRY_RUN=false
        CHECK_ONLY=true
        PULL_ONLY=false
        PULL_RESTART=false
        shift
        ;;
      -p|--pull-only)
        DRY_RUN=false
        CHECK_ONLY=false
        PULL_ONLY=true
        PULL_RESTART=false
        shift
        ;;
      --pull-restart)
        DRY_RUN=false
        CHECK_ONLY=false
        PULL_ONLY=false
        PULL_RESTART=true
        shift
        ;;
      --all-containers-images)
        ALL_CONTAINERS_IMAGES=true
        IMAGES_ONLY=false
        CONTAINERS_ONLY=false
        shift
        ;;
      --images-only)
        ALL_CONTAINERS_IMAGES=false
        IMAGES_ONLY=true
        CONTAINERS_ONLY=false
        shift
        ;;
      --containers-only)
        ALL_CONTAINERS_IMAGES=false
        IMAGES_ONLY=false
        CONTAINERS_ONLY=true
        shift
        ;;
      --containers-scope)
        CONTAINERS_SCOPE="$2"
        shift
        shift
        ;;
      --images-scope)
        IMAGES_SCOPE="$2"
        shift
        shift
        ;;
      --ignore-file-images)
          IGNORE_INI_IMAGES="$2" #Keep same variable and logic
          shift
          shift
          ;;
      --ignore-file-containers)
          IGNORE_INI_CONTAINERS="$2" #Keep same variable and logic
          shift
          shift
          ;;
      *) # Specific images
        if [[ "$key" == "--" ]]; then
           shift # Skip over --
           break
        fi
        IMAGES+=("$key")
        shift
        ;;
    esac
  done

  #Validate CONTAINER_SCOPE and IMAGES_SCOPE
  if [[ "$CONTAINERS_SCOPE" != "all" && "$CONTAINERS_SCOPE" != "running" && "$CONTAINERS_SCOPE" != "stopped" ]]; then
    echo "ERROR: Invalid value for --containers-scope. Must be 'all', 'running', or 'stopped'."
    exit 1
  fi

  if [[ "$IMAGES_SCOPE" != "all" && "$IMAGES_SCOPE" != "used" && "$IMAGES_SCOPE" != "unused" ]]; then
      echo "ERROR: Invalid value for --images-scope. Must be 'all', 'used', or 'unused'."
      exit 1
  fi

  # Check for conflicts between check-only and other actions
  if $CHECK_ONLY && ( $PULL_ONLY || $PULL_RESTART ); then
     echo "ERROR: --check-only cannot be combined with --pull-only or --pull-restart"
     exit 1
  fi
}

# --- Main Script Logic ---

# Critical path check for docker
check_docker_installed

# Load Ignore Lists (using command line overrides where provided)
read_ignore_list "${IGNORE_INI_IMAGES:-$IMAGES_IGNORE_FILE}" "ignored_images[@]" #Change Variable Name
read_ignore_list "${IGNORE_INI_CONTAINERS:-$CONTAINERS_IGNORE_FILE}" "ignored_containers[@]" #Change Variable Name

log "Starting Docker update script..."

parse_arguments "$@"

# Process Images
if [[ $ALL_CONTAINERS_IMAGES == true || $IMAGES_ONLY == true ]]; then
  log "Processing Images..."

  if [[ -n "${IMAGES[@]}" ]]; then
    #Specific Images Specified
    log "Processing specified images: ${IMAGES[@]}"
    for image in "${IMAGES[@]}"; do
      if $CHECK_ONLY || $DRY_RUN; then
        is_image_updatable "$image" #Call to function to report
      else
        update_image "$image" #Call to update image
      fi
    done
  else
    log "Processing all images (based on scope)"
    # Process based on IMAGES_SCOPE
    case "$IMAGES_SCOPE" in
      "all")
        image_list=$(docker images --format "{{.Repository}}:{{.Tag}}")
        ;;
      "used")
        image_list=$(docker images --format "{{.Repository}}:{{.Tag}}" $(docker ps -q | xargs echo)) #Get used images
        ;;
      "unused")
          image_list=$(docker images --format "{{.Repository}}:{{.Tag}}" --filter "dangling=true") #Get unused images
          ;;
    esac

    if [[ -z "$image_list" ]]; then
      log "No images found matching the selected scope."
    else
      for image in $image_list; do
        if $CHECK_ONLY || $DRY_RUN; then
          is_image_updatable "$image" #Call to function to report
        else
          update_image "$image" #Call to update image
        fi
      done
    fi
  fi
fi

# Process Containers
if [[ $ALL_CONTAINERS_IMAGES == true || $CONTAINERS_ONLY == true ]]; then
  log "Processing Containers..."

  # Determine container scope
  case "$CONTAINERS_SCOPE" in
    "all")
      container_ids=$(docker ps -aq)
      ;;
    "running")
      container_ids=$(docker ps -q)
      ;;
    "stopped")
      container_ids=$(docker ps -aq -f status=exited)
      ;;
  esac

  if [[ -z "$container_ids" ]]; then
    log "No containers found matching the selected scope."
  else
    for container_id in $container_ids; do
      container_name=$(docker inspect --format='{{.Name}}' "$container_id" | sed 's/^.//;s/.$//')
      if is_ignored "$container_name" "ignored_containers[@]"; then
          log "Container '$container_name' is ignored, skipping."
          continue
      fi

      if $PULL_RESTART && ! $DRY_RUN; then #Restart or skip, DRY_RUN will just notify the changes
        restart_container "$container_id"
      else
        log "Dry-run: Would restart container $container_name ($container_id)"
      fi
    done
  fi
fi

if $DRY_RUN; then
    log "Dry-run: No actions taken."
fi

log "Docker update script finished."

exit 0
