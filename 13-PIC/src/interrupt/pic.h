#ifndef __PIC_H_
#define __PIC_H_

// PIC Ports
#define MASTER_PIC_COMMAND_PORT 0x20
#define MASTER_PIC_DATA_PORT 0x21
#define SLAVE_PIC_COMMAND_PORT 0xA0
#define SLAVE_PIC_DATA_PORT 0xA1

// PIC Command Words
#define PIC_ICW1_INIT 0x11 // Initialize, expect ICW4
#define PIC_ICW4_8086_MODE 0x01 // 8086/88 mode

// Default IRQ offsets
#define PIC_MASTER_DEFAULT_OFFSET 0x20 // Interrupts 32-39
#define PIC_SLAVE_DEFAULT_OFFSET 0x28 // Interrupts 40-47
// Slave PIC is connected to Master PIC's IRQ2
#define PIC_ICW3_MASTER_SLAVE_ON_IRQ2 0x04

#define KEYBOARD_INTERRUPT_VECTOR 0x21
#define UART0_INTERRUPT_VECTOR 0x24

void remap_master_pic(void);

#endif