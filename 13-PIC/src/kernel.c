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
    
    // example of causing a divide by zero exception
    // int x = 10;
    // volatile int divisor = 0;
    // int result = x / divisor; // This will trigger a divide by zero exception (interrupt 0)https://wiki.osdev.org/Interrupt_Descriptor_Table#Gate_Descriptor
    
    // Read LAPIC version
    uint32_t apic_id = (*(uint32_t *)0xFEE00030) & 0x000000FF;

    printk("Local APIC Version is: ");
    char buf[30] = { 0 };
    unsigned int len = 0;

    while (apic_id != 0) {
      char last_digit = (char)((apic_id % 10) & 0x000000FF);
      apic_id /= 10;
      buf[len++] = (char)(last_digit + (char)48);
    }

    if (len == 0) {
      buf[0] = 48;
    } else {
      for (unsigned int i = len - 1; i > len / 2; --i) {
        char tmp = buf[i];
        buf[i] = buf[len - 1 - i];
        buf[len - 1 - i] = tmp;
      }
    }

    printk(buf);
    printk("\n");

    // Halt the CPU - kernel should never exit
    while (1) {
        halt();
    }
}
