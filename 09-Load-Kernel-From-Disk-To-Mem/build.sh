#!/bin/bash
# Shamelessly stolen from wiki.osdev.org/GCC_Cross-Compiler
#
export PREFIX="$HOME/opt/cross"
export TARGET=i686-elf
export PATH="$PREFIX/bin:$PATH"

make
