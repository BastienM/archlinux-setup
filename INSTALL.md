### Install

Procedure for Archlinux using UEFI and BTRFS

#### Boot from the usb (UEFI)

> F12 to enter boot menu

#### Connect to Internet

```
# while on wifi
$ wifi-menu

# or via ethernet (dhcp)
$ dhcpd
```

#### Sync'ing clock

```
$ timedatectl set-ntp true
```

#### Create our partitions:

> 1 512MB EFI partition # Hex code ef00

> 2 rest Linux partiton  # Hex code 8300

```
$ cgdisk /dev/YOUR_DEVICE
```

#### Formating the partitions

```
# EFI
$ mkfs.vfat -F 32 -n BOOT /dev/YOUR_DEVICEp1

# BTRFS
$ mkfs.btrfs -L ARCH /dev/YOUR_DEVICEp2
```

#### Preparing the BTRFS architecture

```
$ mount /dev/YOUR_DEVICEp2 /mnt
$ cd /mnt

# create subvolumes
$ btrfs subvolume create @
$ mkdir -p @/{/home, /.snapshots, /tmp, /var}

$ btrfs subvolume create @home
$ btrfs subvolume create @snapshots
$ btrfs subvolume create @tmp
$ btrfs subvolume create @var

umount -R /mnt
```

#### Preparing the OS

```
# mounting our subvolumes
$ mount -o compress=lzo,space_cache,noatime,ssd,subvol=@ /dev/YOUR_DEVICEp2 /mnt
$ mount -o compress=lzo,space_cache,noatime,ssd,subvol=@home /dev/YOUR_DEVICEp2 /mnt/home
$ mount -o compress=lzo,space_cache,noatime,ssd,subvol=@snapshots /dev/YOUR_DEVICEp2 /mnt/.snapshots
$ mount -o compress=lzo,space_cache,noatime,ssd,subvol=@tmp /dev/YOUR_DEVICEp2 /mnt/tmp
$ mount -o compress=lzo,space_cache,noatime,ssd,subvol=@var /dev/YOUR_DEVICEp2 /mnt/var

# then the EFI partition
$ mkdir /mnt/boot
$ mount /dev/YOUR_DEVICEp1 /mnt/boot

# Installing the base system and needed dependencies
$ pacstrap /mnt base base-devel btrfs-progs vim git

# Copying the current mounting schema
$ genfstab -Up /mnt >> /mnt/etc/fstab
```

#### Chrooting into our install

```
$ arch-chroot /mnt
```

#### Basic setup

##### locale

```
$ echo LANG=en_US.UTF-8 > /etc/locale.conf
# Then generating our choosen locales ...
$ locale-gen

# and persisting it
$ echo 'LANG=en_US.UTF-8' > /etc/locale.conf
```

##### Clock

```
$ ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime
$ hwclock --systohc
```

##### Hostname

```
$ echo gladOS > /etc/hostname
```

##### Root account

```
# Changing the root's password
$ passwd
```

##### `mkinitcpio`

```
$ vim /etc/mkinitcpio.conf
[...]
# we must remove the "fsck" hook ad add "keymap encrypt" before "filesystems"
HOOKS="base udev autodetect modconf block btrfs keymap encrypt filesystems keyboard"

# then recompile the initrd image
$ mkinitcpio -p linux
```

##### `systemd-boot`

```
# Enable Intel microcode updates
pacman -S intel-ucode

bootctl --path=/boot install
```

> You can get the root PARTUUID with `blkid /dev/YOUR_DEVICEp2'

```
# Adding a new entry to the bootloader
$ vim /boot/loader/entries/archlinux.conf

title     Archlinux
linux     /vmlinuz-linux
initrd    /intel-ucode.img
initrd    /initramfs-linux.img
options   root=PARTUUID=<root-UUID> rw rootflags=subvol=@ 
```

```
# Setting the default bootloader entry to our
$ vim /boot/loader/loader.conf

default		archlinux
timeout   0
editor    0
```

####  Snapshot time

At this point you should have minimal working OS, creating a snapshot can be worthwhile.

```
$ btrfs subvolume snapshot -r / /.snapshots/@root-$(date +%F-%R)
```

#### Rebooting to our finished install

```
$ exit

# unmount all filesystems
$ umount -R /mnt
$ reboot
```
