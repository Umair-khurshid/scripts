
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
    echo -e "${