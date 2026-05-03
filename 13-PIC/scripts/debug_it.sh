#!/bin/bash

# Start gdb and connect to already existing qemu instance
set -x
gdb -ex "set architecture i386" \
	-ex "set disassembly-flavor intel" \
	-ex "target remote localhost:1234" \
	-ex "add-symbol-file build/src/kernel.elf" \
	-ex "break kernel_main" \
	-ex "break divide_by_zero_handler" \
	-ex "break idt_setup" \
	-ex "break * (void(*)(void)) &uart_interrupt_handler" \
	-ex "layout asm" \
	-ex "layout regs" \

set +x
