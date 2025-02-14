#!/bin/sh

kernel_version="linux-4.19.325"
kernel_version_file=$kernel_version.tar.gz
image_file=ft_linux.img  # It could be replaced with local disk, but for obvious reasons (avoid accidents, no need for a VM), I prefer to work on a image.

echo Installing needed package
sudo pacman -Sy --needed gcc bc parted || exit 1


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

#if [ ! -f $image_file ]; then
  dd if=/dev/zero of=$image_file bs=1M count=8192 || exit 1
  parted $image_file mktable msdos || exit 1
  parted $image_file mkpart primary fat32 1 1024 || exit 1
  parted $image_file mkpart primary ext4 1024 7167 || exit 1
  parted $image_file mkpart primary linux-swap 7168 8191 || exit 1
#fi
