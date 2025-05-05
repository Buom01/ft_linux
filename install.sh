#!/bin/sh

LFS=$(pwd)/system
BFS=$(pwd)/boot
SFS=$(pwd)/swap
kernel_version="linux-4.19.325"
kernel_version_file=$kernel_version.tar.gz
image_file=ft_linux.img  # It could be replaced with local disk, but for obvious reasons (avoid accidents, no need for a VM), I prefer to work on a image.

if [ ! -f $image_file ]; then

  echo Installing needed package
  sudo pacman -Sy --needed bc parted base-devel wget || exit 1

  if [ ! -f $kernel_version_file ]; then
    echo Downloading the kernel
    wget https://cdn.kernel.org/pub/linux/kernel/v4.x/$kernel_version_file || exit 1
  fi

  if [ ! -d $kernel_version ]; then
    echo Extracting the kernel
    tar xf $kernel_version_file || exit 1
  fi

  cd $kernel_version


  # https://www.linuxfromscratch.org/lfs/view/stable/chapter10/kernel.html
  if [ ! -f .config ]; then
    echo "Cleaning up the extracted tar" 
    make mrproper || exit 1


    echo "Using the default config"
    make defconfig || exit 1
  fi

  echo Launching compilation
  make || exit 1

  cd ..

  echo Creating the image disk

  dd if=/dev/zero of=$image_file bs=1M count=8192 || exit 1
  parted $image_file mktable msdos || exit 1
  parted $image_file mkpart primary fat32 1 1024 || exit 1
  parted $image_file mkpart primary ext4 1024 7167 || exit 1
  parted $image_file mkpart primary linux-swap 7168 8191 || exit 1

fi

loopdisk=$(losetup -j ./ft_linux.img | head -n 1 | cut -f1 -d":")
if [ -z "$loopdisk" ]; then
  loopdisk=$(sudo losetup -Pf --show ft_linux.img) || exit 1
fi

echo "Loopdisk at $loopdisk"

if ! mountpoint -q $LFS ; then

  echo "Formatting and mounting..."

  if [ -d $BFS ]; then
    sudo umount $BFS
    sudo umount $LFS
    sudo umount $SFS
  fi

  mkdir -p $BFS $LFS $SFS

  umask 022 # https://www.linuxfromscratch.org/lfs/view/stable/chapter02/aboutlfs.html

  sudo mkfs.vfat "${loopdisk}p1"
  sudo mkfs.ext4 "${loopdisk}p2"
  sudo mkswap "${loopdisk}p3"
  sudo mount -w "${loopdisk}p1" $BFS
  sudo mount -w "${loopdisk}p2" $LFS

fi

sudo mkdir -p $BFS/efi $LFS/home $LFS/usr $LFS/opt $LFS/usr/src


