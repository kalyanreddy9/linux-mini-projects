# Linux Partition Management (Using `parted`)

This project  covers creating, formatting, mounting, and cleaning up partitions on a target disk.  
All steps are fully automated through the Bash script `partition_script.sh`.

---

## Objective
- Create a GPT partition table on a target disk  
- Create two partitions (10 MiB and 20 MiB)  
- Format partitions with **ext4** and **xfs**  
- Mount partitions and make them persistent via `/etc/fstab`  
- Clean up safely when done  

---

##  Commands and Explanations

| Command | Description |
|----------|--------------|
| `lsblk` | Lists all block devices and partitions |
| `sudo parted -s /dev/vdb mklabel gpt` | Creates a new GPT partition table |
| `sudo parted -s /dev/vdb mkpart primary 1MiB 11MiB` | Creates the first 10 MiB partition (ext4) |
| `sudo parted -s /dev/vdb mkpart primary 11MiB 31MiB` | Creates the second 20 MiB partition (xfs) |
| `sudo mkfs.ext4 /dev/vdb1` | Formats first partition as ext4 |
| `sudo mkfs.xfs /dev/vdb2` | Formats second partition as xfs |
| `sudo mkdir -p /mnt/data1 /mnt/data2` | Creates mount points |
| `sudo mount /dev/vdb1 /mnt/data1` | Mounts the first partition |
| `sudo mount /dev/vdb2 /mnt/data2` | Mounts the second partition |
| `sudo blkid` | Displays UUIDs of all partitions |
| `sudo mount -a` | Verifies `/etc/fstab` mounts work |
| `sudo umount /mnt/data1 /mnt/data2` | Unmounts partitions |

---

## Script Overview

### File : `partition_script.sh`

This Bash script automates all partitioning steps including:
- Disk verification  
- Partition creation  
- Formatting  
- Mounting  
- Persistence setup  
- Cleanup  

```bash
./partition_script.sh create
```

### Before Script Execution
```bash
[bob@centos-host ~]$ lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINTS
vda    253:0    0  11G  0 disk 
└─vda1 253:1    0  10G  0 part /
vdb    253:16   0   1G  0 disk 
vdc    253:32   0   1G  0 disk 
vdd    253:48   0   1G  0 disk 
vde    253:64   0   1G  0 disk 
vdf    253:80   0   1G  0 disk 
```


### After Running ./partition_script.sh create
```bash
[bob@centos-host ~]$ lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINTS
vda    253:0    0  11G  0 disk 
└─vda1 253:1    0  10G  0 part /
vdb    253:16   0   1G  0 disk 
├─vdb1 253:17   0  10M  0 part /mnt/data1
└─vdb2 253:18   0  20M  0 part /mnt/data2
vdc    253:32   0   1G  0 disk 
vdd    253:48   0   1G  0 disk 
vde    253:64   0   1G  0 disk 
vdf    253:80   0   1G  0 disk 
```

### After Running ./partition_script.sh cleanup

```bash
[bob@centos-host ~]$ lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINTS
vda    253:0    0  11G  0 disk 
└─vda1 253:1    0  10G  0 part /
vdb    253:16   0   1G  0 disk 
vdc    253:32   0   1G  0 disk 
vdd    253:48   0   1G  0 disk 
vde    253:64   0   1G  0 disk 
vdf    253:80   0   1G  0 disk 
```