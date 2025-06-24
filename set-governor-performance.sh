#!/usr/bin/env bash

# Name: set-governor-performance.sh
# Description: Make the CPU governor ‘performance’ permanent via systemd
# Compatible with systems using acpi-cpufreq (e.g., AMD A6-7480)
# Requires sudo

echo "[1/4] Creating governor-adjustment script..."
sudo tee /usr/local/bin/set-cpu-performance.sh > /dev/null << 'EOF'
#!/bin/bash
# Loop over each CPU’s scaling_governor file and set it to "performance"
for CPU in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor; do
    echo performance | sudo tee "$CPU" > /dev/null
done
EOF

sudo chmod +x /usr/local/bin/set-cpu-performance.sh

echo "[2/4] Creating systemd service for boot-time application..."
sudo tee /etc/systemd/system/set-cpu-governor.service > /dev/null << 'EOF'
[Unit]
Description=Set CPU governor to performance at boot
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/set-cpu-performance.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

echo "[3/4] Reloading systemd and enabling service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable set-cpu-governor.service

echo "[4/4] Starting service immediately..."
sudo systemctl start set-cpu-governor.service

echo -e "\n✅ The 'performance' governor is now applied and will be set automatically on every boot."
