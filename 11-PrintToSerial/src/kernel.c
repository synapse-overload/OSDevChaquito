// vim: ts=2 sts=2 sw=2 et
#include "kernel.h"
#include "serial_comm.h"
#include "io.h"

void kernel_main(void) {
    // Initialize serial port
    serial_init();

    // Write message to serial console
    printk("Kernel loaded successfully!\n");
    printk("Hello from 32-bit protected mode!\n");
    printk("Serial output is working.\n");

    // Halt the CPU - kernel should never exit
    while (1) {
        halt();
    }
}