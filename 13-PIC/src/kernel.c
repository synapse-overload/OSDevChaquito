// vim: ts=2 sts=2 sw=2 et
#include "kernel.h"
#include "serial_comm.h"
#include "io.h"
#include "idt.h"
#include "os_string.h"


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
    
    char buf[30] = { 0 };

    // -- APIC ID --
    uint32_t apic_id = get_local_apic_id();
    printk("Local APIC ID is: ");
    i32_to_s(buf, apic_id);
    printk(buf);
    printk("\n");

    // -- APIC VERSION --
    uint32_t apic_ver = get_local_apic_ver();
    printk("Local APIC Version is: ");
    i32_to_s(buf, apic_ver);
    printk(buf);
    printk("\n");

    // -- CPU IDENTIFICATION --
    uint32_t cpu_family = get_cpu_family();
    uint32_t cpu_model  = get_cpu_model();
    const char *cpu_name = cpu_lookup_name(cpu_family, cpu_model);
    printk("CPU: ");
    if (cpu_name) {
        printk(cpu_name);
    } else {
        printk("Unknown Intel CPU (Family ");
        u32_to_hex_s(buf, cpu_family);
        printk(buf);
        printk(", Model ");
        u32_to_hex_s(buf, cpu_model);
        printk(buf);
        printk(")");
    }
    printk("\n");

    // Halt the CPU - kernel should never exit
    while (1) {
        halt();
    }
}
