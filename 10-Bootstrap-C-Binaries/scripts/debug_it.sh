#!/bin/bash

# Start gdb and connect to already existing qemu instance
set -x
gdb -ex "set architecture i386" \
	-ex "target remote localhost:1234" \
	-ex "add-symbol-file build/kernelfull.o 0x100000" \
	-ex "add-symbol-file build/kernel.o" \
	-ex "break kernel_main" \
	-ex "layout asm" \
	-ex "layout regs" \

set +x