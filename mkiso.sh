KERNEL_URL="https://www.kernel.org/pub/linux/kernel/v5.x/linux-5.10.17.tar.xz"
SYSLINUX_URL="https://kernel.org/pub/linux/utils/boot/syslinux/6.xx/syslinux-6.03.tar.gz"
SOURCE_ROOT=$PWD
BUILD_DIR="${SOURCE_ROOT}/build"
OUT_DIR="${SOURCE_ROOT}/build/out"

# make build dir
if [ ! -d $BUILD_DIR ]; then
    mkdir $BUILD_DIR
    mkdir $BUILD_DIR/init
    mkdir $OUT_DIR
    mkdir $OUT_DIR/isolinux
fi

pushd $BUILD_DIR

# get sources
cp -r $SOURCE_ROOT/hello.zig $BUILD_DIR
cp $SOURCE_ROOT/isolinux.cfg $BUILD_DIR
if [ ! -d linux-5.10.17 ]; then
    echo "Downloading kernel"
    wget -qO- $KERNEL_URL | tar -xJ
fi
if [ ! -d syslinux-6.03 ]; then
    echo "Downloading syslinux"
    wget -qO- $SYSLINUX_URL | tar -xz
fi


# build linux
echo "Build kernel"
pushd linux-5.10.17
make mrproper
cp $SOURCE_ROOT/default.config .config
make -j$(nproc)
cp arch/x86/boot/bzImage $OUT_DIR/isolinux/vmlinuz
popd

# build init and initrd
echo "Build init"
pushd init
zig build-exe $BUILD_DIR/hello.zig --name init # why not? https://ziglang.org/
strip init
find . | cpio -o -H newc | gzip - > $OUT_DIR/isolinux/initrd.gz
popd

# get isolinux
pushd syslinux-6.03
cp -v bios/core/isolinux.bin $OUT_DIR/isolinux/isolinux.bin
cp -v bios/com32/elflink/ldlinux/ldlinux.c32 $OUT_DIR/isolinux/ldlinux.c32
cp -v $BUILD_DIR/isolinux.cfg $OUT_DIR/isolinux/isolinux.cfg
popd


# make iso
echo "Make iso"
mkisofs -R -l -L -D \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 \
        -boot-info-table \
        -V HELLO_WORLD \
        $OUT_DIR \
        > $SOURCE_ROOT/hello_world.iso

popd
