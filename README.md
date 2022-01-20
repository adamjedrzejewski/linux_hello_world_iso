# Linux Hello World

## Purpose
This repository showcases how to create a minimal bootable linux iso  that after booting displays `hello world` on standard output.

## Requirements
  - bash
  - gcc
  - [zig](https://ziglang.org/) compiler
  - mkisofs
  - a bunch of nix utilities that probably are already installed on your system
     - find
     - gzip
     - strip
     - cpio
     - make
     - coreutils (mkdir, cp)
     - wget

## How it works?
### kernel
  Since this is an example running minimal linux iso we will need linux.
  You may find minimal config in `default.config` file.
  #### kernel options:
      - TODO
### init
  Init is the first process that is forked after succesfully bootstrapping the kernel. Our init is solely devoted to printing a string to standard output. \
  \
  **Note**: *I choose Zig because it links the executable statically by default. You may choose any language you want, remeber that if the executable is being liked dynamically you need to bundle these libraries with executable when creating an iso.*, ***which is extremely challenging for newcomers***.
### initrd
TODO
### building iso
TODO
