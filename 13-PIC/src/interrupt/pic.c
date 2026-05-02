#include "pic.h"
#include "io.h"
#include <stdint.h>

void remap_master_pic(void) {
  // ICW1: Start initialization sequence (0x11 for 8259A, implies ICW4 is
  // needed)
  outb(MASTER_PIC_COMMAND_PORT, PIC_ICW1_INIT);

  // ICW2: Set Master PIC's vector offset
  // This remaps IRQ0-7 to interrupt vectors 0x20-0x27 (32-39)
  outb(MASTER_PIC_DATA_PORT, PIC_MASTER_DEFAULT_OFFSET);

  // ICW3: Tell Master PIC about Slave PIC presence and connection
  // 0x04 means slave is connected on IRQ2 of master
  outb(MASTER_PIC_DATA_PORT, PIC_ICW3_MASTER_SLAVE_ON_IRQ2);

  // ICW4: Set 8086 mode
  outb(MASTER_PIC_DATA_PORT, PIC_ICW4_8086_MODE);

  // Mask all interrupts on the Master PIC for now.
  // Interrupts should only be unmasked once their handlers are properly set
  // up in the IDT.
  // This prevents spurious interrupts before the kernel is ready.
  outb(MASTER_PIC_DATA_PORT,
       0xFF ^ ((1 << (KEYBOARD_INTERRUPT_VECTOR - PIC_MASTER_DEFAULT_OFFSET)) |
               (1 << (UART0_INTERRUPT_VECTOR - PIC_MASTER_DEFAULT_OFFSET))));
}