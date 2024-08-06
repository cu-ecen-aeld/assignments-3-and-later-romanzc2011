#!/bin/sh
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/home/romancampbell/Coursera/Linux_Intro_to_Buildroot/assign3_kernel
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
SYSROOT=$(which ${CROSS_COMPILE}gcc)
SYSROOT_LIB=$(dirname $SYSROOT)/../aarch64-none-linux-gnu/libc

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi

if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    echo "make mrproper============================================="
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper

    echo "make defconfig============================================"
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig

    echo "make all=================================================="
    make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all

    echo "SKIPPING make modules=============================================="
    #make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules

    echo "make dtbs================================================="
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

echo "Adding the Image in outdir"
cp -rp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}


cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# Creating rootfs staging directory
mkdir -p ${OUTDIR}/rootfs
cd ${OUTDIR}/rootfs


# TODO: Create necessary base directories
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin 
mkdir -p var/log

if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make distclean
    make defconfig
else
    cd busybox
fi

# TODO: Make and install busybox
echo "Installing busybox.................................."
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} CONFIG_PREFIX=${OUTDIR}/rootfs install
echo "busybox install SUCCESS............................."

# Setting proper permissions for busybox
sudo chmod 4755 ${OUTDIR}/rootfs/bin/busybox

cd ${OUTDIR}/rootfs

echo "Library dependencies................................"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
cp ${SYSROOT_LIB}/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib 
cp ${SYSROOT_LIB}/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64
cp ${SYSROOT_LIB}/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64 
cp ${SYSROOT_LIB}/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64

echo "Make device nodes..................................."
if [ ! -e ${OUTDIR}/rootfs/dev/null ];
then
    sudo mknod -m 666 dev/null c 1 3 
elif [ ! -e ${OUTDIR}/dev/console ];
then
    sudo mknod -m 600 dev/console c 5 1
else
    echo "null and console devices already exist"
fi

# Clean and build the writer utility
cd ${FINDER_APP_DIR}
make clean 
make CROSS_COMPILE=${CROSS_COMPILE}

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp ${FINDER_APP_DIR}/finder-test.sh ${OUTDIR}/rootfs/home
cp ${FINDER_APP_DIR}/finder.sh ${OUTDIR}/rootfs/home
cp ${FINDER_APP_DIR}/autorun-qemu.sh ${OUTDIR}/rootfs/home
cp ${FINDER_APP_DIR}/writer ${OUTDIR}/rootfs/home

mkdir -p ${OUTDIR}/rootfs/home/conf
cp conf/username.txt ${OUTDIR}/rootfs/conf/username.txt 
cp conf/assignment.txt ${OUTDIR}/rootfs/conf/assignment.txt 

sudo chown -R root:root ${OUTDIR}/rootfs

cd ${OUTDIR}/rootfs
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
gzip ${OUTDIR}/initramfs.cpio
echo "Build COMPLETE"
