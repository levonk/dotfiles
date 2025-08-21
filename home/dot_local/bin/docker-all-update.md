# `docker-all-update.sh` - Docker Image and Container Management Tool

## Overview

`docker-all-update.sh` is a powerful and flexible Bash script designed to simplify the process of managing Docker images and containers on a system. It primarily checks to see if there are updates available on remote repositories and will report on the changes. To update images or containers, then additional flags will need to be specified. It offers a range of options to control which images and containers are checked, how they are updated, and provides a dry-run mode to preview changes before they are applied. The tool is designed to work with both standalone Docker containers and those managed by Docker Compose.

## Features

*   **Image and Container Version Check:**  Checks for newer Docker images.
*   **Docker Compose Support:**  Automatically detects and uses `docker-compose` to restart containers managed by Compose, preserving all Compose settings.
*   **Selective Checks:** Allows you to check all images, specific images, all containers, or a combination.
*   **Scoped Checks:** Provides options to limit checks to running containers, stopped containers, used images, or unused images.
*   **Ignore Lists:** Supports exclusion of specific containers and images via ignore lists, defined in text files.
*   **Dry-Run Mode:**  Offers a dry-run mode to preview the changes that would be made without actually executing any commands. If the `--dry-run` is specified with pull or restart options, then changes *WOULD* occur.
*   **Pull-Only Mode:**  Allows pulling new image versions without automatically restarting containers.
*   **Pull-Restart Mode:**  Allows pulling new image versions and automatically restarting containers.
*   **Command-Line Options:**  Provides a comprehensive set of command-line options to customize the management process.
*   **Docker Version Check:**  Verifies that Docker is installed before proceeding.
*   **Robust Error Handling:**  Uses `set -euo pipefail` to ensure that the script exits immediately if any command fails.
*   **Clear Logging:**  Logs all actions to provide a detailed audit trail.
*   **`XDG_CONFIG_DIR` Support:** Stores configuration files in the standard `$XDG_CONFIG_DIR` location.

## Requirements

*   **Docker:**  Must be installed and configured correctly.
*   **Bash:**  The script is written in Bash and requires a Bash interpreter.
*   **`docker-compose`:**  Recommended, if you manage containers with Docker Compose.
*   **`jq`:** needed for `docker run` reconstruction and should be installed, but will not break if it is not.
## Configuration

The script uses the following configuration files, stored in `$XDG_CONFIG_DIR/bin/docker-all-update/` (default: `$HOME/.config/bin/docker-all-update/`):

*   **`containers-ignore.txt`:**  A list of container names to exclude from updates (one name per line).
*   **`images-ignore.txt`:**  A list of image names to exclude from updates (one name per line).

The ignore files are simple text files with one entry per line:

```text
container-name-1
image-name-2:tag
```

Each line specifies an item to exclude from the update process.

## Usage

```bash
./docker-all-update.sh [options] [image1 image2 ...]
```

### Options

| Option                    | Long Form                  | Description                                                                                                                                                             |
| ------------------------- | -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `-d`                      | `--dry-run`                | Perform actions. Shows what *WOULD* be updated/restarted if specified. If not specified, the actions are not run.                                                               |
|                           | `--check-only`             | Check Only. Shows images available on remote repo.  This is the default behavior. `--pull-only` and `--pull-restart` should not be specified                                                                                                                                                    |
| `-p`                      | `--pull-only`              | Pull images but do not restart containers.                                                                                                                               |
|                           | `--pull-restart`           | Pull images and restart containers.                                                                         |
|                           | `--all-containers-images`  | Process all containers and images (subject to scope and ignore lists). This is the default scope.                                                                    |
|                           | `--images-only`            | Process only images (subject to scope and ignore lists).                                                                                                                  |
|                           | `--containers-only`        | Process only containers (subject to scope and ignore lists).                                                                                                               |
|                           | `--containers-scope <scope>` | Specifies the scope of containers to process.  `<scope>` can be `all`, `running`, or `stopped`.  Default is `all`.                                                        |
|                           | `--images-scope <scope>`   | Specifies the scope of images to process.  `<scope>` can be `all`, `used`, or `unused`. Default is `all`.                                                             |
|                           | `--ignore-file-images <file>`  | Specifies a custom path to the images ignore file.  Overrides the default location.                                                                              |
|                           | `--ignore-file-containers <file>`| Specifies a custom path to the containers ignore file. Overrides the default location.                                                                        |
| `[image1 image2 ...]`   |                           | Specific image names to check. If provided, only these images will be checked. If image names are not specified and if `--images-only` is not set, then images are not processed  |

### Examples

*   **Check for updates (check only - default):**

    ```bash
    ./docker-all-update.sh
    ```

*   **Explicitly check only:**

    ```bash
    ./docker-all-update.sh --check-only
    ```

*   **Pull images only (no restart):**

    ```bash
    ./docker-all-update.sh --pull-only
    ```

*   **Pull images and restart containers:**

    ```bash
    ./docker-all-update.sh --pull-restart
    ```

*   **Dry run pull images only (no restart):**

    ```bash
    ./docker-all-update.sh --pull-only --dry-run
    ```
*   **Dry run Pull images and restart containers:**

    ```bash
    ./docker-all-update.sh --pull-restart --dry-run
    ```

*   **Process containers only:**

    ```bash
    ./docker-all-update.sh --containers-only
    ```

*   **Process images only:**

    ```bash
    ./docker-all-update.sh --images-only
    ```

*   **Process all containers and images (default scope):**

    ```bash
    ./docker-all-update.sh --all-containers-images
    ```

*   **Process only running containers:**

    ```bash
    ./docker-all-update.sh --containers-scope running
    ```

*   **Process only stopped containers:**

    ```bash
    ./docker-all-update.sh --containers-scope stopped
    ```

*   **Process only used images:**

    ```bash
    ./docker-all-update.sh --images-scope used
    ```

*   **Process only unused images:**

    ```bash
    ./docker-all-update.sh --images-scope unused
    ```

*   **Update a specific image:**

    ```bash
    ./docker-all-update.sh nginx:latest
    ```

*   **Specify a different containers ignore file:**

    ```bash
    ./docker-all-update.sh --ignore-file-containers /path/to/my-containers-ignore.txt
    ```

*   **Combine options:**

    ```bash
    ./docker-all-update.sh --pull-restart --containers-scope running --images-scope used
    ```

    (Pulls and restarts, operating only on running containers and used images)

## Implementation Details

The script works by:

1.  **Parsing Command-Line Arguments:** The `parse_arguments` function handles all command-line options and sets the corresponding variables.
2.  **Reading Configuration Files:** The `read_ignore_list` function reads the ignore lists from the text files.
3.  **Identifying Images and Containers:** The script uses Docker commands to retrieve lists of images and containers, filtered by the specified scopes.
4.  **Check for updates:** The `is_image_updatable` function checks if images available on remote repo are more recent
5.  **Updating Images:** The `update_image` function pulls the latest version of an image from Docker Hub.
6.  **Restarting Containers:** The `restart_container` function stops and removes a container and then restarts it using either `docker-compose` (if the container is managed by Compose) or by reconstructing the original `docker run` command.
7.  **Logging:** The `log` function provides timestamped output for all actions.

## Important Notes and Cautions

*   **TEST THOROUGHLY:** This script makes potentially destructive changes to your system. Test it thoroughly in a non-production environment before using it on a production system. Use the dry-run feature (`-d` or `--dry-run`) to preview the changes before applying them.
*   **BACKUPS:** Before running the script, ensure you have backups of any critical data stored in Docker volumes. While the script attempts to preserve data, unexpected issues can always occur.
*   **Complexity:** The `docker run` reconstruction part is inherently complex and may not work perfectly for all container configurations. Carefully examine the output of the dry run and verify that the reconstructed `docker run` command is correct.
*   **Security:** Be extremely cautious about the images you update. Always use images from trusted sources. Regularly scan your images for vulnerabilities. Don't just blindly update everything without considering the security implications.
*   **Rolling Updates:** For production systems, consider using a more sophisticated rolling update strategy using tools like Kubernetes or Docker Swarm. This script provides a basic update mechanism, but it's not suitable for zero-downtime deployments.
*   **Docker Swarm:** If you are using Docker Swarm, this script will *not* work correctly. You will need to use the `docker service update` command to update your services.
*   **Permissions:** Make sure the script is run with a user that has sufficient permissions to run Docker commands (usually root or a user in the `docker` group).
*   **Data Volumes:** If you have volumes, make sure they are mounted correctly after the update. Double-check the dry-run output.
*   **Logging:** Consider adding more detailed logging to the script to help with debugging and troubleshooting.
*   **Network Configuration:** Be mindful of network configuration if you're using bridged networks. Make sure your containers are still able to communicate with each other after the update.

## Disclaimer

This script is provided as-is, without warranty of any kind. Use it at your own risk. The author is not responsible for any data loss or system damage caused by the use of this script. Always back up your data before making any changes to your system.
