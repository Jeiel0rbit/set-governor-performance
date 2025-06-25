#!/usr/bin/env bash

# Name: revert-governor-to-balanced.sh
# Description: Disables the service that forces the 'performance' governor
# and restores a balanced state ('schedutil').
# Requires sudo to run.

echo "This script will revert the changes made by 'set-governor-performance.sh'."
echo "It will stop and disable the service, remove the created files, and set the CPU governor to 'schedutil'."
echo "---"

# Check if the service exists before trying to stop it
if systemctl list-units --full --all | grep -Fq 'set-cpu-governor.service'; then
    echo "[1/4] Stopping and disabling the 'set-cpu-governor.service'..."
    sudo systemctl stop set-cpu-governor.service
    sudo systemctl disable set-cpu-governor.service
    echo "Service stopped and disabled."
else
    echo "[1/4] Service 'set-cpu-governor.service' not found. Skipping."
fi

# Check if the service file exists before trying to remove it
SERVICE_FILE="/etc/systemd/system/set-cpu-governor.service"
if [ -f "$SERVICE_FILE" ]; then
    echo "[2/4] Removing the systemd service file..."
    sudo rm "$SERVICE_FILE"
    echo "File $SERVICE_FILE removed."
else
    echo "[2/4] Service file $SERVICE_FILE not found. Skipping."
fi

# Check if the script file exists before trying to remove it
SCRIPT_FILE="/usr/local/bin/set-cpu-performance.sh"
if [ -f "$SCRIPT_FILE" ]; then
    echo "[3/4] Removing the governor adjustment script..."
    sudo rm "$SCRIPT_FILE"
    echo "File $SCRIPT_FILE removed."
else
    echo "[3/4] Script file $SCRIPT_FILE not found. Skipping."
fi

echo "[4/4] Reloading systemd daemon and setting governor to 'schedutil'..."
sudo systemctl daemon-reload
sudo systemctl reset-failed

# Set a more balanced governor for all CPU cores
for CPU in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor; do
    if [ -f "$CPU" ]; then
        echo schedutil | sudo tee "$CPU" > /dev/null
    fi
done

echo -e "\n✅ Reversion process completed."
echo "The CPU governor has been set to 'schedutil', and the boot automation has been removed."
echo "To check the current status, use the command:"
echo "cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
