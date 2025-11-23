#!/usr/bin/env bash
#
# wtf.sh - Windows Thumbs.db Files cleaner
# Safely locate and remove Thumbs.db files from the system
#

set -euo pipefail  # Exit on error, undefined variables, pipe failures

readonly SCRIPT_NAME="$(basename "$0")"
readonly CACHE_DIR="${HOME}/.cache/thumbs_cleaner"
readonly CACHE_FILE="${CACHE_DIR}/thumbs_list"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $*"
}

show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Windows Thumbs.db Files Cleaner - Safely locate and remove Thumbs.db files

Options:
    -h, --help          Show this help message
    -d, --dry-run       Show what would be deleted without actually deleting
    -v, --verbose       Show detailed output
    -f, --force         Skip confirmation prompt
    -c, --cache         Use cached file list from previous run
    --cache-dir DIR     Use custom cache directory (default: $CACHE_DIR)
    --max-depth LEVEL   Limit search depth (default: unlimited)

Examples:
    $SCRIPT_NAME --dry-run    # Preview files that would be deleted
    $SCRIPT_NAME --force      # Delete without confirmation
    $SCRIPT_NAME -v --max-depth 3 # Verbose search, max 3 levels deep
EOF
}

find_thumbs_files() {
    local max_depth="${1:-}"
    local find_cmd=("find" "/" "-name" "Thumbs.db" "-type" "f")
    
    if [[ -n "$max_depth" ]]; then
        find_cmd+=("-maxdepth" "$max_depth")
    fi
    
    # Exclude common system directories to improve performance and safety
    find_cmd+=("!" "-path" "*/proc/*" "!" "-path" "*/sys/*" "!" "-path" "*/dev/*")
    
    log_info "Searching for Thumbs.db files..."
    "${find_cmd[@]}" 2>/dev/null || true
}

confirm_action() {
    local message="$1"
    local response
    
    read -r -p "$message (y/N): " response
    case "$response" in
        [yY]|[yY][eE][sS])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

main() {
    local dry_run=false
    local verbose=false
    local force=false
    local use_cache=false
    local max_depth=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -d|--dry-run)
                dry_run=true
                ;;
            -v|--verbose)
                verbose=true
                ;;
            -f|--force)
                force=true
                ;;
            -c|--cache)
                use_cache=true
                ;;
            --max-depth)
                max_depth="$2"
                shift
                ;;
            --cache-dir)
                CACHE_DIR="$2"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
        shift
    done
    
    # Create cache directory if it doesn't exist
    if [[ ! -d "$CACHE_DIR" ]]; then
        mkdir -p "$CACHE_DIR"
    fi
    
    # Find or load Thumbs.db files
    local files
    if [[ "$use_cache" == true && -f "$CACHE_FILE" ]]; then
        log_info "Using cached file list from: $CACHE_FILE"
        files=$(cat "$CACHE_FILE")
    else
        files=$(find_thumbs_files "$max_depth")
        echo "$files" > "$CACHE_FILE"
    fi
    
    # Count files
    local file_count
    file_count=$(echo "$files" | grep -c '^' || true)
    
    if [[ "$file_count" -eq 0 ]]; then
        log_info "No Thumbs.db files found."
        exit 0
    fi
    
    log_info "Found $file_count Thumbs.db files"
    
    # Show files in verbose mode
    if [[ "$verbose" == true ]]; then
        echo "$files"
        echo
    fi
    
    # Dry run mode
    if [[ "$dry_run" == true ]]; then
        log_info "Dry run completed. $file_count files would be deleted."
        exit 0
    fi
    
    # Confirm deletion unless forced
    if [[ "$force" != true ]]; then
        if ! confirm_action "Delete $file_count Thumbs.db files?"; then
            log_info "Operation cancelled."
            exit 0
        fi
    fi
    
    # Delete files
    local deleted_count=0
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        
        if rm -f "$file"; then
            ((deleted_count++))
            [[ "$verbose" == true ]] && log_info "Deleted: $file"
        else
            log_error "Failed to delete: $file"
        fi
    done <<< "$files"
    
    # Clean up cache file
    rm -f "$CACHE_FILE"
    
    log_info "Successfully deleted $deleted_count Thumbs.db files"
}

main "$@"
