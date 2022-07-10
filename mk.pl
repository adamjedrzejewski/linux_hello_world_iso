#!/bin/perl

use warnings;
use File::Copy;

use feature qw(say);

$kernel_url = 'https://www.kernel.org/pub/linux/kernel/v5.x/linux-5.10.17.tar.xz';
$kernel_dir = 'linux-5.10.17';
$syslinux_url = 'https://kernel.org/pub/linux/utils/boot/syslinux/6.xx/syslinux-6.03.tar.gz';
$syslinux_dir = 'syslinux-6.03';

sub check_exists_command { 
    my $check = `sh -c 'command -v $_[0]'`; 
    return $check;
}

@commands = (
    'realpath',
    'cp',
    'wget',
    'tar',
    'make',
    'gcc',
    'flex',
    'bison',
    'strip',
    'find',
    'cpio',
    'gzip',
    'mkisofs'
);

foreach (@commands)
{
    check_exists_command $_ or die "$0 requires $_";
}

$nproc = `nproc`;
$build_root = `pwd`;
$build_root =~ s/\R//g;
$source_root =`dirname $0 | xargs realpath`;
$source_root =~ s/\R//g;
$build_dir = "$build_root/linux_hello_world_build";
$out_dir = "$build_dir/out";
$iso_out_dir = $build_root;

if (! -d $build_dir) {
    mkdir "$build_dir";
    mkdir "$build_dir/init";
    mkdir "$out_dir";
    mkdir "$out_dir/isolinux";
}

chdir $build_dir;
copy "$source_root/hello.c", "$build_dir/hello.c";
copy "$source_root/isolinux.cfg", "$build_dir/isolinux.cfg";
if (! -d $kernel_dir) {
    say 'Downloading kernel';
    system "wget -qO- $kernel_url | tar -xJ";
}
if (! -d $syslinux_dir) {
    say 'Downloading syslinux';
    system "wget -qO- $syslinux_url | tar -xz";
}

say 'Build kernel';
chdir "$kernel_dir";
system "make mrproper";
copy "$source_root/default.config", "$build_dir/$kernel_dir/.config";
system "make -j$nproc";
copy "arch/x86/boot/bzImage", "$out_dir/isolinux/vmlinuz";

say 'Build init';
chdir "$build_dir/init";
system "gcc -static -static-libgcc $build_dir/hello.c -o init";
system "strip init";
system "find . | cpio -o -H newc | gzip - > $out_dir/isolinux/initrd.gz";

# get isolinux
copy "$build_dir/$syslinux_dir/bios/core/isolinux.bin", "$out_dir/isolinux/isolinux.bin";
copy "$build_dir/$syslinux_dir/bios/com32/elflink/ldlinux/ldlinux.c32", "$out_dir/isolinux/ldlinux.c32";
copy "$build_dir/isolinux.cfg", "$out_dir/isolinux/isolinux.cfg";

say "Make iso";
chdir $iso_out_dir;
system "mkisofs -R -l -L -D \\
            -b isolinux/isolinux.bin \\
            -c isolinux/boot.cat \\
            -input-charset ascii \\
            -no-emul-boot -boot-load-size 4 \\
            -boot-info-table \\
            -V HELLO_WORLD \\
            $out_dir \\
            > $iso_out_dir/hello_world.iso";