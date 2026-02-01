This section separates the bootloader from the kernel and READS the kernel into
memory.

The ATA PIO interface uses specific I/O ports to communicate with the hard 
drive. For the primary bus, ports 0x1F0-0x1F7 control disk operations, with
each port serving a distinct function:
- 0x1F0: Data port - used to read/write 512-byte sectors (256 16-bit words)
- 0x1F2: Sector Count register - specifies how many sectors to read (0 means
  256)
- 0x1F3: LBA bits 0-7 (lowest byte of the logical block address)
- 0x1F4: LBA bits 8-15 (second byte)
- 0x1F5: LBA bits 16-23 (third byte)
- 0x1F6: Drive/Head register - selects master/slave and holds LBA bits 24-27
- 0x1F7: Command/Status register - sends commands (write) or reads drive status
  (read)


