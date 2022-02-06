# check the shell
if ! test -n "$BASH_VERSION"
then
    echo "This script must be run using bash."
    exit 1
fi

commands=(
    realpath
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

kernel_url="https://www.kernel.org/pub/linux/kernel/v5.x/linux-5.10.17.tar.xz"
kernel_dir="linux-5.10.17"
syslinux_url="https://kernel.org/pub/linux/utils/boot/syslinux/6.xx/syslinux-6.03.tar.gz"
syslinux_dir="syslinux-6.03"
build_root=$(pwd)
source_root=$(dirname $0 | xargs realpath)
build_dir="${build_root}/linux_hello_world_build"
out_dir="${build_dir}/out"
iso_out_dir=$build_root

# make build dir
if [ ! -d $build_dir ]
then
    mkdir $build_dir
    mkdir $build_dir/init
    mkdir $out_dir
    mkdir $out_dir/isolinux
fi


pushd $build_dir > /dev/null

# get sources
cp $source_root/hello.c $build_dir
cp $source_root/isolinux.cfg $build_dir
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
pushd $kernel_dir > /dev/null
make mrproper
cp $source_root/default.config .config
make -j$(nproc)
cp arch/x86/boot/bzImage $out_dir/isolinux/vmlinuz
popd > /dev/null

# build init and initrd
echo "Build init"
pushd init > /dev/null
gcc -static -static-libgcc $build_dir/hello.c -o init
strip init
find . | cpio -o -H newc | gzip - > $out_dir/isolinux/initrd.gz
popd > /dev/null

# get isolinux
pushd $syslinux_dir > /dev/null
cp bios/core/isolinux.bin $out_dir/isolinux/isolinux.bin
cp bios/com32/elflink/ldlinux/ldlinux.c32 $out_dir/isolinux/ldlinux.c32
cp $build_dir/isolinux.cfg $out_dir/isolinux/isolinux.cfg
popd > /dev/null


# make iso
echo "Make iso"
mkisofs -R -l -L -D \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -input-charset ascii \
        -no-emul-boot -boot-load-size 4 \
        -boot-info-table \
        -V HELLO_WORLD \
        $out_dir \
        > $iso_out_dir/hello_world.iso

popd > /dev/null
