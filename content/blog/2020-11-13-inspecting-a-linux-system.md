---
title: Inspecting a Linux System
date: 2020-11-13
tags:
- linux
- systems
thumbnail: night_waves_thumb.png
teaser: How to learn more about a Linux system.
draft: true
---

_Some intro notes I compiled for a junior software engineer on learning more about a Linux system through the command line._

The `/etc/os-release` file contains system information of note. For example:

```bash
cat /etc/os-release
NAME="Ubuntu"
VERSION="16.04.6 LTS (Xenial Xerus)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 16.04.6 LTS"
VERSION_ID="16.04"
HOME_URL="http://www.ubuntu.com/"
SUPPORT_URL="http://help.ubuntu.com/"
BUG_REPORT_URL="http://bugs.launchpad.net/ubuntu/"
VERSION_CODENAME=xenial
UBUNTU_CODENAME=xenial
```

`uname -r` reports the Linux kernel version:

```text
uname -r
4.19.76-linuxkit
```

`uname --help` explains the other useful information to glean from `uname`:

```text
uname --help
Usage: uname [OPTION]...
Print certain system information.  With no OPTION, same as -s.

  -a, --all                print all information, in the following order,
                             except omit -p and -i if unknown:
  -s, --kernel-name        print the kernel name
  -n, --nodename           print the network node hostname
  -r, --kernel-release     print the kernel release
  -v, --kernel-version     print the kernel version
  -m, --machine            print the machine hardware name
  -p, --processor          print the processor type (non-portable)
  -i, --hardware-platform  print the hardware platform (non-portable)
  -o, --operating-system   print the operating system
      --help     display this help and exit
      --version  output version information and exit
```

`lsb_release -a` shows information about the Linux distribution:

```text
lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 16.04.6 LTS
Release:        16.04
Codename:       xenial
```

`du` can be used to inspect disk usage for a particular directory; `du --help` shows some tricks for using it effectively. For example:

```text
sudo du --human-readable /var/log
308K    /var/log/sysstat
49M     /var/log
```

Similarly, `df` can be used to inspect the system's disk usage, with some helpful additional context. For example, to inspect the mounted file systems, mount points, space used, and space available for each, in megabytes:

```text
df -m
Filesystem     1M-blocks   Used Available Use% Mounted on
overlay            59820  56886         0 100% /
tmpfs                 64      0        64   0% /dev
tmpfs                996      0       996   0% /sys/fs/cgroup
shm                   64      0        64   0% /dev/shm
grpcfuse          476803 253347    214581  55% /src
/dev/vda1          59820  56886         0 100% /worker-state
tmpfs                996      0       996   0% /proc/acpi
tmpfs                996      0       996   0% /sys/firmware
```

The `/proc/cpuinfo` file containts CPU model information. Similarly, `lscpu` reports CPU details. For example:

```text
lscpu
Architecture:        x86_64
CPU op-mode(s):      32-bit, 64-bit
Byte Order:          Little Endian
CPU(s):              4
On-line CPU(s) list: 0-3
Thread(s) per core:  1
Core(s) per socket:  1
Socket(s):           4
Vendor ID:           GenuineIntel
CPU family:          6
Model:               158
Model name:          Intel(R) Core(TM) i7-7700HQ CPU @ 2.80GHz
Stepping:            9
CPU MHz:             2800.000
BogoMIPS:            5616.00
L1d cache:           32K
L1i cache:           32K
L2 cache:            256K
L3 cache:            6144K
Flags:               fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss ht pbe syscall nx pdpe1gb lm constant_tsc rep_good nopl xtopology nonstop_tsc cpuid tsc_known_freq pni pclmulqdq dtes64 ds_cpl ssse3 sdbg fma cx16 xtpr pcid sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch pti fsgsbase bmi1 avx2 bmi2 erms xsaveopt arat
```

The `/proc/meminfo` file contains detailed information about the system's memory profile. For example:

```text
cat /proc/meminfo
MemTotal:        2038904 kB
MemFree:          394860 kB
MemAvailable:    1044532 kB
...
```

`free` can be used to inspect current memory consumption. `free -m` shows the current memory use in megabytes, reporting how much memory is free, the size of the swap, and whether it's being used:

```text
free -m
              total        used        free      shared  buff/cache   available
Mem:           1991         871         686           0         432        1028
Swap:          1023         463         560
```

`top` offers a bit more detail and shows current memory as well as CPU use, and also details such as process ID.

`lshw` can be used to inspect your hardware profile. `lshw -short` offers a summary.

`lsblk` displays system storage device information pertaining to hard drives, partitions, and flash drives:

```text
lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sr0     11:0    1 405.6M  0 rom
sr1     11:1    1   106K  0 rom
sr2     11:2    1 251.3M  0 rom
vda    254:0    0  59.6G  0 disk
└─vda1 254:1    0  59.6G  0 part /etc/hosts
```
