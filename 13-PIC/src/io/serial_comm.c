// vim: ts=2 sts=2 sw=2 et
#include "serial_comm.h"
#include "io.h"

// Initialize the serial port (COM1 at 38400 baud, 8N1)
void serial_init(void) {
    // Disable interrupts
    outb(SERIAL_INT_ENABLE, 0x00);

    // Enable DLAB (set baud rate divisor)
    outb(SERIAL_LINE_CTRL, 0x80);

    // Set divisor to 3 (38400 baud)
    outb(SERIAL_BAUD_RATE_LOW, 0x03);
    outb(SERIAL_BAUD_RATE_HIGH, 0x00);

    // 8 bits, no parity, one stop bit (disable DLAB)
    outb(SERIAL_LINE_CTRL, 0x03);

    // Enable FIFO, clear them, with 1-byte threshold
    outb(SERIAL_INT_ID_FIFO_CTRL, 0x07);

    // RTS (Request To Send): when asserted, the UART tells the far end 
    //   “I’m ready to receive data” (it is requesting permission to receive).
    // DTR (Data Terminal Ready): when asserted, the UART tells the far end “I’m
    //   powered on/ready” (it’s a general “terminal is present” signal).
    outb(SERIAL_MODEM_CTRL, 0x03);
}

// Check if transmit buffer is empty
static int serial_is_transmit_empty(void) {
    // Bit 5 of Line Status Register indicates transmit buffer empty
    return inb(SERIAL_LINE_STATUS) & 0x20;
}

// Write a byte to the serial port
void serial_write_byte(char c) {
    // Wait until transmit buffer is empty
    while (serial_is_transmit_empty() == 0);

    // Write the byte to data port
    outb(SERIAL_DATA_PORT, c);
}

// Write a string to the serial port
void printk(const char* str) {
    while (*str) {
        serial_write_byte(*str);
        str++;
    }
}
