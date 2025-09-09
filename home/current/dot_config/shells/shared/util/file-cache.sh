#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

#!/usr/bin/env bash
# File Caching Utility for Dotfiles
# Purpose: Cache frequently sourced files to improve shell startup performance
# Shell Support: bash, zsh (POSIX-compliant where possible)
# Chezmoi: Managed by chezmoi, safe to source multiple times
# Security: No external calls, safe for all environments
# Extensibility: Can be extended with TTL and size limits

# Cache directory - use XDG_CACHE_HOME if available
DOTFILES_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
DOTFILES_CACHE_ENABLED="${DOTFILES_CACHE_ENABLED:-1}"
DOTFILES_CACHE_TTL="${DOTFILES_CACHE_TTL:-3600}"  # 1 hour default TTL

# Ensure cache directory exists
init_cache_dir() {
    if [ "$DOTFILES_CACHE_ENABLED" = "1" ] && [ ! -d "$DOTFILES_CACHE_DIR" ]; then
        mkdir -p "$DOTFILES_CACHE_DIR" 2>/dev/null || {
            echo "Warning: Could not create cache directory: $DOTFILES_CACHE_DIR" >&2
            DOTFILES_CACHE_ENABLED=0
            return 1
        }
    fi
}

# Get cache file path for a source file
# Usage: get_cache_path "/path/to/source.sh"
get_cache_path() {
    local source_file="$1"
    local cache_name

    if [ -z "$source_file" ]; then
        return 1
    fi

    # Create a safe cache filename from the source path
    cache_name="$(echo "$source_file" | sed 's|/|_|g' | sed 's|^_||')"
    echo "$DOTFILES_CACHE_DIR/${cache_name}.cache"
}

# Check if cached version is valid
# Usage: is_cache_valid "/path/to/source.sh" "/path/to/cache.cache"
is_cache_valid() {
    local source_file="$1"
    local cache_file="$2"
    local source_mtime cache_mtime cache_age current_time

    # Cache disabled or files don't exist
    if [ "$DOTFILES_CACHE_ENABLED" != "1" ] || [ ! -f "$cache_file" ] || [ ! -f "$source_file" ]; then
        return 1
    fi

    # Get modification times (platform-independent)
    if command -v stat >/dev/null 2>&1; then
        # Try GNU stat first, then BSD stat
        source_mtime="$(stat -c %Y "$source_file" 2>/dev/null || stat -f %m "$source_file" 2>/dev/null)" || return 1
        cache_mtime="$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null)" || return 1
    else
        # Fallback: assume cache is invalid if we can't check
        return 1
    fi

    # Source file is newer than cache
    if [ "$source_mtime" -gt "$cache_mtime" ]; then
        return 1
    fi

    # Check TTL if we can get current time
    if command -v date >/dev/null 2>&1; then
        current_time="$(date +%s 2>/dev/null)" || current_time="$cache_mtime"
        cache_age=$((current_time - cache_mtime))

        if [ "$cache_age" -gt "$DOTFILES_CACHE_TTL" ]; then
            return 1  # Cache expired
        fi
    fi

    return 0  # Cache is valid
}

# Create cache from source file
# Usage: create_cache "/path/to/source.sh" "/path/to/cache.cache"
create_cache() {
    local source_file="$1"
    local cache_file="$2"
    local temp_cache

    if [ "$DOTFILES_CACHE_ENABLED" != "1" ] || [ ! -r "$source_file" ]; then
        return 1
    fi

    # Create temporary cache file
    temp_cache="${cache_file}.tmp.$$"

    # Copy source to cache with some metadata
    {
        echo "# Cached from: $source_file"
        echo "# Cache created: $(date 2>/dev/null || echo 'unknown')"
        echo "# Original size: $(wc -c < "$source_file" 2>/dev/null || echo 'unknown') bytes"
        echo ""
        cat "$source_file"
    } > "$temp_cache" 2>/dev/null || {
        rm -f "$temp_cache" 2>/dev/null
        return 1
    }

    # Atomically move to final cache location
    if mv "$temp_cache" "$cache_file" 2>/dev/null; then
        return 0
    else
        rm -f "$temp_cache" 2>/dev/null
        return 1
    fi
}

# Source file with caching
# Usage: cached_source "/path/to/source.sh" ["description"]
cached_source() {
    local source_file="$1"
    local description="${2:-$(basename "$source_file" 2>/dev/null || echo "$source_file")}"
    local cache_file
    local use_cache=0

    # Validate input
    if [ -z "$source_file" ] || [ ! -r "$source_file" ]; then
        echo "Warning: Cannot source $description - file not readable: $source_file" >&2
        return 1
    fi

    # Initialize cache directory
    init_cache_dir

    # Get cache path and check if caching is beneficial
    if [ "$DOTFILES_CACHE_ENABLED" = "1" ]; then
        cache_file="$(get_cache_path "$source_file")"

        if [ -n "$cache_file" ]; then
            if is_cache_valid "$source_file" "$cache_file"; then
                use_cache=1
            else
                # Try to create new cache
                if create_cache "$source_file" "$cache_file"; then
                    use_cache=1
                fi
            fi
        fi
    fi

    # Source from cache or original file
    if [ "$use_cache" = "1" ] && [ -r "$cache_file" ]; then
        if [ -n "${DEBUG_SOURCING:-}" ]; then
            echo "Debug: Using cached version of $description" >&2
        fi
        . "$cache_file"
    else
        if [ -n "${DEBUG_SOURCING:-}" ]; then
            echo "Debug: Using original file for $description" >&2
        fi
        . "$source_file"
    fi
}

# Clean old cache files
# Usage: clean_cache [max_age_seconds]
clean_cache() {
    local max_age="${1:-$((DOTFILES_CACHE_TTL * 2))}"  # Default: 2x TTL
    local current_time cache_age

    if [ "$DOTFILES_CACHE_ENABLED" != "1" ] || [ ! -d "$DOTFILES_CACHE_DIR" ]; then
        return 0
    fi

    if ! command -v date >/dev/null 2>&1; then
        echo "Warning: Cannot clean cache - date command not available" >&2
        return 1
    fi

    current_time="$(date +%s 2>/dev/null)" || return 1

    # Find and remove old cache files
    find "$DOTFILES_CACHE_DIR" -name "*.cache" -type f 2>/dev/null | while IFS= read -r cache_file; do
        if [ -f "$cache_file" ]; then
            local file_mtime
            file_mtime="$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null)" || continue
            cache_age=$((current_time - file_mtime))

            if [ "$cache_age" -gt "$max_age" ]; then
                rm -f "$cache_file" 2>/dev/null
                if [ -n "${DEBUG_SOURCING:-}" ]; then
                    echo "Debug: Removed old cache file: $cache_file" >&2
                fi
            fi
        fi
    done
}

# Get cache statistics
# Usage: get_cache_stats
get_cache_stats() {
    local cache_count=0
    local total_size=0

    echo "=== Dotfiles Cache Statistics ==="
    echo "Cache directory: $DOTFILES_CACHE_DIR"
    echo "Cache enabled: $DOTFILES_CACHE_ENABLED"
    echo "Cache TTL: ${DOTFILES_CACHE_TTL}s"

    if [ "$DOTFILES_CACHE_ENABLED" = "1" ] && [ -d "$DOTFILES_CACHE_DIR" ]; then
        # Count cache files and calculate total size
        find "$DOTFILES_CACHE_DIR" -name "*.cache" -type f 2>/dev/null | while IFS= read -r cache_file; do
            if [ -f "$cache_file" ]; then
                cache_count=$((cache_count + 1))
                if command -v stat >/dev/null 2>&1; then
                    local file_size
                    file_size="$(stat -c %s "$cache_file" 2>/dev/null || stat -f %z "$cache_file" 2>/dev/null)" || file_size=0
                    total_size=$((total_size + file_size))
                fi
                echo "  ✓ $(basename "$cache_file")"
            fi
        done

        echo "Total cache files: $cache_count"
        if [ "$total_size" -gt 0 ]; then
            echo "Total cache size: $total_size bytes"
        fi
    else
        echo "Cache is disabled or directory does not exist"
    fi
}

# Clear all cache files
# Usage: clear_cache
clear_cache() {
    if [ "$DOTFILES_CACHE_ENABLED" = "1" ] && [ -d "$DOTFILES_CACHE_DIR" ]; then
        rm -f "$DOTFILES_CACHE_DIR"/*.cache 2>/dev/null
        echo "Cache cleared"
    else
        echo "Cache is disabled or directory does not exist"
    fi
}

# Export functions for use in other scripts
if [ -n "${BASH_VERSION:-}" ]; then
    export -f init_cache_dir get_cache_path is_cache_valid create_cache cached_source clean_cache get_cache_stats clear_cache
fi
