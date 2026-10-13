#!/bin/bash
#
# save.sh - Save files/directories to /boot/firmware/config for persistence
#
# Usage:
#   save.sh <path>       Save a file or directory
#   save.sh --all        Save all files registered in files.json
#   save.sh              Show usage
#

set -e

CONFIG_DIR="/boot/firmware/config"
FILES_JSON="${CONFIG_DIR}/files.json"

usage() {
    echo "Usage:"
    echo "  $0 <path>       Save a file or directory to config"
    echo "  $0 --all        Save all registered files"
    echo ""
    echo "Examples:"
    echo "  $0 /home/pi/.config/rclone/rclone.conf"
    echo "  $0 ~/.netrc"
    echo "  $0 --all"
    exit 1
}

error() {
    echo "Error: $1" >&2
    exit 1
}

# Reject paths that must never be persisted. Registering "/" (or an empty/system
# path) would make load.sh chown/chmod the root directory at every boot.
is_unsafe_target() {
    local p="$1"
    if [[ -z "$p" || "$p" == "null" || "$p" != /* ]]; then
        return 0
    fi
    local norm="$p"
    while [[ "$norm" == */ ]]; do norm="${norm%/}"; done
    [[ -z "$norm" ]] && return 0
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
        error "jq is required but not installed. Run: sudo apt install jq"
    fi
}

# Initialize files.json if it doesn't exist
init_files_json() {
    if [[ ! -f "$FILES_JSON" ]]; then
        echo '{"files":[]}' > "$FILES_JSON"
    fi
}

# Get absolute path from relative or absolute path
get_absolute_path() {
    local path="$1"
    if [[ "$path" == /* ]]; then
        echo "$path"
    else
        echo "$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
    fi
}

# Generate unique name for config storage
generate_unique_name() {
    local base_name="$1"
    local name="$base_name"
    local counter=2

    while jq -e --arg name "$name" '.files[] | select(.name == $name)' "$FILES_JSON" > /dev/null 2>&1; do
        name="${base_name}.${counter}"
        ((counter++))
    done

    echo "$name"
}

# Check if all files in directory have same owner
check_directory_owner() {
    local dir="$1"
    local first_owner=""
    local first_group=""

    while IFS= read -r -d '' file; do
        local owner=$(stat -c '%U' "$file")
        local group=$(stat -c '%G' "$file")

        if [[ -z "$first_owner" ]]; then
            first_owner="$owner"
            first_group="$group"
        elif [[ "$owner" != "$first_owner" || "$group" != "$first_group" ]]; then
            error "Directory contains files with different owners: $first_owner:$first_group vs $owner:$group"
        fi
    done < <(find "$dir" -print0)

    echo "${first_owner}:${first_group}"
}

# Save a single file
save_file() {
    local src_path="$1"
    local abs_path=$(get_absolute_path "$src_path")

    if is_unsafe_target "$abs_path"; then
        error "Refusing to persist unsafe/system path: '$abs_path'"
    fi

    if [[ ! -e "$abs_path" ]]; then
        error "File or directory not found: $abs_path"
    fi

    local base_name=$(basename "$abs_path")
    local owner=$(stat -c '%U' "$abs_path")
    local group=$(stat -c '%G' "$abs_path")
    local mode=$(stat -c '%a' "$abs_path")

    if [[ -d "$abs_path" ]]; then
        # Directory: check owner consistency and create tar
        local owner_info=$(check_directory_owner "$abs_path")
        owner=$(echo "$owner_info" | cut -d: -f1)
        group=$(echo "$owner_info" | cut -d: -f2)

        # Check if already registered
        local existing=$(jq -r --arg path "$abs_path" '.files[] | select(.path == $path) | .name' "$FILES_JSON")

        if [[ -n "$existing" ]]; then
            # Update existing entry
            local tar_file="${CONFIG_DIR}/${existing}"
            tar -cf "$tar_file" -C "$(dirname "$abs_path")" "$(basename "$abs_path")"
            echo "Updated: $abs_path -> $tar_file"
        else
            # New entry
            local unique_name=$(generate_unique_name "${base_name}.tar")
            local tar_file="${CONFIG_DIR}/${unique_name}"

            tar -cf "$tar_file" -C "$(dirname "$abs_path")" "$(basename "$abs_path")"

            # Add to files.json
            local tmp_json=$(mktemp)
            jq --arg name "$unique_name" \
               --arg path "$abs_path" \
               --arg owner "$owner" \
               --arg group "$group" \
               '.files += [{"name": $name, "path": $path, "type": "directory", "owner": $owner, "group": $group}]' \
               "$FILES_JSON" > "$tmp_json"
            mv "$tmp_json" "$FILES_JSON"

            echo "Saved: $abs_path -> $tar_file"
        fi
    else
        # Regular file
        # Check if already registered
        local existing=$(jq -r --arg path "$abs_path" '.files[] | select(.path == $path) | .name' "$FILES_JSON")

        if [[ -n "$existing" ]]; then
            # Update existing entry
            cp "$abs_path" "${CONFIG_DIR}/${existing}"
            echo "Updated: $abs_path -> ${CONFIG_DIR}/${existing}"
        else
            # New entry
            local unique_name=$(generate_unique_name "$base_name")
            local dest_file="${CONFIG_DIR}/${unique_name}"

            cp "$abs_path" "$dest_file"

            # Add to files.json
            local tmp_json=$(mktemp)
            jq --arg name "$unique_name" \
               --arg path "$abs_path" \
               --arg owner "$owner" \
               --arg group "$group" \
               --arg mode "$mode" \
               '.files += [{"name": $name, "path": $path, "type": "file", "owner": $owner, "group": $group, "mode": $mode}]' \
               "$FILES_JSON" > "$tmp_json"
            mv "$tmp_json" "$FILES_JSON"

            echo "Saved: $abs_path -> $dest_file"
        fi
    fi
}

# Save all registered files
save_all() {
    if [[ ! -f "$FILES_JSON" ]]; then
        error "files.json not found: $FILES_JSON"
    fi

    local count=$(jq '.files | length' "$FILES_JSON")

    if [[ "$count" -eq 0 ]]; then
        echo "No files registered in files.json"
        exit 0
    fi

    local errors=0

    for i in $(seq 0 $((count - 1))); do
        local path=$(jq -r ".files[$i].path" "$FILES_JSON")
        local name=$(jq -r ".files[$i].name" "$FILES_JSON")
        local type=$(jq -r ".files[$i].type" "$FILES_JSON")

        if is_unsafe_target "$path"; then
            echo "Warning: refusing unsafe/system path, skipping: '$path'" >&2
            ((errors++))
            continue
        fi

        if [[ ! -e "$path" ]]; then
            echo "Warning: File not found, skipping: $path" >&2
            ((errors++))
            continue
        fi

        if [[ "$type" == "directory" ]]; then
            # Check owner consistency
            if ! check_directory_owner "$path" > /dev/null 2>&1; then
                echo "Warning: Directory has mixed owners, skipping: $path" >&2
                ((errors++))
                continue
            fi
            tar -cf "${CONFIG_DIR}/${name}" -C "$(dirname "$path")" "$(basename "$path")"
            echo "Saved: $path -> ${CONFIG_DIR}/${name}"
        else
            cp "$path" "${CONFIG_DIR}/${name}"
            echo "Saved: $path -> ${CONFIG_DIR}/${name}"
        fi
    done

    if [[ $errors -gt 0 ]]; then
        echo ""
        echo "Completed with $errors warning(s)"
    fi
}

# Main
check_dependencies

if [[ $# -eq 0 ]]; then
    usage
fi

# Ensure config directory exists
if [[ ! -d "$CONFIG_DIR" ]]; then
    error "Config directory not found: $CONFIG_DIR"
fi

init_files_json

case "$1" in
    --all)
        save_all
        ;;
    --help|-h)
        usage
        ;;
    *)
        save_file "$1"
        ;;
esac
