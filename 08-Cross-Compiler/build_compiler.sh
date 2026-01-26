#!/bin/bash
# Shamelessly stolen from wiki.osdev.org/GCC_Cross-Compiler
#
export PREFIX="$HOME/opt/cross"
export TARGET=i686-elf
export PATH="$PREFIX/bin:$PATH"

which -- $TARGET-as || echo $TARGET-as is not in the path

mkdir build-gcc
cd build-gcc
../gcc-10.2.0/configure --target=$TARGET --prefix="$PREFIX" --disable-nls \
  --enable-languages=c,c++ --without-headers

make all-gcc
make all-target-libgcc
make install-gcc
make install-target-libgcc
