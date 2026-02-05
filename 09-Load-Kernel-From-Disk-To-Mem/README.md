# Lab 9: Loading Kernel from Disk to Memory

## Overview

This lab demonstrates how to create a two-stage boot process by separating the bootloader from the kernel. The bootloader (Stage 1) transitions to 32-bit protected mode and loads the kernel (Stage 2) from disk into memory at the 1MB mark (0x0100000), then transfers control to it.

**Key Innovation:** This bootloader performs disk I/O in **32-bit protected mode** using direct ATA port I/O, rather than the traditional approach of using BIOS interrupts (INT 13h) in real mode.

## What Happens in This Lab

### 1. **Bootloader Execution** (boot.asm)
   - BIOS loads the 512-byte bootloader at 0x7c00
   - Sets up segment registers and stack in real mode
   - Defines and loads the Global Descriptor Table (GDT)
   - Transitions from 16-bit real mode to 32-bit protected mode
   - Uses ATA PIO mode to read 100 sectors from disk
   - Loads kernel binary at 0x0100000 (1MB)
   - Jumps to kernel entry point

### 2. **Kernel Execution** (kernel.asm)
   - Initializes segment registers with kernel data segment
   - Sets up stack at 2MB (0x00200000)
   - Enables A20 line for full 32-bit memory addressing
   - Ready for kernel initialization (IDT, drivers, etc.)

## Memory Layout

```
0x00000000 - 0x000003FF : Interrupt Vector Table (IVT)
0x00000400 - 0x000004FF : BIOS Data Area (BDA)
0x00000500 - 0x00007BFF : Free conventional memory
0x00007C00 - 0x00007DFF : Bootloader (512 bytes)
0x00007E00 - 0x0009FFFF : Free conventional memory
0x000A0000 - 0x000FFFFF : Video memory, ROM, BIOS reserved
0x00100000 - 0x???????? : Extended memory (kernel loaded here at 1MB)
```

**Why load at 1MB?**
- Above the 1MB barrier (no real mode conflicts)
- In extended memory (requires A20 line enabled)
- Avoids BIOS reserved areas (0xA0000-0xFFFFF)
- Standard location for kernel loading

## ATA PIO Mode - Direct Disk Access

The bootloader uses **ATA PIO (Programmed I/O)** mode to read from the disk without BIOS assistance. This requires direct communication with the disk controller through I/O ports.

### ATA Primary Bus I/O Ports (0x1F0-0x1F7)

| Port  | Function | Read/Write | Description |
|-------|----------|------------|-------------|
| 0x1F0 | Data Register | R/W | Transfer 512-byte sectors (256 16-bit words) |
| 0x1F1 | Error/Features | R/W | Read: error info; Write: feature control |
| 0x1F2 | Sector Count | R/W | Number of sectors to read (0 = 256) |
| 0x1F3 | LBA Low | R/W | LBA bits 0-7 |
| 0x1F4 | LBA Mid | R/W | LBA bits 8-15 |
| 0x1F5 | LBA High | R/W | LBA bits 16-23 |
| 0x1F6 | Drive/Head | R/W | LBA bits 24-27 + drive select + mode flags |
| 0x1F7 | Command/Status | W/R | Write: send command; Read: drive status |

### LBA (Logical Block Addressing)

LBA is a simple linear addressing scheme where each sector has a sequential number:
- **LBA 0**: First sector (bootloader)
- **LBA 1**: Second sector (first sector of kernel)
- **LBA 2-100**: Continuation of kernel data

The 28-bit LBA is split across multiple ports:
```
Bits 0-7   → Port 0x1F3
Bits 8-15  → Port 0x1F4
Bits 16-23 → Port 0x1F5
Bits 24-27 → Port 0x1F6 (lower 4 bits)
```

### Status Register (0x1F7) Bits

When reading from port 0x1F7, you get the drive status:

| Bit | Name | Description |
|-----|------|-------------|
| 7 | BSY | Busy - drive is busy |
| 6 | DRDY | Drive Ready |
| 5 | DF | Drive Fault |
| 4 | DSC | Drive Seek Complete |
| 3 | **DRQ** | **Data Request Ready** (must poll this before reading) |
| 2 | CORR | Corrected data (always 0) |
| 1 | IDX | Index (always 0) |
| 0 | ERR | Error - check error register for details |

### Disk Read Algorithm

1. **Configure drive** (port 0x1F6): Set LBA mode, select master drive, send LBA bits 24-27
2. **Set sector count** (port 0x1F2): Specify how many sectors to read
3. **Send LBA address** (ports 0x1F3-0x1F5): Send remaining 24 bits of LBA
4. **Issue READ command** (port 0x1F7): Send command 0x20 (READ SECTORS)
5. **Poll for DRQ** (port 0x1F7): Wait until bit 3 is set (drive ready)
6. **Read data** (port 0x1F0): Use `REP INSW` to read 256 words (512 bytes)
7. **Repeat** for each sector

## Protected Mode vs Real Mode Disk Access

| Aspect | Real Mode (Traditional) | Protected Mode (This Lab) |
|--------|------------------------|---------------------------|
| Method | BIOS INT 13h | Direct ATA port I/O |
| Pros | Simple, BIOS handles hardware | Full control, no BIOS dependency |
| Cons | Limited to real mode | Must handle hardware directly |
| Typical Use | Most bootloaders | Advanced/educational |

## Key Concepts Learned

1. **Two-stage booting**: Separating bootloader from kernel
2. **Protected mode transition**: Enabling 32-bit addressing
3. **GDT setup**: Defining memory segments for protected mode
4. **ATA PIO mode**: Direct hardware communication without BIOS
5. **LBA addressing**: Linear sector addressing on disk
6. **Port I/O**: Using IN/OUT instructions for hardware control
7. **Memory layout**: Understanding PC memory map
8. **A20 line**: Hardware requirement for >1MB addressing

## Build and Run

```bash
# Build the bootloader and kernel
make

# Run in QEMU
make run

# Or manually:
qemu-system-x86_64 -drive format=raw,file=./bin/boot.bin
```

## Important Notes

- ⚠️ **No error handling**: This implementation doesn't check for disk errors (ERR, DF bits)
- ⚠️ **Assumes ATA support**: Won't work with pure AHCI systems without compatibility mode
- ⚠️ **Fixed sector count**: Reads exactly 100 sectors (50KB)
- ✅ **Educational focus**: Demonstrates low-level disk I/O principles

## Further Reading

- [OSDev Wiki - ATA PIO Mode](https://wiki.osdev.org/ATA_PIO_Mode)
- [OSDev Wiki - Memory Map](https://wiki.osdev.org/Memory_Map_(x86))
- [Intel x86 Manual - Protected Mode](https://www.intel.com/content/www/us/en/architecture-and-technology/64-ia-32-architectures-software-developer-vol-3a-part-1-manual.html)