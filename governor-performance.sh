#!/usr/bin/env bash
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │                     CPU Governor Performance Configurator                   │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# Script:      governor-performance.sh
# Description: Permanently configures CPU frequency scaling governor to 
#              'performance' mode using systemd service for persistence across reboots
# Version:     3.0.0
# Author:      Jeiel0rbit
# License:     MIT License
# Repository:  https://github.com/Jeiel0rbit/set-governor-performance
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │                                   USAGE                                     │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# Basic Usage:
#   ./governor-performance.sh                 # Install and configure
#   ./governor-performance.sh --status        # Show current status
#   ./governor-performance.sh --uninstall     # Remove configuration
#   ./governor-performance.sh --help          # Show help information

# To immediately return any error code
set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Constants
readonly SERVICE_NAME="set-performance.service"
readonly SCRIPT_PATH="/usr/local/bin/${SERVICE_NAME}"
readonly SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"

# Function to print colored messages
print_step() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "for security reasons this script should not be run as root."
        exit 1
    fi
}

# Function to check if sudo is available
check_sudo() {
    if ! command -v sudo &> /dev/null; then
        print_error "sudo is not installed. Please install sudo and try again."
        exit 1
    fi
    
    # Test sudo access
    if ! sudo -n true 2>/dev/null; then
        print_warning "Checking sudo permissions..."
        sudo -v || {
            print_error "use sudo to continue."
            exit 1
        }
    fi
}

# Function to check if cpufreq is available
check_cpufreq() {
    if [[ ! -d "/sys/devices/system/cpu/cpu0/cpufreq" ]]; then
        print_error "cpufreq is not available on this system."
        print_error "Verify that the appropriate driver is loaded (acpi-cpufreq, intel_pstate, etc.)"
        exit 1
    fi
}

# Function to check available governors
check_governors() {
    local available_governors
    available_governors=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "")
    
    if [[ -z "$available_governors" ]]; then
        print_error "Unable to determine available governors."
        exit 1
    fi
    
    if [[ ! "$available_governors" =~ "performance" ]]; then
        print_error "The 'performance' governor is not available on this system."
        print_error "Available Governors: $available_governors"
        exit 1
    fi
    
    print_step "Available Governors: $available_governors"
}

# Configure the script
configure_script() {
    print_step "[1/4] Setting up the script"

    sudo cp ./set-performance.service $SCRIPT_PATH
    
    sudo chmod +x "$SCRIPT_PATH"

    print_success "Script created in: $SCRIPT_PATH"
}

# Function to create systemd service
create_systemd_service() {
    print_step "[2/4] Creating systemd service for application at boot..."
    
    sudo cp ./governor-performance.service $SERVICE_PATH

    sudo chmod +x "$SERVICE_PATH"

    print_success "Systemd service created in $SERVICE_PATH"
}

# Function to enable and start the service
enable_service() {
    print_step "[3/4] Reloading systemd and enabling service..."
    
    # Reload systemd
    sudo systemctl daemon-reload
    
    # Enable the service
    if sudo systemctl enable "$SERVICE_NAME"; then
        print_success "Service $SERVICE_NAME enabled for autostart"
    else
        print_error "Failed to enable service"
        exit 1
    fi
}

# Function to start the service immediately
start_service() {
    print_step "[4/4] Trying to start service immediately..."
    
    if sudo systemctl start "$SERVICE_NAME"; then
        print_success "Service started successfully"
        
        # Wait a moment and check status
        sleep 2
        if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
            print_success "Service is up and running"
        else
            print_warning "Service may not be working properly"
            sudo systemctl status "$SERVICE_NAME" --no-pager -l
        fi
    else
        print_error "Failed to start service"
        sudo systemctl status "$SERVICE_NAME" --no-pager -l
        exit 1
    fi
}

# Function to show current status
show_status() {
    echo
    print_step "Current status of CPU governors:"
    
    local cpu_count=0
    for cpu_path in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor; do
        if [[ -f "$cpu_path" ]]; then
            cpu_name=$(basename "$(dirname "$(dirname "$cpu_path")")")
            governor=$(cat "$cpu_path" 2>/dev/null || echo "unknown")
            printf "  %-8s: %s\n" "$cpu_name" "$governor"
            cpu_count=$((cpu_count + 1))
        fi
    done
    
    echo
    print_step "Service Information:"
    sudo systemctl status "$SERVICE_NAME" --no-pager -l || true
}

# Function to show usage information
show_usage() {
    echo "Use: $0 [options]"
    echo "Options:"
    echo "  -h, --help      Show this help"
    echo "  -s, --status    Show only current status"
    echo "  -u, --uninstall Uninstall the service"
    echo
    echo "This script sets the CPU governor to 'performance' permanently."
}

# Function to uninstall the service
uninstall_service() {
    print_step "Uninstalling CPU governor service..."
    
    # Stop and disable service
    if sudo systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        sudo systemctl stop "$SERVICE_NAME" 2>/dev/null || true
        sudo systemctl disable "$SERVICE_NAME"
        print_success "Service disabled"
    fi
    
    # Remove files
    if [[ -f "$SERVICE_PATH" ]]; then
        sudo rm -f "$SERVICE_PATH"
        print_success "Service file removed"
    fi
    
    if [[ -f "$SCRIPT_PATH" ]]; then
        sudo rm -f "$SCRIPT_PATH"
        print_success "Script removed"
    fi
    
    # Reload systemd
    sudo systemctl daemon-reload
    print_success "Uninstallation complete"
}

# Main function
main() {
    echo "=== CPU Governor Configurator ==="
    echo
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -s|--status)
                check_cpufreq
                show_status
                exit 0
                ;;
            -u|--uninstall)
                check_root
                check_sudo
                uninstall_service
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Pre-flight checks
    check_root
    check_sudo
    check_cpufreq
    check_governors
    
    # Main installation process
    configure_script
    create_systemd_service
    enable_service
    start_service
    
    # Show final status
    show_status
    
    echo
    print_success "✅ The 'performance' governor has been configured and will be applied automatically at each boot."
    print_step "To check the status: sudo systemctl status $SERVICE_NAME"
    print_step "To uninstall: $0 --uninstall"
    sleep 5d
}

# Execute main function with all arguments
main "$@"
