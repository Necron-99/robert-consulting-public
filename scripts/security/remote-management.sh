#!/bin/bash

# Remote Management Script for Client Accounts
# This script allows easy access to client accounts for management tasks

set -e

# Ensure we're using bash for associative arrays
if [ -z "$BASH_VERSION" ]; then
    echo "This script requires bash. Please run with: bash $0"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Client account configurations (using functions for compatibility)
get_client_account() {
    case "$1" in
        "baileylessons")
            echo "${data.aws_caller_identity.current.account_id}"
            ;;
        # Add more clients here as they're created
        # "client2")
        #     echo "123456789012"
        #     ;;
        *)
            echo ""
            ;;
    esac
}

get_all_clients() {
    echo "baileylessons"
    # Add more clients here as they're created
    # echo "client2"
}

# Function to assume remote management role
assume_remote_role() {
    local client_name=$1
    local account_id=$2
    
    print_status "Assuming remote management role for $client_name (Account: $account_id)"
    
    # Assume the remote management role
    local credentials=$(aws sts assume-role \
        --role-arn "arn:aws:iam::${account_id}:role/RobertRemoteManagementRole" \
        --role-session-name "remote-management-${client_name}" \
        --external-id "robert-consulting-remote-management" \
        --query 'Credentials' --output json)
    
    if [ $? -eq 0 ]; then
        # Extract credentials
        local access_key=$(echo "$credentials" | jq -r '.AccessKeyId')
        local secret_key=$(echo "$credentials" | jq -r '.SecretAccessKey')
        local session_token=$(echo "$credentials" | jq -r '.SessionToken')
        
        # Set environment variables
        export AWS_ACCESS_KEY_ID="$access_key"
        export AWS_SECRET_ACCESS_KEY="$secret_key"
        export AWS_SESSION_TOKEN="$session_token"
        
        print_success "Successfully assumed role for $client_name"
        
        # Verify access
        local caller_identity=$(aws sts get-caller-identity --query 'Account' --output text)
        if [ "$caller_identity" = "$account_id" ]; then
            print_success "Verified access to account $account_id"
            return 0
        else
            print_error "Failed to verify access to account $account_id"
            return 1
        fi
    else
        print_error "Failed to assume role for $client_name"
        return 1
    fi
}

# Function to list available clients
list_clients() {
    print_status "Available clients:"
    for client in $(get_all_clients); do
        local account_id=$(get_client_account "$client")
        echo "  - $client (Account: $account_id)"
    done
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND] [CLIENT]"
    echo ""
    echo "Commands:"
    echo "  list                    - List available clients"
    echo "  assume <client>         - Assume remote management role for client"
    echo "  shell <client>          - Start shell with client credentials"
    echo "  exec <client> <command> - Execute command in client context"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 assume baileylessons"
    echo "  $0 shell baileylessons"
    echo "  $0 exec baileylessons 'aws s3 ls'"
}

# Main script logic
case "$1" in
    "list")
        list_clients
        ;;
    "assume")
        if [ -z "$2" ]; then
            print_error "Please specify a client name"
            show_usage
            exit 1
        fi
        
        account_id=$(get_client_account "$2")
        if [ -z "$account_id" ]; then
            print_error "Unknown client: $2"
            list_clients
            exit 1
        fi
        
        assume_remote_role "$2" "$account_id"
        ;;
    "shell")
        if [ -z "$2" ]; then
            print_error "Please specify a client name"
            show_usage
            exit 1
        fi
        
        account_id=$(get_client_account "$2")
        if [ -z "$account_id" ]; then
            print_error "Unknown client: $2"
            list_clients
            exit 1
        fi
        
        assume_remote_role "$2" "$account_id"
        if [ $? -eq 0 ]; then
            print_success "Starting shell with $2 credentials..."
            print_warning "Type 'exit' to return to management account"
            exec bash
        fi
        ;;
    "exec")
        if [ -z "$2" ] || [ -z "$3" ]; then
            print_error "Please specify client and command"
            show_usage
            exit 1
        fi
        
        account_id=$(get_client_account "$2")
        if [ -z "$account_id" ]; then
            print_error "Unknown client: $2"
            list_clients
            exit 1
        fi
        
        assume_remote_role "$2" "$account_id"
        if [ $? -eq 0 ]; then
            print_success "Executing command in $2 context..."
            eval "$3"
        fi
        ;;
    *)
        show_usage
        ;;
esac
