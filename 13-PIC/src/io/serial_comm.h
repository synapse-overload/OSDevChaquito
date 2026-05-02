#ifndef __SERIAL_COMM_H_
#define __SERIAL_COMM_H_

// Serial port base address
#define SERIAL_COM1_BASE 0x3F8

// Serial port register offsets (add to base address)
// DLAB = 0 (Divisor Latch Access Bit cleared)
#define SERIAL_DATA_PORT          (SERIAL_COM1_BASE + 0)  // Read: Receive, Write: Transmit
#define SERIAL_INT_ENABLE         (SERIAL_COM1_BASE + 1)  // Interrupt Enable Register
#define SERIAL_INT_ID_FIFO_CTRL   (SERIAL_COM1_BASE + 2)  // Read: Int ID, Write: FIFO Ctrl
#define SERIAL_LINE_CTRL          (SERIAL_COM1_BASE + 3)  // Line Control (MSB is DLAB)
#define SERIAL_MODEM_CTRL         (SERIAL_COM1_BASE + 4)  // Modem Control Register
#define SERIAL_LINE_STATUS        (SERIAL_COM1_BASE + 5)  // Line Status Register
#define SERIAL_MODEM_STATUS       (SERIAL_COM1_BASE + 6)  // Modem Status Register
#define SERIAL_SCRATCH            (SERIAL_COM1_BASE + 7)  // Scratch Register

// DLAB = 1 (Divisor Latch Access Bit set)
#define SERIAL_BAUD_RATE_LOW      (SERIAL_COM1_BASE + 0)  // LSB of divisor
#define SERIAL_BAUD_RATE_HIGH     (SERIAL_COM1_BASE + 1)  // MSB of divisor

// Function declarations
void serial_init(void);
void serial_write_byte(char c);
void printk(const char* str);

#endif
