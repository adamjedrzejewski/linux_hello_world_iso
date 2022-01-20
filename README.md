# Linux Hello World

## Purpose
This repository contains a script that creates minimal bootable linux iso that after booting displays `hello world` on standard output.

## Requirements
  - bash
  - [zig](https://ziglang.org/) compiler
  - mkisofs
  - a bunch of nix utilities that probably are already installed on your system
     - find
     - strip
     - cpio
     - make
     - coreutils (mkdir, cp)
     - wget

## How it works?
### kernel
  Since this is an example running minimal linux iso we will need linux.
  Minimal config is is stored in file `default.config`.
### init
  Init is the first process that is forked after succesfully bootstrapping the kernel. Our init is solely devoted to printing a string to standard output. To prevent shutdown the process will sleep indefinitely. \
  \
  Note: *I choose Zig because it links the executable statically by default. You may choose any language you want, remeber that if the executable is being liked dynamically you need to bundle these libraries with executable when creating an iso*
### initrd
TODO
### building iso
TODO
