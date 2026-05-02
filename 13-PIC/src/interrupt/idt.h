#ifndef __IDT_H_
#define __IDT_H_

#include <stdint.h>
#include "memory.h"

// GATE TYPES
#define GATE_TYPE_INTERRUPT 0xE // 32-bit Interrupt Gate
#define GATE_TYPE_TRAP 0xF      // 32-bit Trap Gate
#define GATE_TYPE_TASK 0x5      // Task Gate
#define GATE_TYPE_CALL 0xC      // 32-bit Call Gate

// INTERRUPT INDEXES
#define DIVIDE_BY_ZERO_EXCEPTION 0 // Interrupt 0: Divide by zero exception

typedef union
{
    struct
    {
        uint8_t gate_type : 4; // Bits 0-3
        uint8_t zero_bit : 1;  // Bit 4
        uint8_t dpl : 2;       // Bits 5-6
        uint8_t present : 1;   // Bit 7
    } __attribute__((packed)) bits;

    uint8_t all; // Access the whole 8-bit chunk
} type_attr_t;

struct idt_entry_t
{
    uint16_t offset_low;          // Lower 16 bits of handler function address
    uint16_t selector;            // Code segment selector in GDT
    uint8_t zero;                 // Unused, set to 0
    type_attr_t type_attr; // Type and attributes
    uint16_t offset_high;         // Higher 16 bits of handler function address
} __attribute__((packed));

struct idt_ptr_t
{
    uint16_t limit; // Size of the IDT
    uint32_t base;  // Base address of the IDT
} __attribute__((packed));

void idt_setup(void);
// this funciton is defined in idt.asm
void load_idtr(struct idt_ptr_t* idt_ptr);

void mask_all_pic_interrupts_except_kbd(void);
void enable_interrupts(void);
void kbd_interrupt_handler(void);
void uart_interrupt_handler(void);

#endif