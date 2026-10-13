#!/bin/bash
#
# load.sh - Load files/directories from /boot/firmware/config
#
# Usage:
#   load.sh --all        Load all files registered in files.json
#   load.sh              Show usage
#

CONFIG_DIR="/boot/firmware/config"
FILES_JSON="${CONFIG_DIR}/files.json"
LOG_FILE="/tmp/load.sh-log"

usage() {
    echo "Usage:"
    echo "  $0 --all        Load all registered files from config"
    echo ""
    echo "Log file: $LOG_FILE"
    exit 1
}

log() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$message" >> "$LOG_FILE"
    echo "$message"
}

log_error() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1"
    echo "$message" >> "$LOG_FILE"
    echo "$message" >&2
}

# Reject paths that must never be a restore target. A stray "/" or empty entry
# would otherwise make the chown/chmod/rm/cp below operate on the root directory
# (this once chmod'd / to 0700 and broke every non-root service at boot).
is_unsafe_target() {
    local p="$1"
    # empty, jq-null, or not an absolute path
    if [[ -z "$p" || "$p" == "null" || "$p" != /* ]]; then
        return 0
    fi
    # strip all trailing slashes; if nothing left it was "/" (or all slashes)
    local norm="$p"
    while [[ "$norm" == */ ]]; do norm="${norm%/}"; done
    [[ -z "$norm" ]] && return 0
    # never allow a top-level system directory as a target
    case "$norm" in
        /bin|/boot|/dev|/etc|/home|/lib|/lib32|/lib64|/libx32|/media|/mnt|/opt|/proc|/root|/run|/sbin|/srv|/sys|/tmp|/usr|/var)
            return 0
            ;;
    esac
    return 1
}

# Check if jq is available
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed"
        exit 1
    fi
}

# Check disk space (requires at least 10MB free)
check_disk_space() {
    local available=$(df / --output=avail -B1M | tail -1 | tr -d ' ')
    if [[ "$available" -lt 10 ]]; then
        log_error "Insufficient disk space: ${available}MB available, need at least 10MB"
        exit 1
    fi
}

# Load all registered files
load_all() {
    # Initialize log file
    echo "=== load.sh started at $(date) ===" > "$LOG_FILE"

    # Check if files.json exists
    if [[ ! -f "$FILES_JSON" ]]; then
        log_error "files.json not found: $FILES_JSON"
        log "Skipping all file loading"
        exit 0
    fi

    # Validate JSON
    if ! jq empty "$FILES_JSON" 2>/dev/null; then
        log_error "files.json is corrupted or invalid JSON"
        log "Skipping all file loading"
        exit 0
    fi

    # Check disk space
    check_disk_space

    local count=$(jq '.files | length' "$FILES_JSON")

    if [[ "$count" -eq 0 ]]; then
        log "No files registered in files.json"
        exit 0
    fi

    local success=0
    local errors=0

    for i in $(seq 0 $((count - 1))); do
        local name=$(jq -r ".files[$i].name" "$FILES_JSON")
        local path=$(jq -r ".files[$i].path" "$FILES_JSON")
        local type=$(jq -r ".files[$i].type" "$FILES_JSON")
        local owner=$(jq -r ".files[$i].owner" "$FILES_JSON")
        local group=$(jq -r ".files[$i].group" "$FILES_JSON")
        local mode=$(jq -r ".files[$i].mode" "$FILES_JSON")

        local src="${CONFIG_DIR}/${name}"

        # Guard: never restore onto the root dir or a system directory.
        if is_unsafe_target "$path"; then
            log_error "Refusing unsafe target path, skipping entry: '$path'"
            ((errors++))
            continue
        fi

        # Guard: owner/group must be valid (jq returns "null" for missing keys,
        # which would turn into chown "null:null").
        if [[ -z "$owner" || "$owner" == "null" || -z "$group" || "$group" == "null" ]]; then
            log_error "Invalid owner/group ('${owner}:${group}'), skipping: $path"
            ((errors++))
            continue
        fi

        # Check if source exists
        if [[ ! -e "$src" ]]; then
            log_error "Source not found, skipping: $src"
            ((errors++))
            continue
        fi

        # Create parent directory if needed
        local parent_dir=$(dirname "$path")
        if [[ ! -d "$parent_dir" ]]; then
            mkdir -p "$parent_dir"
            # Set parent directory owner to match the file owner
            chown "${owner}:${group}" "$parent_dir"
            log "Created directory: $parent_dir"
        fi

        if [[ "$type" == "directory" ]]; then
            # Extract tar archive
            # Remove existing directory if present
            if [[ -d "$path" ]]; then
                rm -rf "$path"
            fi

            if tar -xf "$src" -C "$parent_dir" 2>> "$LOG_FILE"; then
                # Set owner recursively (tar preserves mode)
                chown -R "${owner}:${group}" "$path"
                log "Loaded directory: $src -> $path"
                ((success++))
            else
                log_error "Failed to extract: $src -> $path"
                ((errors++))
            fi
        else
            # Copy regular file
            if cp "$src" "$path" 2>> "$LOG_FILE"; then
                chown "${owner}:${group}" "$path"
                chmod "$mode" "$path"
                log "Loaded file: $src -> $path (owner=${owner}:${group}, mode=$mode)"
                ((success++))
            else
                log_error "Failed to copy: $src -> $path"
                ((errors++))
            fi
        fi
    done

    log "=== Completed: $success succeeded, $errors failed ==="
}

# Main
check_dependencies

if [[ $# -eq 0 ]]; then
    usage
fi

case "$1" in
    --all)
        load_all
        ;;
    --help|-h)
        usage
        ;;
    *)
        usage
        ;;
esac
