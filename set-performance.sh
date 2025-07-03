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