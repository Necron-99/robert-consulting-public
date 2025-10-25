#!/bin/bash

# Secure Script Manager
# Prevents accidental commits of scripts with secrets

set -euo pipefail

# Configuration
SECURE_SCRIPTS_DIR="${HOME}/.secure-scripts"
GITIGNORE_FILE=".gitignore"
SECRET_PATTERNS=(
    "password"
    "secret"
    "key"
    "token"
    "credential"
    "auth"
    "api.*key"
    "private"
    "sensitive"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create secure scripts directory
create_secure_dir() {
    if [[ ! -d "$SECURE_SCRIPTS_DIR" ]]; then
        mkdir -p "$SECURE_SCRIPTS_DIR"
        chmod 700 "$SECURE_SCRIPTS_DIR"
        log_success "Created secure scripts directory: $SECURE_SCRIPTS_DIR"
    fi
}

# Check if script contains secrets
contains_secrets() {
    local script_file="$1"
    
    if [[ ! -f "$script_file" ]]; then
        return 1
    fi
    
    # Check for actual hardcoded secrets (exclude legitimate patterns)
    # Look for patterns that suggest actual hardcoded secrets, not defaults or examples
    if grep -qiE "password\s*=\s*['\"][^'\"]{8,}['\"]" "$script_file" && ! grep -qiE "(demo|test|example|default)" "$script_file"; then
        log_warning "Script contains potential hardcoded secret"
        return 0
    fi
    
    # Check for AWS access keys (AKIA pattern)
    if grep -qiE "AKIA[0-9A-Z]{16}" "$script_file"; then
        log_warning "Script contains potential AWS access key"
        return 0
    fi
    
    # Check for long base64-like strings (but exclude common patterns)
    if grep -qiE "[a-zA-Z0-9+/]{40,}" "$script_file" && ! grep -qiE "(demo|test|example|default|placeholder)" "$script_file"; then
        log_warning "Script contains potential long secret string"
        return 0
    fi
    
    return 1
}

# Move script to secure directory
move_to_secure() {
    local script_file="$1"
    local script_name=$(basename "$script_file")
    local secure_path="${SECURE_SCRIPTS_DIR}/${script_name}"
    
    # Copy to secure directory
    cp "$script_file" "$secure_path"
    chmod 600 "$secure_path"
    
    # Remove from git tracking if it exists
    if git ls-files --error-unmatch "$script_file" >/dev/null 2>&1; then
        git rm --cached "$script_file" 2>/dev/null || true
        log_info "Removed $script_file from git tracking"
    fi
    
    # Add to gitignore
    if [[ -f "$GITIGNORE_FILE" ]]; then
        if ! grep -q "^$script_file$" "$GITIGNORE_FILE"; then
            echo "$script_file" >> "$GITIGNORE_FILE"
            log_info "Added $script_file to .gitignore"
        fi
    else
        echo "$script_file" > "$GITIGNORE_FILE"
        log_info "Created .gitignore with $script_file"
    fi
    
    log_success "Script moved to secure location: $secure_path"
    echo "$secure_path"
}

# Create secure script template
create_secure_template() {
    local script_name="$1"
    local template_file="${SECURE_SCRIPTS_DIR}/${script_name}"
    
    cat > "$template_file" << 'EOF'
#!/bin/bash

# Secure Script Template
# This script is stored in ~/.secure-scripts/ to prevent accidental commits

set -euo pipefail

# Configuration - MODIFY THESE VALUES
# DO NOT COMMIT THESE VALUES TO GIT
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-}"
export AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN:-}"
export AWS_REGION="${AWS_REGION:-us-east-1}"

# Add your secret variables here
# export SECRET_VAR="${SECRET_VAR:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Your script logic here
main() {
    log_info "Starting secure script: $0"
    
    # Add your implementation here
    
    log_success "Script completed successfully"
}

# Run main function
main "$@"
EOF
    
    chmod +x "$template_file"
    chmod 600 "$template_file"
    
    log_success "Created secure script template: $template_file"
    echo "$template_file"
}

# Scan directory for scripts with secrets
scan_directory() {
    local scan_dir="${1:-.}"
    local found_secrets=false
    
    log_info "Scanning directory for scripts with potential secrets: $scan_dir"
    
    # Find all shell scripts (exclude workflow files and legitimate config files)
    while IFS= read -r -d '' script_file; do
        # Skip workflow files and legitimate config files that contain these patterns
        if [[ "$script_file" == *".github/workflows/"* ]] || \
           [[ "$script_file" == *"node_modules/"* ]] || \
           [[ "$script_file" == *"/.terraform/"* ]]; then
            continue
        fi
        
        if contains_secrets "$script_file"; then
            log_warning "Found script with potential secrets: $script_file"
            found_secrets=true
        fi
    done < <(find "$scan_dir" -name "*.sh" -type f -print0)
    
    if [[ "$found_secrets" == "true" ]]; then
        log_warning "Scripts with potential secrets found. Consider moving them to secure directory."
        return 1
    else
        log_success "No scripts with potential secrets found"
        return 0
    fi
}

# List secure scripts
list_secure_scripts() {
    log_info "Secure scripts in $SECURE_SCRIPTS_DIR:"
    
    if [[ -d "$SECURE_SCRIPTS_DIR" ]]; then
        ls -la "$SECURE_SCRIPTS_DIR" 2>/dev/null || log_info "No secure scripts found"
    else
        log_info "Secure scripts directory does not exist"
    fi
}

# Execute secure script
execute_secure_script() {
    local script_name="$1"
    local script_path="${SECURE_SCRIPTS_DIR}/${script_name}"
    
    if [[ ! -f "$script_path" ]]; then
        log_error "Secure script not found: $script_name"
        return 1
    fi
    
    log_info "Executing secure script: $script_path"
    bash "$script_path" "${@:2}"
}

# Setup git hooks for security
setup_git_hooks() {
    local hooks_dir=".git/hooks"
    
    if [[ ! -d "$hooks_dir" ]]; then
        log_error "Not in a git repository"
        return 1
    fi
    
    # Pre-commit hook
    cat > "${hooks_dir}/pre-commit" << 'EOF'
#!/bin/bash

# Pre-commit hook to prevent accidental secret commits

# Check for secret patterns in staged files
for file in $(git diff --cached --name-only); do
    if [[ -f "$file" ]]; then
        # Check for common secret patterns
        if grep -qiE "(password|secret|key|token|credential|auth|api.*key|private|sensitive)" "$file"; then
            echo "ERROR: Potential secrets detected in $file"
            echo "Please use the secure script manager to handle files with secrets"
            echo "Run: ./scripts/secure-script-manager.sh scan"
            exit 1
        fi
    fi
done
EOF
    
    chmod +x "${hooks_dir}/pre-commit"
    log_success "Git pre-commit hook installed"
}

# Main function
main() {
    local command="${1:-help}"
    shift || true
    
    create_secure_dir
    
    case "$command" in
        "scan")
            scan_directory "${1:-.}"
            ;;
        "move")
            if [[ $# -lt 1 ]]; then
                log_error "Usage: $0 move <script-file>"
                exit 1
            fi
            move_to_secure "$1"
            ;;
        "create")
            if [[ $# -lt 1 ]]; then
                log_error "Usage: $0 create <script-name>"
                exit 1
            fi
            create_secure_template "$1"
            ;;
        "list")
            list_secure_scripts
            ;;
        "exec")
            if [[ $# -lt 1 ]]; then
                log_error "Usage: $0 exec <script-name> [args...]"
                exit 1
            fi
            execute_secure_script "$@"
            ;;
        "setup-hooks")
            setup_git_hooks
            ;;
        "help"|*)
            echo "Usage: $0 <command> [args...]"
            echo ""
            echo "Commands:"
            echo "  scan <dir>        - Scan directory for scripts with secrets"
            echo "  move <script>     - Move script to secure directory"
            echo "  create <name>     - Create secure script template"
            echo "  list              - List secure scripts"
            echo "  exec <name> [args] - Execute secure script"
            echo "  setup-hooks       - Setup git hooks for security"
            echo "  help              - Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 scan ."
            echo "  $0 move deploy-with-secrets.sh"
            echo "  $0 create my-deploy-script"
            echo "  $0 exec my-deploy-script arg1 arg2"
            ;;
    esac
}

# Run main function with all arguments
main "$@"
