#!/bin/bash

# Start gdb and connect to already existing qemu instance

gdb 	-ex "set architecture i386:x86-64" \
	-ex "target remote localhost:1234" \
	-ex "add-symbol-file build/kernelfull.o 0x100000" \
	-ex "break _start" \
	-ex "layout asm" \
	-ex "layout regs" \

