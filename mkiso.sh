kernel_url="https://www.kernel.org/pub/linux/kernel/v5.x/linux-5.10.17.tar.xz"
kernel_dir="linux-5.10.17"
syslinux_url="https://kernel.org/pub/linux/utils/boot/syslinux/6.xx/syslinux-6.03.tar.gz"
syslinux_dir="syslinux-6.03"
build_root=$PWD
build_dir="${build_root}/build"
out_dir="${build_root}/build/out"


# check the shell
if ! test -n "$BASH_VERSION"; then
    echo "This script must be run using bash."
    exit 1
fi

commands=(
    cp
    wget    # downloads
    tar     # unpacking archives
    make    # build system
    gcc     # compiler
    flex    # compile kernel
    bison   # compile kernel
    strip   # clear objects from executables
    find    # list files for initramfs
    cpio    # create initramfs archive
    gzip    # compress initramfs
    mkisofs # create bootable iso
)

# check for existance
all_commands_exist=0
for cmd in "${commands[@]}"
do
    if ! command -v $cmd &> /dev/null
    then
        echo "$cmd could not be found"
        all_commands_exist=1
    fi
done

if [ $all_commands_exist -eq 1 ]
then
    exit 1
fi

# make build dir
if [ ! -d $build_dir ]
then
    mkdir $build_dir
    mkdir $build_dir/init
    mkdir $out_dir
    mkdir $out_dir/isolinux
fi

pushd $build_dir

# get sources
cp $build_root/hello.c $build_dir
cp $build_root/isolinux.cfg $build_dir
if [ ! -d $kernel_dir ]
then
    echo "Downloading kernel"
    wget -qO- $kernel_url | tar -xJ
fi
if [ ! -d $syslinux_dir ]
then
    echo "Downloading syslinux"
    wget -qO- $syslinux_url | tar -xz
fi


# build linux
echo "Build kernel"
pushd $kernel_dir
make mrproper
cp $build_root/default.config .config
make -j$(nproc)
cp arch/x86/boot/bzImage $out_dir/isolinux/vmlinuz
popd

# build init and initrd
echo "Build init"
pushd init
gcc -static -static-libgcc $build_dir/hello.c -o init
strip init
find . | cpio -o -H newc | gzip - > $out_dir/isolinux/initrd.gz
popd

# get isolinux
pushd $syslinux_dir
cp -v bios/core/isolinux.bin $out_dir/isolinux/isolinux.bin
cp -v bios/com32/elflink/ldlinux/ldlinux.c32 $out_dir/isolinux/ldlinux.c32
cp -v $build_dir/isolinux.cfg $out_dir/isolinux/isolinux.cfg
popd


# make iso
echo "Make iso"
mkisofs -R -l -L -D \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 \
        -boot-info-table \
        -V HELLO_WORLD \
        $out_dir \
        > $build_root/hello_world.iso

popd
