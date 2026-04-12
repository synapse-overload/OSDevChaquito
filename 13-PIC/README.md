# Lab 13 - Programmable Interrupt Controller

For this lab, a read-through of section 13 of the Intel Developer Manual Volume 3A is recommended.

A short description of the relevant concepts of the implementation in this lab will be provided below.

As of Skylake x2APIC mode of passing interrupts which uses writes to MSRs to raise inter-processor interrupts is the preferred way.
Older versions of raising interrupts would be through APIC and xAPIC mode which used 8-bit processor numbers which may have been sufficient
at some point in the past but now large machines can have more than 256 processors, x2APIC solves this problem by increasing the number of
bits used for CPU identification when raising an IPI to 32-bits.
The above modes are specific ways of managing interrupts, they may be considered protocols.

The architecture on multi-processor systems we will be looking at is:
1. Each logical processor will have its own local apic (LAPIC).
2. The LAPICs communicate interrupts to any other processors or to a I/O APIC (which is also no longer used effectively due to MSI/MSI-x interrupt raising from hardware communicating to the PCIe Root Complex) via a System BUS. Architectures where an internal APIC bus was used will not be the focus of
this lab and should be ignored anyway as they are relevant only for historic purposes at this time.

