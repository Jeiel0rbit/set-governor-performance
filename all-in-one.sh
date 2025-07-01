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
readonly SERVICE_NAME="set-performance.sh"
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

    sudo tee "$SCRIPT_PATH" > /dev/null << 'EOF'
#!/bin/bash
# Make the CPU governor 'performance' permanent

# To immediately return any error code
set -euo pipefail

# Logger function
log_message() {
    logger -t "cpu-governor" "$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to set governor for all CPUs
set_performance_governor() {
    local cpu_count=0
    local success_count=0
    
    # Check if cpufreq directory exists
    if [[ ! -d "/sys/devices/system/cpu" ]]; then
        log_message "ERROR: CPU frequency scaling not available"
        exit 1
    fi
    
    # Loop over each CPU's scaling_governor file
    for cpu_path in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor; do
        if [[ -f "$cpu_path" ]]; then
            cpu_count=$((cpu_count + 1))
            cpu_name=$(basename "$(dirname "$(dirname "$cpu_path")")")
            
            # Check current governor
            current_governor=$(cat "$cpu_path" 2>/dev/null || echo "unknown")
            
            if [[ "$current_governor" == "performance" ]]; then
                log_message "INFO: $cpu_name already set to performance"
                success_count=$((success_count + 1))
            else
                # Set to performance
                if echo "performance" > "$cpu_path" 2>/dev/null; then
                    log_message "SUCCESS: $cpu_name governor set to performance (was: $current_governor)"
                    success_count=$((success_count + 1))
                else
                    log_message "ERROR: Failed to set $cpu_name governor to performance"
                fi
            fi
        fi
    done
    
    if [[ $cpu_count -eq 0 ]]; then
        log_message "ERROR: No CPU frequency scaling governors found"
        exit 1
    fi
    
    log_message "INFO: Processed $success_count/$cpu_count CPUs successfully"
    
    if [[ $success_count -ne $cpu_count ]]; then
        exit 1
    fi
}

# Main execution
main() {
    log_message "INFO: Starting CPU governor configuration"
    set_performance_governor
    log_message "INFO: CPU governor configuration completed"
}

# Execute main function
main "$@"
EOF
    
    sudo chmod +x "$SCRIPT_PATH"

    print_success "Script created in: $SCRIPT_PATH"
}

# Function to create systemd service
create_systemd_service() {
    print_step "[2/4] Creating systemd service for application at boot..."

    sudo tee "$SERVICE_PATH" > /dev/null << 'EOF'
[Unit]
Description=Set CPU governor to performance at boot
Documentation=man:cpufreq-set(1)
After=multi-user.target
Wants=multi-user.target
ConditionPathExists=/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

[Service]
Type=oneshot
ExecStart=/usr/local/bin/set-performance.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal
TimeoutStartSec=30

# Security hardening
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
PrivateDevices=no
ProtectKernelTunables=no
ProtectKernelModules=yes
ProtectControlGroups=yes
RestrictRealtime=yes
MemoryDenyWriteExecute=yes
ReadWritePaths=/sys/devices/system/cpu

[Install]
WantedBy=multi-user.target
EOF

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
    echo "This script sets the CPU governor to 'performance'."
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
    print_success "Uninstallation complete. The CPU governor will revert to its default setting on the next reboot."
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
}

# Execute main function with all arguments
main "$@"
