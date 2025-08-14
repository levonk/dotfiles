#!/bin/bash
# Lazy Loading Utility for Dotfiles
# Purpose: Load optional modules only when needed to improve shell startup performance
# Shell Support: bash, zsh (POSIX-compliant where possible)
# Chezmoi: Managed by chezmoi, safe to source multiple times
# Security: No external calls, safe for all environments
# Extensibility: Can be extended with dependency tracking and auto-discovery

# Registry for lazy-loaded modules
declare -A DOTFILES_LAZY_MODULES 2>/dev/null || {
    # Fallback for shells without associative arrays
    DOTFILES_LAZY_MODULES=""
}

# Registry for loaded modules
declare -A DOTFILES_LOADED_MODULES 2>/dev/null || {
    DOTFILES_LOADED_MODULES=""
}

# Register a module for lazy loading
# Usage: register_lazy_module "module_name" "/path/to/module.sh" "command1,command2,alias1"
register_lazy_module() {
    local module_name="$1"
    local module_path="$2"
    local triggers="$3"
    local trigger
    
    # Validate input
    if [ -z "$module_name" ] || [ -z "$module_path" ]; then
        echo "Error: register_lazy_module requires module_name and module_path" >&2
        return 1
    fi
    
    # Validate module file exists
    if [ ! -r "$module_path" ]; then
        echo "Warning: Lazy module file not readable: $module_path" >&2
        return 1
    fi
    
    # Store module information
    if [ -n "${DOTFILES_LAZY_MODULES+x}" ] 2>/dev/null; then
        DOTFILES_LAZY_MODULES["$module_name"]="$module_path"
    else
        # Fallback for shells without associative arrays
        DOTFILES_LAZY_MODULES="$DOTFILES_LAZY_MODULES $module_name:$module_path"
    fi
    
    # Create trigger functions/aliases if specified
    if [ -n "$triggers" ]; then
        # Split triggers by comma and create lazy loaders
        echo "$triggers" | tr ',' '\n' | while IFS= read -r trigger; do
            trigger="$(echo "$trigger" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"  # trim whitespace
            if [ -n "$trigger" ]; then
                create_lazy_trigger "$trigger" "$module_name"
            fi
        done
    fi
    
    if [ -n "${DEBUG_SOURCING:-}" ]; then
        echo "Debug: Registered lazy module '$module_name' with triggers: $triggers" >&2
    fi
}

# Create a lazy trigger function
# Usage: create_lazy_trigger "command_name" "module_name"
create_lazy_trigger() {
    local trigger_name="$1"
    local module_name="$2"
    
    # Validate input
    if [ -z "$trigger_name" ] || [ -z "$module_name" ]; then
        return 1
    fi
    
    # Create the lazy trigger function dynamically
    # This creates a function that loads the module and then calls the real command
    eval "${trigger_name}() {
        if ! is_module_loaded \"$module_name\"; then
            load_lazy_module \"$module_name\"
        fi
        
        # Check if the real command/function exists after loading
        if command -v \"$trigger_name\" >/dev/null 2>&1 || type \"$trigger_name\" >/dev/null 2>&1; then
            # Unset our lazy loader and call the real command
            unset -f \"$trigger_name\" 2>/dev/null
            \"$trigger_name\" \"\$@\"
        else
            echo \"Error: Command '$trigger_name' not available after loading module '$module_name'\" >&2
            return 127
        fi
    }"
    
    if [ -n "${DEBUG_SOURCING:-}" ]; then
        echo "Debug: Created lazy trigger for '$trigger_name' -> '$module_name'" >&2
    fi
}

# Check if a module is already loaded
# Usage: is_module_loaded "module_name"
is_module_loaded() {
    local module_name="$1"
    
    if [ -z "$module_name" ]; then
        return 1
    fi
    
    # Check loaded modules registry
    if [ -n "${DOTFILES_LOADED_MODULES[$module_name]:-}" ] 2>/dev/null; then
        return 0  # Already loaded
    elif echo "$DOTFILES_LOADED_MODULES" | grep -q "$module_name" 2>/dev/null; then
        return 0  # Already loaded (fallback method)
    else
        return 1  # Not loaded
    fi
}

# Load a lazy module
# Usage: load_lazy_module "module_name"
load_lazy_module() {
    local module_name="$1"
    local module_path
    local start_time end_time duration
    
    # Validate input
    if [ -z "$module_name" ]; then
        echo "Error: load_lazy_module requires module_name" >&2
        return 1
    fi
    
    # Check if already loaded
    if is_module_loaded "$module_name"; then
        if [ -n "${DEBUG_SOURCING:-}" ]; then
            echo "Debug: Module '$module_name' already loaded" >&2
        fi
        return 0
    fi
    
    # Get module path from registry
    if [ -n "${DOTFILES_LAZY_MODULES+x}" ] 2>/dev/null; then
        module_path="${DOTFILES_LAZY_MODULES[$module_name]:-}"
    else
        # Fallback method
        module_path="$(echo "$DOTFILES_LAZY_MODULES" | grep "$module_name:" | cut -d: -f2-)"
    fi
    
    if [ -z "$module_path" ]; then
        echo "Error: Module '$module_name' not registered for lazy loading" >&2
        return 1
    fi
    
    # Validate module file
    if [ ! -r "$module_path" ]; then
        echo "Error: Cannot load lazy module '$module_name' - file not readable: $module_path" >&2
        return 1
    fi
    
    # Record start time for performance tracking
    if command -v date >/dev/null 2>&1; then
        start_time="$(date +%s%3N 2>/dev/null)" || start_time="$(date +%s)"
    fi
    
    # Load the module
    if . "$module_path"; then
        # Mark as loaded
        if [ -n "${DOTFILES_LOADED_MODULES+x}" ] 2>/dev/null; then
            DOTFILES_LOADED_MODULES["$module_name"]="$(date +%s 2>/dev/null || echo 'loaded')"
        else
            DOTFILES_LOADED_MODULES="$DOTFILES_LOADED_MODULES $module_name"
        fi
        
        # Record timing
        if [ -n "$start_time" ] && command -v date >/dev/null 2>&1; then
            end_time="$(date +%s%3N 2>/dev/null)" || end_time="$(date +%s)"
            duration=$((end_time - start_time))
            
            if [ -n "${DEBUG_SOURCING:-}" ]; then
                echo "Debug: Lazy loaded '$module_name' in ${duration}ms" >&2
            fi
        fi
        
        if [ -n "${DEBUG_SOURCING:-}" ]; then
            echo "Debug: Successfully lazy loaded module '$module_name'" >&2
        fi
        return 0
    else
        echo "Error: Failed to load lazy module '$module_name': $module_path" >&2
        return 1
    fi
}

# Preload essential modules (called during shell startup)
# Usage: preload_essential_modules
preload_essential_modules() {
    local essential_modules="${DOTFILES_ESSENTIAL_MODULES:-}"
    local module
    
    if [ -z "$essential_modules" ]; then
        # Default essential modules if not specified
        essential_modules="aliases env"
    fi
    
    # Load each essential module
    echo "$essential_modules" | tr ' ' '\n' | while IFS= read -r module; do
        module="$(echo "$module" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"  # trim whitespace
        if [ -n "$module" ]; then
            if ! is_module_loaded "$module"; then
                load_lazy_module "$module" 2>/dev/null || {
                    if [ -n "${DEBUG_SOURCING:-}" ]; then
                        echo "Debug: Could not preload essential module '$module'" >&2
                    fi
                }
            fi
        fi
    done
}

# Get lazy loading statistics
# Usage: get_lazy_stats
get_lazy_stats() {
    local registered_count=0
    local loaded_count=0
    
    echo "=== Dotfiles Lazy Loading Statistics ==="
    
    # Count registered modules
    if [ -n "${DOTFILES_LAZY_MODULES+x}" ] 2>/dev/null; then
        for module in "${!DOTFILES_LAZY_MODULES[@]}"; do
            registered_count=$((registered_count + 1))
            echo "  📦 $module -> ${DOTFILES_LAZY_MODULES[$module]}"
        done
    else
        registered_count=$(echo "$DOTFILES_LAZY_MODULES" | wc -w)
    fi
    
    echo "Registered modules: $registered_count"
    
    # Count loaded modules
    echo "=== Currently Loaded Modules ==="
    if [ -n "${DOTFILES_LOADED_MODULES+x}" ] 2>/dev/null; then
        for module in "${!DOTFILES_LOADED_MODULES[@]}"; do
            loaded_count=$((loaded_count + 1))
            echo "  ✓ $module (${DOTFILES_LOADED_MODULES[$module]})"
        done
    else
        loaded_count=$(echo "$DOTFILES_LOADED_MODULES" | wc -w)
        echo "  Loaded modules: $loaded_count"
    fi
    
    echo "Loaded modules: $loaded_count"
    echo "Lazy modules: $((registered_count - loaded_count))"
}

# Clear lazy loading registries (useful for testing)
# Usage: clear_lazy_registries
clear_lazy_registries() {
    if [ -n "${DOTFILES_LAZY_MODULES+x}" ] 2>/dev/null; then
        unset DOTFILES_LAZY_MODULES
        declare -A DOTFILES_LAZY_MODULES 2>/dev/null
    else
        DOTFILES_LAZY_MODULES=""
    fi
    
    if [ -n "${DOTFILES_LOADED_MODULES+x}" ] 2>/dev/null; then
        unset DOTFILES_LOADED_MODULES
        declare -A DOTFILES_LOADED_MODULES 2>/dev/null
    else
        DOTFILES_LOADED_MODULES=""
    fi
}

# Export functions for use in other scripts
if [ -n "${BASH_VERSION:-}" ]; then
    export -f register_lazy_module create_lazy_trigger is_module_loaded load_lazy_module preload_essential_modules get_lazy_stats clear_lazy_registries
fi
