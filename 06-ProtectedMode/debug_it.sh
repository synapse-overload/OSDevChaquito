#!/bin/bash

# Start gdb and connect to already existing qemu instance

gdb -ex "target remote localhost:1234" \
	  -ex "set architecture i386:x86_64" \
		-ex "layout asm" \
		-ex "layout regs"
