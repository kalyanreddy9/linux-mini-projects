# Linux LVM Management (PV → VG → LV)

This project demonstrates **Logical Volume Management (LVM)** on Linux.  
It shows how to create, extend, verify, and clean up LVM storage — using real disks and automated Bash scripting.

---

##  Objective
- Create Physical Volumes (PVs) from multiple disks  
- Combine them into a Volume Group (VG)  
- Create a Logical Volume (LV) and format it  
- Extend both VG and LV dynamically  
- Validate and clean up LVM configuration safely  

---

## Script Overview

### File: `lvm_management.sh`

| Command | Description |
|----------|--------------|
| `./lvm_management.sh create` | Creates full LVM stack — PV, VG, LV, filesystem, and persistent mount |
| `./lvm_management.sh extend` | Adds a new disk to VG and extends LV by +0.8 GB |
| `./lvm_management.sh verify` | Displays current PV, VG, LV, and mount information |
| `./lvm_management.sh cleanup` | Unmounts, removes LV/VG/PV, and cleans up `/etc/fstab` and mount dirs |

---

## 🧾 Commands Used (with Explanations)

| Command | Purpose |
|----------|----------|
| `sudo pvcreate /dev/vdc /dev/vdd` | Converts physical disks into LVM-compatible Physical Volumes |
| `sudo vgcreate vgdata /dev/vdc /dev/vdd` | Combines PVs into a Volume Group named `vgdata` |
| `sudo lvcreate -L 1.5G -n lvdata vgdata` | Creates a Logical Volume `lvdata` of 1.5 GB inside `vgdata` |
| `sudo mkfs.xfs /dev/vgdata/lvdata` | Formats the Logical Volume with XFS filesystem |
| `sudo mount /dev/vgdata/lvdata /mnt/lvmdata` | Mounts the Logical Volume |
| `sudo blkid -s UUID -o value /dev/vgdata/lvdata` | Retrieves the UUID for persistence |
| `sudo vgextend vgdata /dev/vde` | Adds an additional disk `/dev/vde` to the VG |
| `sudo lvextend -L +0.8G /dev/vgdata/lvdata` | Extends the existing LV by 0.8 GB |
| `sudo xfs_growfs /mnt/lvmdata` | Expands the filesystem to match the new LV size |
| `sudo lvremove /dev/vgdata/lvdata` | Removes the Logical Volume |
| `sudo vgremove vgdata` | Removes the Volume Group |
| `sudo pvremove /dev/vdc /dev/vdd /dev/vde` | Removes Physical Volume labels |

---

## Execution and Output

### Create LVM Setup

```bash
[bob@centos-host ~]$ ./lvm_management.sh create
Creating LVM setup...
Step 1: Creating Physical Volumes...
  Physical volume "/dev/vdc" successfully created.
  Physical volume "/dev/vdd" successfully created.
  PV         VG Fmt  Attr PSize PFree
  /dev/vdc      lvm2 ---  1.00g 1.00g
  /dev/vdd      lvm2 ---  1.00g 1.00g
Step 2: Creating Volume Group vgdata...
  Volume group "vgdata" successfully created
  VG     #PV #LV #SN Attr   VSize VFree
  vgdata   2   0   0 wz--n- 1.99g 1.99g
Step 3: Creating Logical Volume lvdata...
  Logical volume "lvdata" created.
Step 4: Formatting and Mounting...
Mount successful at /mnt/lvmdata
/dev/mapper/vgdata-lvdata  1.5G   43M  1.4G   3% /mnt/lvmdata
UUID=0be0637c-7489-43a2-8818-e7bcde949ed1  /mnt/lvmdata  xfs  defaults  0 2
Persistent mount entry added.
```

### Verify LVM
```bash
[bob@centos-host ~]$ ./lvm_management.sh verify
Verifying current LVM setup...
  PV         VG     Fmt  Attr PSize    PFree  
  /dev/vdc   vgdata lvm2 a--  1020.00m      0 
  /dev/vdd   vgdata lvm2 a--  1020.00m 504.00m
  VG     #PV #LV #SN Attr   VSize VFree  
  vgdata   2   1   0 wz--n- 1.99g 504.00m
  LV     VG     Attr       LSize Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lvdata vgdata -wi-ao---- 1.50g                                                    

/dev/mapper/vgdata-lvdata  1.5G   43M  1.4G   3% /mnt/lvmdata
```

### Extend LVM
```bash
[bob@centos-host ~]$ ./lvm_management.sh extend
Extending LVM with new disk /dev/vde...
Step 1: Adding new disk as Physical Volume...
  Physical volume "/dev/vde" successfully created.
  Volume group "vgdata" successfully extended
  VG     #PV #LV #SN Attr   VSize  VFree 
  vgdata   3   1   0 wz--n- <2.99g <1.49g
Step 2: Extending Logical Volume by 0.8G...
  Size of logical volume vgdata/lvdata changed from 1.50 GiB to 2.30 GiB.
  Logical volume vgdata/lvdata successfully resized.
  Filesystem resized using xfs_growfs.

/dev/mapper/vgdata-lvdata  2.3G   49M  2.2G   3% /mnt/lvmdata
```


### Verify Again
```bash
[bob@centos-host ~]$ ./lvm_management.sh verify
Verifying current LVM setup...
  PV         VG     Fmt  Attr PSize    PFree  
  /dev/vdc   vgdata lvm2 a--  1020.00m      0 
  /dev/vdd   vgdata lvm2 a--  1020.00m      0 
  /dev/vde   vgdata lvm2 a--  1020.00m 704.00m
  VG     #PV #LV #SN Attr   VSize  VFree  
  vgdata   3   1   0 wz--n- <2.99g 704.00m
  LV     VG     Attr       LSize Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lvdata vgdata -wi-ao---- 2.30g                                                    

/dev/mapper/vgdata-lvdata  2.3G   49M  2.2G   3% /mnt/lvmdata
```

### Cleanup
```bash
[bob@centos-host ~]$ ./lvm_management.sh cleanup
Cleaning up LVM setup...
Unmounting LV...
Removing fstab entry...
Removing LV, VG, and PVs...
  Logical volume "lvdata" successfully removed.
  Volume group "vgdata" successfully removed
  Labels on physical volumes successfully wiped.
Deleting mount directory...
Cleanup complete.
```
