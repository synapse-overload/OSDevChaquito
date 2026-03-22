// vim: ts=2 sts=2 sw=2 et
#include "kernel.h"
#include "serial_comm.h"
#include "io.h"
#include "idt.h"

void kernel_main(void) {
    // Initialize serial port
    serial_init();

    // Write message to serial console
    printk("Kernel loaded successfully!\n");
    printk("Hello from 32-bit protected mode!\n");
    printk("Serial output is working.\n");
    idt_setup();
    int x = 10;
    volatile int divisor = 0;
    int result = x / divisor; // This will trigger a divide by zero exception (interrupt 0)https://wiki.osdev.org/Interrupt_Descriptor_Table#Gate_Descriptor

    // Halt the CPU - kernel should never exit
    while (1) {
        halt();
    }
}