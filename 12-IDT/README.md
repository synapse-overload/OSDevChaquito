# Lab 12 - Interrupt Descriptor Table

This lab implements the interrupt descriptor table for 32 bit operating
systems.
The maximum number of descriptors in this table is 256.

## Loading the interrupt descriptor register

In order for the interrupt descriptor table that has been filled in memory to 
be used we need to load the address of this table into the IDTR register.

## Verifying that the new interrupt is called

In order to check that the newly set up interrupt handler in the IDT is used
we need to trigger it via a divide by zero operation to see its text message
displayed via the serial interface.

## Interrupt descriptor structure

The interrupt descriptor's structure can be found [here](https://wiki.osdev.org/Interrupt_Descriptor_Table#Gate_Descriptor)
It's important to note that the type of gate (which is also the name for the interrupt descriptor entry) is actually
mixed with the definition of segment types in the Intel developer manual under section 3.5.

## Interresting observations

While in the interrupt you'll notice that the interrupt flag is not set. In my case I would see
`EFLAGS: [ IOPL=0 PF ]` and that's it (value 0x06). This is because when the kernel starts executing an
interrupt gate it will flip it automatically.
An option to study variance in this behavior would be to change the gate type to TRAP. However this
is still not a solution because the interrupts are cleared anyway at this stage in the kernel dev lab.
If we do an `sti` what will happen would be that all interrupts would start firing and general protection
fault (#GP), double faults (#DF), etc. don't yet have handlers. What is more, the programmable interrupt controllers
would start sending interrupts to the CPU, these can be mapped to other interrupt vectors than their defaults.
More specifically the programmable interrupt controller will send timer interrupts at vector 8 which would overlap
with our divide-by-zero exception (#DE).
To overcome this the labs provides two helper functions in idt.asm that mask all PIC interrupts (both for PIC1 and 2)
such that they don't fire at all, but we can set the interrupt flag and observe the difference between a TRAP GATE and
an INTERRUPT GATE. Studying the EFLAGS value is interesting and with TRAPs IF is not cleared when debugging the interrupt service routine.


Also note that the intrerrupt handler function doesn't return via iret, normally interrupt handlers should have an asm wrapper that
performs iret at the end.


The interrupt #DE fault has a particularly interesting feature, like any FAULT apparently it doesn't increment the EIP past the instruciton
that caused the fault, thus returning from the handler will cause it to be called immediately again. Other interrupt types like TRAPs will return
to the next instruction after the one that called the interrupt. Try out the isr_generic handler instead of the default one.

## Changes to the build process

Starting with this lab we've migrated to building the project with CMake.
This system allows manipulating the build toolchain in a uniform way such that 
users may benefit from automatic build system generation. You're no longer
bound to GNU Makefiles or Ninja builds. The toolchain file uses the manually built
gcc tolchain and binutils from lab 8.

## Further reading

[IDT on OSDev Wiki](https://wiki.osdev.org/Interrupt_Descriptor_Table)
[Intel Dev Manual Vol 3A Section 2.4.3 and section 7.10](https://cdrdv2.intel.com/v1/dl/getContent/671190)