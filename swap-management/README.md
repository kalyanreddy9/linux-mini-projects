# Linux Swap Management (File-based)

This project demonstrates how to **create, verify, extend, and remove swap space** in Linux using swap **files** instead of partitions.  
It’s completely automated through a Bash script: `swap_management.sh`.

---

## Objective
- Create a new swap file and enable it  
- Add additional swap files for more memory  
- Verify kernel swap usage and priority  
- Delete specific swap files safely  
- Make swap persistent across reboots via `/etc/fstab`


---

## Script Overview

### File: `swap_management.sh`

| Command | Description |
|----------|--------------|
| `./swap_management.sh create` | Creates a 100 MB swap file (`/swapfile1`) |
| `./swap_management.sh add` | Adds an additional 50 MB swap file (`/swapfile2`) |
| `./swap_management.sh verify` | Displays swap usage and priority info |
| `./swap_management.sh delete` | Disables and removes all swap files created by this script |

---

## 🧾 Commands Used (with Explanation)

| Command | Purpose |
|----------|----------|
| `sudo fallocate -l 100M /swapfile1` | Allocates a 100 MB empty file |
| `sudo chmod 600 /swapfile1` | Restricts access to root only |
| `sudo mkswap /swapfile1` | Converts the file into a swap area |
| `sudo swapon /swapfile1` | Enables the swap immediately |
| `sudo swapon --show` | Lists active swap areas |
| `free -h` | Displays system memory and swap usage |
| `cat /proc/swaps` | Kernel-level info of swap devices |
| `echo "/swapfile1 none swap sw 0 0" >> /etc/fstab` | Makes swap persistent |
| `sudo swapoff /swapfile1` | Disables swap |
| `sudo rm -f /swapfile1` | Deletes swap file |
| `sudo sed -i "\|/swapfile1\|d" /etc/fstab` | Removes entry from `/etc/fstab` |

---

## Script Execution and Output

### Create Swap File
```bash
[bob@centos-host ~]$ ./swap_management.sh create
Creating swap file /swapfile1 of size 100M ...
Setting up swapspace version 1, size = 100 MiB (104853504 bytes)
no label, UUID=8b5f98e8-6303-43ee-9847-0b78dd5f4560
/swapfile1 none swap sw 0 0
Swap file /swapfile1 created and enabled successfully.

NAME       TYPE SIZE  USED PRIO
/swapfile  file   2G 25.3M   -2
/swapfile1 file 100M    0B   -3

               total        used        free      shared  buff/cache   available
Mem:           959Mi       262Mi       612Mi       4.0Mi       226Mi       697Mi
Swap:          2.1Gi        25Mi       2.1Gi

```
### Verify Swap
```bash
[bob@centos-host ~]$ ./swap_management.sh verify
Verifying active swap areas...
NAME       TYPE SIZE  USED PRIO
/swapfile  file   2G 25.3M   -2
/swapfile1 file 100M    0B   -3

               total        used        free      shared  buff/cache   available
Mem:           959Mi       262Mi       612Mi       4.0Mi       226Mi       697Mi
Swap:          2.1Gi        25Mi       2.1Gi

Filename                                Type            Size            Used            Priority
/swapfile                               file            2097148         25872           -2
/swapfile1                              file            102396          0               -3
```
### Add Another Swap File
```bash
[bob@centos-host ~]$ ./swap_management.sh add
Creating swap file /swapfile2 of size 50M ...
Setting up swapspace version 1, size = 50 MiB (52424704 bytes)
no label, UUID=aae1c970-438b-421a-b7ed-d35d85051be0
/swapfile2 none swap sw 0 0
Swap file /swapfile2 created and enabled successfully.

NAME       TYPE SIZE  USED PRIO
/swapfile  file   2G 25.3M   -2
/swapfile1 file 100M    0B   -3
/swapfile2 file  50M    0B   -4

               total        used        free      shared  buff/cache   available
Mem:           959Mi       262Mi       612Mi       4.0Mi       227Mi       697Mi
Swap:          2.1Gi        25Mi       2.1Gi
```

### Verify Again

```bash
[bob@centos-host ~]$ ./swap_management.sh verify
Verifying active swap areas...
NAME       TYPE SIZE  USED PRIO
/swapfile  file   2G 25.3M   -2
/swapfile1 file 100M    0B   -3
/swapfile2 file  50M    0B   -4

Filename                                Type            Size            Used            Priority
/swapfile                               file            2097148         25872           -2
/swapfile1                              file            102396          0               -3
/swapfile2                              file            51196           0               -4
```

### Delete Swap
```bash
[bob@centos-host ~]$ ./swap_management.sh delete
Disabling and removing all swap files...
Removing /etc/fstab entries...
Deleting swap files...
Swap disabled and files removed.

[bob@centos-host ~]$ ./swap_management.sh verify
Verifying active swap areas...
NAME      TYPE SIZE USED PRIO
/swapfile file   2G  25M   -2

               total        used        free      shared  buff/cache   available
Mem:           959Mi       256Mi       619Mi       4.0Mi       225Mi       703Mi
Swap:          2.0Gi        24Mi       2.0Gi
```

