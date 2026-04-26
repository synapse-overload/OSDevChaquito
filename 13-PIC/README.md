# Lab 13 - Programmable Interrupt Controller

For this lab, a read-through of Chapter 13 of the Intel Developer Manual Volume
3A is recommended. Since the Intel Developer Manual continuously evolved, this
reference is for the February 2026 version.
The name of the sections are:
- CHAPTER 13 ADVANCED PROGRAMMABLE INTERRUPT CONTROLLER (APIC)
- 13.4.8 Local APIC Version Register - used for reading the version of the
  current CPU's APIC version 
- 13.4.6 Local APIC ID - local APIC Id
- Volume 2A - Chapter 21 - PROCESSOR IDENTIFICATION AND FEATURE DETERMINATION
  

A short description of the relevant concepts of the implementation in this lab
will be provided below.

As of Nehalem x2APIC mode of passing interrupts which uses writes to MSRs to
raise inter-processor interrupts is the preferred way.
Older versions of raising interrupts would be through APIC and xAPIC mode which
used 8-bit processor numbers which may have been sufficient
at some point in the past but now large machines can have more than 256
processors, x2APIC solves this problem by increasing the number of bits used for
CPU identification when raising an IPI to 32-bits.
The above modes are specific ways of managing interrupts, they may be considered
protocols.

The architecture on multi-processor systems we will be looking at is:
1. Each logical processor will have its own local apic (LAPIC).
2. The LAPICs communicate interrupts to any other processors or to a I/O APIC 
(which is also no longer used effectively due to MSI/MSI-x interrupt raising 
from hardware communicating to the PCIe Root Complex) via a **system bus**. 
Architectures where an internal APIC bus was used will not be the focus of this
lab and should be ignored anyway as they are relevant only for historic purposes
at this time.

## CPUID
The CPUID instruction is useful for finding out information about the current
system.

## Linker ordering
This lab establishes a clear linker ordering so that the `_start` symbol comes
first in the binary output after the 1MB mark. In order to find out that the
`_start` symbol was in the wrong place:
```bash
❯ nm build/src/kernelfull.o | grep -E "_start|kernel_main|cpuid_query|serial_init"
00000750 T cpuid_query
00000180 T kernel_main
000004a0 T serial_init
000002a0 T _start  
```
`_start` should be at `CODE_SEG:0x0100000` as per `boot.asm:194`
now the new linker script that places the start.first section first will place
the `_start` symbol right at that first section that starts after 1MB.
```bash
# pre-linker
❯ nm build/src/kernelfull.o | grep -E "_start|kernel_main|cpuid_query|serial_init"
00000550 T cpuid_query
00000180 T kernel_main
000002a0 T serial_init
00000000 R _start 
```
doing an objdump on the binary after the 1MB offset gets:
```bash
 objdump -D -b binary -m i386 --adjust-vma=0x100000 /home/synapse/Workspace/Kernel-Development/13-PIC/build/src/kernel.bin | head -35

/home/synapse/Workspace/Kernel-Development/13-PIC/build/src/kernel.bin:     file format binary


Disassembly of section .data:

00100000 <.data>:
  100000:       66 b8 10 00             mov    $0x10,%ax
  100004:       8e d8                   mov    %eax,%ds
  100006:       8e c0                   mov    %eax,%es
  100008:       8e e0                   mov    %eax,%fs
```
which is the same code as the start section (loading DATA SEG into ax):
```bash
objdump -d -j start.first /home/synapse/Workspace/Kernel-Development/13-PIC/build/src/kernelfull.o

/home/synapse/Workspace/Kernel-Development/13-PIC/build/src/kernelfull.o:     file format elf32-i386


Disassembly of section start.first:

00000000 <_start>:
   0:   66 b8 10 00             mov    $0x10,%ax
   4:   8e d8                   mov    %eax,%ds
   6:   8e c0                   mov    %eax,%es
```