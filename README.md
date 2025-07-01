# CPU Governor Performance Configurator

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Linux](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.kernel.org/)
[![systemd](https://img.shields.io/badge/Init-systemd-red.svg)](https://systemd.io/)

![GitHub stars](https://img.shields.io/github/stars/Jeiel0rbit/set-governor-performance)
![GitHub forks](https://img.shields.io/github/forks/Jeiel0rbit/set-governor-performance)
![GitHub issues](https://img.shields.io/github/issues/Jeiel0rbit/set-governor-performance)
![GitHub last commit](https://img.shields.io/github/last-commit/Jeiel0rbit/set-governor-performance)

> **Set Linux CPU frequency scaling governor to 'performance' mode with automatic persistence across reboots using systemd.**

## 🚀 Overview

This script provides a robust, safe, and easy-to-use way to set your Linux system's CPU frequency governor to "performance" mode permanently. Since some distros may not recognize performance mode, this script sets it up. Unlike temporary workarounds that disappear after a reboot, this tool creates a systemd service that ensures that CPU governor settings are maintained across reboots, suspend/resume cycles, and system updates.

### Why Use This Tool?

- **🔒 Secure**: Follows security best practices with least privilege principle
- **🔄 Persistent**: Automatic configuration on every boot via systemd
- **🖥️ Multi-CPU**: Supports systems with multiple CPUs and cores
- **📊 Comprehensive**: Detailed logging, status reporting, and error handling
- **🎯 Professional**: Production-ready with proper error handling and rollback
- **🔧 Flexible**: Easy installation, status checking, and uninstallation

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [Features](#-features)
- [Installation](#-installation)
- [Usage](#-usage)
- [What It Does](#-what-it-does)
- [Security](#-security)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## ⚡ Quick Start

```bash
curl -s https://raw.githubusercontent.com/Jeiel0rbit/set-governor-performance/refs/heads/main/all-in-one.sh | bash
```

That's it! Your CPU controller is now set to performance mode.

## ✨ Features

### Core Functionality

- ✅ **Permanent Configuration**: Uses systemd for persistence across reboots
- ✅ **Multi-CPU Support**: Handles systems with multiple CPUs and cores
- ✅ **Automatic Application**: Applies settings on boot and resume from suspend
- ✅ **Comprehensive Logging**: Detailed logs with timestamps and system integration

### Security & Reliability

- 🔒 **Security Hardened**: Follows principle of least privilege
- 🔒 **Input Validation**: Comprehensive system and parameter validation
- 🔒 **Error Handling**: Robust error handling with automatic rollback
- 🔒 **systemd Hardening**: Service runs with security restrictions

### User Experience

- 🎨 **Colored Output**: Clear, colored terminal output with progress indicators
- 🎨 **Multiple Options**: Install, status check, uninstall, and help commands
- 🎨 **Detailed Feedback**: Real-time status updates and comprehensive reporting
- 🎨 **Easy Management**: Simple commands for all operations

### Tested Distributions

| Distribution | Version                         | Status                             |
| ------------ | ------------------------------- | ---------------------------------- |
| Ubuntu       | 20.04 LTS, 22.04 LTS, 24.04 LTS | :white_check_mark: Fully Supported |
| Debian       | 11 (Bullseye), 12 (Bookworm)    | :warning: Not Tested               |
| CentOS/RHEL  | 8, 9                            | :warning: Not Tested               |
| Rocky Linux  | 8, 9                            | :warning: Not Tested               |
| Fedora       | 35+                             | :warning: Not Tested               |
| openSUSE     | Leap 15.4+                      | :warning: Not Tested               |
| Arch Linux   | Rolling                         | :warning: Not Tested               |
| Manjaro      | Current                         | :warning: Not Tested               |

### Hardware Compatibility

| CPU Type | Driver       | Status                             |
| -------- | ------------ | ---------------------------------- |
| Intel    | intel_pstate | :white_check_mark: Fully Supported |
| AMD      | acpi-cpufreq | :white_check_mark: Fully Supported |
| ARM64    | cpufreq-dt   | :warning: Not Tested               |

## 📦 Installation

### Method 1: Direct Download (All-In-One)

```bash
# Download the latest version
curl -O https://raw.githubusercontent.com/Jeiel0rbit/set-governor-performance/main/all-in-one.sh

# Make executable
chmod +x all-in-one.sh

# Run installation
./all-in-one.sh
```

### Method 2: Git Clone

```bash
# Clone the repository
git clone https://github.com/Jeiel0rbit/set-governor-performance.git

# Navigate to directory
cd set-governor-performance

# Run the script
./governor-performance.sh
```

## 📖 Usage

### Basic Commands

```bash
# Install and configure CPU governor
./governor-performance.sh

# Check current status
./governor-performance.sh --status

# Show help information
./governor-performance.sh --help

# Uninstall completely
./governor-performance.sh --uninstall
```

### Example Output

```bash
$ ./governor-performance.sh
=== CPU Governor Configurator ===

[WARNING] Checking sudo permissions...
[sudo] password for harukadev:
[INFO] Available Governors: conservative ondemand userspace powersave performance schedutil
[INFO] [1/4] Setting up the script
[SUCCESS] Script created in: /usr/local/bin/set-performance.service
[INFO] [2/4] Creating systemd service for application at boot...
[SUCCESS] Systemd service created in /etc/systemd/system/set-performance.service
[INFO] [3/4] Reloading systemd and enabling service...
[SUCCESS] Service set-performance.service enabled for autostart
[INFO] [4/4] Trying to start service immediately...
[SUCCESS] Service started successfully
[SUCCESS] Service is up and running

[INFO] Current status of CPU governors:
  cpu0    : schedutil
  cpu10   : schedutil
  cpu11   : schedutil
  cpu12   : schedutil
  cpu13   : schedutil
  cpu14   : schedutil
  cpu15   : schedutil
  cpu16   : schedutil
  cpu17   : schedutil
  cpu18   : schedutil
  cpu19   : schedutil
  cpu1    : schedutil
  cpu20   : schedutil
  cpu21   : schedutil
  cpu22   : schedutil
  cpu23   : schedutil
  cpu24   : schedutil
  cpu25   : schedutil
  cpu26   : schedutil
  cpu27   : schedutil
  cpu2    : schedutil
  cpu3    : schedutil
  cpu4    : schedutil
  cpu5    : schedutil
  cpu6    : schedutil
  cpu7    : schedutil
  cpu8    : schedutil
  cpu9    : schedutil

[INFO] Service Information:
● set-performance.service - Set CPU governor to performance at boot
     Loaded: loaded (/etc/systemd/system/set-performance.service; enabled; vendor preset: enabled)
     Active: active (exited) since Tue 2025-07-01 04:05:57 -03; 4h 32min ago
       Docs: man:cpufreq-set(1)
   Main PID: 1886 (code=exited, status=0/SUCCESS)
        CPU: 262ms

jul 01 04:05:57 mydream set-performance.service[1886]: 2025-07-01 04:05:57 - SUCCESS: cpu7 governor set to performance (was: schedutil)
jul 01 04:05:57 mydream cpu-governor[2078]: SUCCESS: cpu8 governor set to performance (was: schedutil)
jul 01 04:05:57 mydream set-performance.service[1886]: 2025-07-01 04:05:57 - SUCCESS: cpu8 governor set to performance (was: schedutil)
jul 01 04:05:57 mydream cpu-governor[2085]: SUCCESS: cpu9 governor set to performance (was: schedutil)
jul 01 04:05:57 mydream set-performance.service[1886]: 2025-07-01 04:05:57 - SUCCESS: cpu9 governor set to performance (was: schedutil)
jul 01 04:05:57 mydream cpu-governor[2087]: INFO: Processed 28/28 CPUs successfully
jul 01 04:05:57 mydream set-performance.service[1886]: 2025-07-01 04:05:57 - INFO: Processed 28/28 CPUs successfully
jul 01 04:05:57 mydream cpu-governor[2089]: INFO: CPU governor configuration completed
jul 01 04:05:57 mydream set-performance.service[1886]: 2025-07-01 04:05:57 - INFO: CPU governor configuration completed
jul 01 04:05:57 mydream systemd[1]: Finished Set CPU governor to performance at boot.

[SUCCESS] ✅ The 'performance' governor has been configured and will be applied automatically at each boot.
[INFO] To check the status: sudo systemctl status set-performance.service
[INFO] To uninstall: ./governor-performance.sh --uninstall

```

## ⚙️ What It Does

### Installation Process

1. **System Validation**

   - Checks for required dependencies
   - Validates CPUfreq subsystem availability
   - Confirms 'performance' governor support
   - Verifies sudo permissions

2. **Script Creation**

   - Creates optimized CPU governor management script
   - Implements comprehensive error handling
   - Adds detailed logging with timestamps
   - Applies security best practices

3. **systemd Integration**

   - Creates hardened systemd service unit
   - Configures proper dependencies and ordering
   - Enables automatic startup on boot
   - Integrates with system logging

4. **Immediate Application**
   - Applies configuration to all CPUs immediately
   - Verifies successful application
   - Provides detailed status reporting

### Files Created

| File                                               | Purpose                        | Permissions     |
| -------------------------------------------------- | ------------------------------ | --------------- |
| `/usr/local/bin/set-performance.service`           | CPU governor management script | 755 (rwxr-xr-x) |
| `/etc/systemd/system/governor-performance.service` | systemd service unit           | 644 (rw-r--r--) |

## 🔐 Security

This project prioritizes security and follows industry best practices:

### Script Security

- **Principle of Least Privilege**: Runs as regular user, elevates only when necessary
- **Input Validation**: All parameters and system state validated before execution
- **Path Security**: Uses absolute paths to prevent PATH injection attacks
- **Error Handling**: Comprehensive error handling with secure cleanup
- **Secure Permissions**: Files created with appropriate permissions (644/755)

### systemd Service Security

The created systemd service includes multiple security hardening measures:

```ini
NoNewPrivileges=yes          # Prevents privilege escalation
ProtectSystem=strict         # Read-only filesystem protection
ProtectHome=yes             # Prevents access to user directories
PrivateTmp=yes              # Isolated temporary directory
ProtectKernelModules=yes    # Prevents kernel module loading
RestrictRealtime=yes        # Prevents realtime scheduling
MemoryDenyWriteExecute=yes  # Prevents code injection
```

### Security Audit

Regular security audits ensure the script maintains high security standards:

- Static analysis with ShellCheck
- Permission validation
- Input sanitization testing
- Privilege escalation prevention

## 🐛 Troubleshooting

### Common Issues

#### Issue: "cpufreq not available"

```bash
[ERROR] cpufreq is not available on this system.
```

**Solution**: Your kernel may not have CPUfreq support enabled, or the appropriate driver isn't loaded.

```bash
# Check if CPUfreq is available
ls /sys/devices/system/cpu/cpu0/cpufreq/

# Load appropriate driver (AMD)
sudo modprobe acpi-cpufreq

# Load appropriate driver (Intel)
sudo modprobe intel_pstate
```

#### Issue: "Performance governor not available"

```bash
[ERROR] The 'performance' governor is not available on this system.
```

**Solution**: Check available governors and verify system support:

```bash
# Check available governors
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors

# If performance is missing, you may need to enable it in kernel config
```

#### Issue: "sudo permissions required"

```bash
[ERROR] Sudo permissions required to continue.
```

**Solution**: Ensure your user has sudo privileges:

```bash
# Add user to sudo group (Ubuntu/Debian)
sudo usermod -aG sudo $USER

# Add user to wheel group (CentOS/RHEL/Fedora)
sudo usermod -aG wheel $USER

# Then logout and login again
```

### Getting Help

If you're still experiencing issues:

1. **Check Compatibility**: Verify your system meets the requirements above
2. **Run Verbose Mode**: Use `--verbose` flag for detailed output
3. **Check Logs**: Review systemd logs with `journalctl`
4. **Report Issues**: Create an issue on GitHub with system information

## 🤝 Contributing

We welcome contributions! Please see our contributing guidelines:

### Development Setup

```bash
# Fork the repository
git clone https://github.com/Jeiel0rbit/set-governor-performance.git
cd set-governor-performance

# Create a feature branch
git checkout -b feature/your-feature-name

# Commit your changes
git commit -m "Add: your feature description"

# Push and create a pull request
git push origin feature/your-feature-name
```

### Code Standards

- Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Use ShellCheck for static analysis
- Include comprehensive error handling
- Add appropriate comments and documentation
- Test on multiple distributions when possible

### Reporting Issues

When reporting issues, please include:

- System information (`uname -a`)
- Distribution and version
- systemd version (`systemctl --version`)
- Steps to reproduce

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Linux kernel CPUfreq subsystem developers
- systemd project maintainers
- Open source community for feedback and contributions

<div align="center">

**[⬆ Back to Top](#cpu-governor-performance-configurator)**

Made with ❤️ for the Linux community

</div>
