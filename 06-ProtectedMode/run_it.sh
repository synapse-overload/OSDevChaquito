#!/bin/bash

# -s listens to tcp:1234 and -S stops until gdb is connected
qemu-system-x86_64 -hda ./boot.bin -nographic -s -S
