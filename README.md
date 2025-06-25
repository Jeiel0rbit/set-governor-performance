# set-governor-performance
> Force 'cpupower' to use the performance governor if it isn’t available in 'powerprofilesctl'.
```
curl -s https://raw.githubusercontent.com/Jeiel0rbit/set-governor-performance/refs/heads/main/set-governor-performance.sh | bash
```
Save the script to a file

```bash
nano set-governor-performance.sh
```
Paste in the contents of the script from above and save (Ctrl + O, Enter, Ctrl + X).
Make it executable
```bash
chmod +x set-governor-performance.sh
```
Run it with `sudo`
```bash
sudo ./set-governor-performance.sh
```

Run the real-time test with:
```bash
watch -n 1 "cat /proc/cpuinfo | grep 'MHz'"
```
## My History

I checked which CPU frequency driver I’m using:

```bash
cat /sys/devices/system/cpu/cpufreq/policy1/scaling_driver
# acpi-cpufreq
```

It turned out that this driver isn’t fully compatible. So I looked up which governor is actually in use under the hood:

```bash
cpupower frequency-info
```

Sample output:

```bash
analyzing CPU 1:
driver: acpi-cpufreq
CPUs which run at the same hardware frequency: 1
CPUs which need to have their frequency coordinated by software: 1
maximum transition latency: 4.0 us
hardware limits: 1.40 GHz - 3.50 GHz
available frequency steps:  3.50 GHz, 3.20 GHz, 2.90 GHz, 2.40 GHz, 1.90 GHz, 1.40 GHz
available cpufreq governors: conservative ondemand userspace powersave performance schedutil
current policy: frequency should be within 1.40 GHz and 3.50 GHz.
The governor "schedutil" may decide which speed to use
within this range.
current CPU frequency: 3.79 GHz (asserted by call to kernel)
boost state support:
Supported: yes
Active: yes
```

As we can see, `schedutil` is the one already in use (the same “Balanced” mode shown in the GUI). So I forced a switch to the `performance` governor:

```bash
sudo cpupower frequency-set -g performance
Setting cpu: 0
Setting cpu: 1
```

This enforces it under the hood, but the GUI still shows “Balanced.” I’ll reach out to the GUI tool’s maintainer to request support for this driver/governor combination.

Anyone can test this:

Switch to the `schedutil` (Balanced) governor:

```bash
 sudo cpupower frequency-set -g schedutil watch -n 1 "grep 'MHz' /proc/cpuinfo" 
```

Switch to the `performance` governor:

```bash 
sudo cpupower frequency-set -g performance watch -n 1 "grep 'MHz' /proc/cpuinfo" 
```

> [!warning]
> You regret it? No problem. Run reverse script.
```
curl -s https://github.com/Jeiel0rbit/set-governor-performance/blob/main/reverter_governor.sh | bash
```
> Restart the machine.