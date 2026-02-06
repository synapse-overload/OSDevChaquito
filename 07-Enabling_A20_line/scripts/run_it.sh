#!/bin/bash

# -s listens to tcp:1234 and -S stops until gdb is connected
qemu-system-i386 -hda build/boot.bin -nographic -s -S
