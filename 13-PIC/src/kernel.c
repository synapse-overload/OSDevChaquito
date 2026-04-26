// vim: ts=2 sts=2 sw=2 et
#include "kernel.h"
#include "serial_comm.h"
#include "io.h"
#include "idt.h"
#include "cpuid.h"

void invert_string(unsigned int len, char *buf) {
  if (len <= 1) {
      buf[0] = 48;
    } else {
      for (unsigned int i = len - 1; i >= len / 2; --i) {
        char tmp = buf[i];
        buf[i] = buf[len - 1 - i];
        buf[len - 1 - i] = tmp;
      }
    }
}

uint32_t get_local_apic_id(void) {
  uint32_t eax=0, ebx=0, ecx=0, edx=0;
  cpuid_query(1, &eax, &ebx, &ecx, &edx);
  return (uint32_t)(ebx >> 24);
}

uint32_t get_local_apic_ver(void) {
  // Read LAPIC version
  return (*(uint32_t *)0xFEE00030) & 0x000000FF;
}

uint32_t i32_to_s(char *buf, uint32_t number) {
  uint32_t len = 0;
  buf[0] = '\0';
  while (number != 0) {
    char last_digit = (char)((number % 10) & 0x000000FF);
    number /= 10;
    buf[len++] = (char)(last_digit + (char)48);
  }
  buf[len] = '\0';
  invert_string(len, buf);
  return len;
}

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

    // Halt the CPU - kernel should never exit
    while (1) {
        halt();
    }
}
