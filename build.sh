#!/bin/bash

#Display messages
 msg() {
    ALL_OFF="\e[1;0m"
    BOLD="\e[1;1m"
    GREEN="${BOLD}\e[1;32m"
      local mesg=$1; shift
      printf "${GREEN}==>${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@" >&2
 }

#Build the 'any' packages on armv7
if [ $3 == "any" ]; then
	_ARCH="armv7h"
else
	_ARCH="$3"
fi

######## Some globals to set ########
#Only set this one
_BUILDDIR=/opt/build-dir

#Leave these alone
_ROOTFS=$_BUILDDIR/$_ARCH
_REPODIR=$_BUILDDIR/repo
#_PKGDIR=$_BUILDDIR/packages
_PKGDIR=/opt/repo/mirror/stable



#enable qemu binaries
msg "===== Enabling qemu binaries ====="
sudo update-binfmts --enable qemu-arm
sudo update-binfmts --enable qemu-aarch64 

#pulling git repos
#msg "===== Updating the github repo ====="
#for dir in $_REPODIR/*; do (cd "$dir" && git pull); done

#updating rootfs 
msg "===== Updating the rootfs ====="
sudo systemd-nspawn -D $_ROOTFS/ -u manjaro sudo pacman -Syyu --noconfirm

#cp package to rootfs
msg "===== Copying build directory {$1/$2} to rootfs ====="
sudo systemd-nspawn -D $_ROOTFS/ -u manjaro --chdir=/home/manjaro/ mkdir build
sudo cp -rp /var/lib/jenkins/workspace/$2/$2/* $_ROOTFS/home/manjaro/build/

#build package
msg "===== Building {$2} ====="
sudo systemd-nspawn -D $_ROOTFS/ -u manjaro --chdir=/home/manjaro/ sudo chmod -R 777 build/
sudo systemd-nspawn -D $_ROOTFS/ -u manjaro --chdir=/home/manjaro/build/ makepkg -scr --noconfirm --sign
#read -p "Press [Enter] to continue"

if ls $_ROOTFS/home/manjaro/build/*.pkg.tar.xz* 1> /dev/null 2>&1; then
    #pull package out of rootfs
    msg "!!!!! +++++ ===== Package Succeeded ===== +++++ !!!!!"
    msg "===== Extracting finished package out of rootfs ====="
    cp $_ROOTFS/home/manjaro/build/*.pkg.tar.xz* $_PKGDIR/$3/$1/

    #clean up rootfs
    msg "===== Cleaning rootfs ====="
    sudo rm -r $_ROOTFS/home/manjaro/build/ > /dev/null

else
    msg "!!!!! ++++++ ===== Package failed to build ===== +++++ !!!!!"
    msg "cleaning rootfs"
    sudo rm -r $_ROOTFS/home/manjaro/build/ > /dev/null
    exit 1
fi
