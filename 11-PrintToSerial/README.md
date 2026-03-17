# Lab 11 - Print text to serial 

This lab implements serial port output for debugging in headless environments.

It will also add a halt loop in the kernel main program to prevent jumps to
invalid code after the main function finishes.

## Serial output vs Video output for studying

When running in headless environments (SSH, servers, VMs without display), VGA 
memory at `0xB8000` isn't useful so printing to a serial console is better.

### COM1 Port Layout

The serial port uses multiple I/O ports for configuration and data transfer:

| Port Offset | DLAB | Access | Purpose                         |
|-------------|------|--------|---------------------------------|
| +0          | 0    | Read   | Receive buffer                  |
| +0          | 0    | Write  | Transmit buffer                 |
| +1          | 0    | R/W    | Interrupt Enable Register       |
| +0          | 1    | R/W    | Baud rate divisor (LSB)         |
| +1          | 1    | R/W    | Baud rate divisor (MSB)         |
| +2          | -    | Read   | Interrupt Identification        |
| +2          | -    | Write  | FIFO Control                    |
| +3          | -    | R/W    | Line Control (bit 7 = DLAB)     |
| +4          | -    | R/W    | Modem Control                   |
| +5          | -    | Read   | Line Status (bit 5 = TX empty)  |
| +6          | -    | Read   | Modem Status                    |
| +7          | -    | R/W    | Scratch Register                |

**DLAB (Divisor Latch Access Bit)**: When set to 1 in the Line Control Register
(port +3, bit 7), ports +0 and +1 switch from data transfer to baud rate 
configuration. Always clear DLAB after setting baud rate!

### Initialization Sequence

```c
// 1. Disable UART interrupts by writing 0 to the port
outb(SERIAL_INT_ENABLE, 0x00);

// 2. Enable DLAB to set baud rate, the base UART clock is 115200 so it will be
// divided by a certain value, but to do that we need to flip this latch on
// this changes the I/O ports from functioning like data/interrupt control and
// turns these ports to rate divisor registers (RATE LOW/HIGH)
outb(SERIAL_LINE_CTRL, 0x80);

// 3. Set divisor = 3 (38400 baud)
outb(SERIAL_BAUD_RATE_LOW, 0x03);
outb(SERIAL_BAUD_RATE_HIGH, 0x00);

// 4. Disable DLAB (return ports +0/+1 to data/interrupt enable) and set 8N1
//    (8 data bits, no parity, 1 stop bit)
outb(SERIAL_LINE_CTRL, 0x03);

// 5. Enable FIFO with 14-byte threshold - fewer interrupts, only every 14 bytes
outb(SERIAL_INT_ID_FIFO_CTRL, 0xC7);

// 6. Enable IRQs and assert RTS (so the other end knows we can receive).
//    Note: DSR is a status input line (not something we “set”), and on PCs the
//    OUT2 bit is what allows the UART to actually raise IRQ4.
//    we won't be using bit 3 set up for now because we don't handle interrupts
//    yet
outb(SERIAL_MODEM_CTRL, 0x03);
```


### Writing Data

**Always poll before writing!** The transmit buffer must be empty:

```c
void serial_write_byte(char c) {
    // Wait until bit 5 of Line Status Register is set
    while ((inb(SERIAL_LINE_STATUS) & 0x20) == 0);

    // Now safe to write
    outb(SERIAL_DATA_PORT, c);
}
```

Skipping the poll can cause data loss—the UART has a small buffer and will 
drop bytes if you write too fast.

To exit QEMU with `-nographic`: Press `Ctrl+A`, then `X`

## Memory Layout

```
0x00000000 - 0x000003FF : Interrupt Vector Table (IVT)
0x00000400 - 0x000004FF : BIOS Data Area (BDA)
0x00007C00 - 0x00007DFF : Bootloader (512 bytes)
0x00100000 - ????????  : Kernel code (.text)
0x00200000             : Kernel stack (2MB)

I/O Ports:
0x3F8 - 0x3FF          : COM1 (serial port)
```

## Build and Run

```bash
# Build kernel
./build.sh

# Run in QEMU (serial output to terminal)
./scripts/run_it.sh

# Exit QEMU: Ctrl+A, then X
```

## Further Reading

- [OSDev Wiki - Serial Ports](https://wiki.osdev.org/Serial_Ports)
- [OSDev Wiki - Inline Assembly](https://wiki.osdev.org/Inline_Assembly)
- [PC16550D UART Datasheet](http://www.ti.com/lit/ds/symlink/pc16550d.pdf)
- [Intel® 64 and IA-32 Architectures Software Developer Manuals](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
