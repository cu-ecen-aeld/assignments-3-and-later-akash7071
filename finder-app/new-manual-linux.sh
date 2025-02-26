#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}
chown $USER:$USER kernel



cd "$OUTDIR"
if [ ! -d "linux-stable" ]; then
    # Clone only if the repository does not exist.
    echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	read -n 1 -s -r -p "Press any key to continue..."
    git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION} || { echo "Git clone failed!"; exit 1; }
	read -n 1 -s -r -p "Press any key to continue..."
fi

if [ ! -e "linux-stable/arch/${ARCH}/boot/Image" ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}	
	


    # TODO: Add your kernel build steps here
    # Clean the build tree
    sudo make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper

    # Configure the kernel (e.g., using the default configuration for the architecture)
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig

    # Build the kernel image
    make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
	
    #Build any kernel modules
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
	
    #Build any device tree
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

echo "Adding the Image in outdir"
cp -a ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/

echo "Creating the staging directory for the root filesystem"

cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p rootfs
cd rootfs

mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

tree -d

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
	
	make distclean
	make defconfig
	

else
    cd "${OUTDIR}/busybox"
fi

# TODO: Make and install busybox
sudo make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} 
make CONFIG_PREFIX=${FINDER_APP_DIR}/${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install
echo "Library dependencies"
${CROSS_COMPILE}readelf -a ${FINDER_APP_DIR}/${OUTDIR}/rootfs/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ${FINDER_APP_DIR}/${OUTDIR}/rootfs/bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs

cd ${FINDER_APP_DIR}/${OUTDIR}/rootfs
export SYSROOT=$(sudo ${CROSS_COMPILE}gcc -print-sysroot)
cp -a $SYSROOT/lib/ld-linux-aarch64.so.1 lib/
cp -a $SYSROOT/lib64/libm.so.6 lib64/
cp -a $SYSROOT/lib64/libresolv.so.2 lib64/
cp -a $SYSROOT/lib64/libc.so.6 lib64/
# TODO: Make device nodes
#sudo mknod -m 666 dev/null c 1 3
#sudo mknod -m 660 dev/console c 5 1
ls -l dev
# TODO: Clean and build the writer utility
cd ${FINDER_APP_DIR}   #change to finder app directory
sudo make clean
sudo make CROSS_COMPILE=aarch64-linux-gnu-

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp -a finder.sh ${OUTDIR}/rootfs/home
cp -a conf/ ${OUTDIR}/rootfs/home
#cp -a conf/username.txt ${OUTDIR}/rootfs/home
#cp -a conf/assignment.txt ${OUTDIR}/rootfs/home
cp -a finder-test.sh ${OUTDIR}/rootfs/home
cp -a writer ${OUTDIR}/rootfs/home
cp -a autorun-qemu.sh ${OUTDIR}/rootfs/home
# TODO: Chown the root directory

sudo chown -R root:root ${FINDER_APP_DIR}/${OUTDIR}/rootfs
# TODO: Create initramfs.cpio.gz
cd ${FINDER_APP_DIR}/${OUTDIR}/rootfs
find . | cpio -H newc -ov --owner root:root > ${FINDER_APP_DIR}/${OUTDIR}/initramfs.cpio
gzip -f ${FINDER_APP_DIR}/${OUTDIR}/initramfs.cpio