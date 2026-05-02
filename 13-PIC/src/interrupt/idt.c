#include "idt.h"
#include "io.h"
#include "config.h"
#include "serial_comm.h"
#include "pic.h"

struct idt_entry_t idt_descriptors[TOTAL_INTERRUPTS];
struct idt_ptr_t idt_ptr;

void idt_set_gate(uint8_t num, uint32_t base, uint16_t selector, type_attr_t type_attr) {
    idt_descriptors[num].offset_low = base & 0xFFFF; // Lower 16 bits of handler address
    idt_descriptors[num].selector = selector;         // Code segment selector
    idt_descriptors[num].zero = 0;                    // Unused, set to 0
    idt_descriptors[num].type_attr = type_attr;      // Type and attributes
    idt_descriptors[num].offset_high = (base >> 16) & 0xFFFF; // Higher 16 bits of handler address
}

void divide_by_zero_handler(void) {
    // Handle divide by zero exception (interrupt 0)
    // For demonstration, we can just hang the system or print a message
    printk("Divide by zero exception occurred!\n");

    // it's important to halt the CPU here to prevent further execution after the exception
    // this prevents the function from actually needing to be a proper interrupt handler 
    // with an IRET instruction, which would require more complex assembly code
    while (1) {
        halt(); // Halt the CPU to prevent further execution
    }
}

void isr_generic(void);

void idt_setup(void) {
    // Clear the IDT entries
    memset(idt_descriptors, 0, sizeof(idt_descriptors));
    
    // Load the IDT using lidt instruction
    idt_ptr.limit = sizeof(idt_descriptors) - 1;
    idt_ptr.base = (uint32_t)&idt_descriptors;

    idt_set_gate(
        0,
        (uint32_t)divide_by_zero_handler,
        KERNEL_CODE_SEGMENT_SELECTOR, 
        (type_attr_t){
            .bits = {
                .gate_type = GATE_TYPE_INTERRUPT, 
                .zero_bit = 0,
                .dpl = 3,
                .present = 1
            }
        }
    );
    
    idt_set_gate(KEYBOARD_INTERRUPT_VECTOR, (uint32_t)kbd_interrupt_handler,
        KERNEL_CODE_SEGMENT_SELECTOR,
        (type_attr_t){
            .bits = {
                .gate_type = GATE_TYPE_INTERRUPT,
                .zero_bit = 0,
                .dpl = 3,
                .present = 1
            }
        }
    );

    idt_set_gate(UART0_INTERRUPT_VECTOR, (uint32_t)uart_interrupt_handler,
        KERNEL_CODE_SEGMENT_SELECTOR,
        (type_attr_t){
            .bits = {
                .gate_type = GATE_TYPE_INTERRUPT,
                .zero_bit = 0,
                .dpl = 3,
                .present = 1
            }
        }
    );

    
    load_idtr(&idt_ptr);
    remap_master_pic();
    outb(SERIAL_INT_ENABLE, 0x01);   // enable UART RX-ready interrupt → IRQ4
    enable_interrupts();
}