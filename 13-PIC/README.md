# Lab 13 - Programmable Interrupt Controller

# A word about the real-world relationship between this lab and the current-day computer arhcitectures

Everything you are doing in this lab — and in most of the labs in this series — 
targets an environment that has not represented production hardware for well
over a decade. QEMU, by default, emulates a classic PC compatible machine based
on the Intel 440FX or Q35 chipset, which faithfully reproduces the legacy ISA
interrupt model that dates back to the original IBM PC. This is an excellent
teaching vehicle precisely because it is simple, well-documented, and
deterministic, but it is important to be clear-eyed about the gap between what 
you are writing here and what runs on a machine you can buy today.

The 8259A PIC is gone from real hardware. Intel officially deprecated it as part
of removing the legacy Compatibility Support Module (CSM) — the firmware shim 
that allowed UEFI systems to pretend they were old BIOS machines — from the 
chipset. Starting with Intel's 700-series chipsets (Alder Lake platform, 2021) 
the CSM was dropped entirely and with it went the emulated 8259A. On such 
systems, if you were to boot bare-metal code that only programs the 8259A and
never touches the APIC, your interrupt handling simply would not work. The 
hardware has no 8259A to talk to.

The CSM itself is worth understanding. For years, UEFI firmware shipped with a
Compatibility Support Module that emulated legacy BIOS services: INT 10h for
video, INT 13h for disk, and the 8259A-style IRQ model. This allowed bootloaders
and operating systems written for the BIOS era to run unmodified on UEFI
machines. The removal of the CSM is the industry's final break with the PC/AT
interrupt model. Modern operating systems — Linux, Windows — have long since
moved to using the APIC natively and do not rely on the CSM at all.

What real hardware actually uses today. On any x86-64 machine built in the last
several years, interrupt delivery works as follows: each CPU core contains a
Local APIC (LAPIC) integrated directly into the processor die.
Peripheral devices — NVMe drives, NICs, GPUs — do not assert physical IRQ lines
at all; instead they use Message Signaled Interrupts (MSI or MSI-X), which are
writes to a specific memory address that cause the PCIe Root Complex to deliver
an interrupt directly to a LAPIC without involving any discrete interrupt
controller chip. The I/O APIC, which was itself a successor to the 8259A, exists
on the chipset but is largely bypassed for MSI-capable devices. In multi-socket
or many-core configurations, x2APIC mode is used, extending processor addressing
to 32 bits to support more than 256 logical CPUs.

The 8259A model establishes every concept you will need to reason about the 
APIC: IRQ lines, vector remapping, masking, end-of-interrupt signaling,
master/slave chaining. The primitives are identical; the wiring is different.
Writing a working 8259A driver in QEMU gives you a concrete, debuggable artifact
before you have to deal with ACPI tables, MSI capability structures, and
per-core LAPIC register maps. Think of this lab as the "Hello, World" of
interrupt controllers — not because the 8259A is relevant to production systems,
but because it isolates the essential idea cleanly enough to understand it.


## 8259 PIC
The implementation in `pic.c/asm` focuses on the
**Legacy 8259 Programmable Interrupt Controller**. This chip handles the
hardware IRQs (0-15) by mapping them to CPU interrupt vectors. 

Key concepts for this lab:
- **ICW (Initialization Command Words):** A sequence of 4 bytes used to  
  initialize the master and slave PICs.
- **OCW (Operation Command Words):** Used to send End-Of-Interrupt (EOI) 
  signals or mask specific IRQs.
- **Vector Offsets:** Why we map IRQ0 to 0x20 instead of 0x08 (to avoid conflict
  with CPU exceptions).

**Recommended Reading for 8259:**
- [OSDev Wiki - 8259 PIC](https://wiki.osdev.org/8259_PIC)
- 8259A Datasheet

In the previous lab there was dirrect interaction with this PIC when interrupts
were purposefully disabled for all its ports in function
`mask_all_pic_interrupts` where both PIC1 and 2 received two masks on their
data ports (0x21, 0xA1) which directly write to their respective Interrupt Mask
Register (IMR).

# Initialization

To initialize the PIC you need to send it commands to its command port and data
to its data port. Easy, right? In reality the initialization sequence is very
fixed: ICW1 is a command sent to the cmd port which requires ICW2->4 to be sent
to the data port in this sequence. After receiving ICW4 the PIC is live, the
tricky part is knowing when it's done initializing.


# Interrupts handled in this lab

The table of interrupts handled by the pic on this architecture is:

| IRQ | Description                                                            |
|-----|------------------------------------------------------------------------|
| 0   | Timer Interrupt                                                        |
| 1   | Keyboard Interrupt                                                     |
| 2   | Cascade Interrupt                                                      |
| 3   | COM2 Interrupt                                                         |
| 4   | COM1 Interrupt                                                         |
| 5   | LPT                                                                    |
| ... | etc...                                                                 |

For this lab we will be handling the keyboard interrupt and the COM1 serial
interrupt. The timer interrupt may be used for scheduler invocation, but on
modern hardware that is invoked via the CPU's LAPIC-implemented timer or through
the HPET.

**A note on triggering IRQ1 under QEMU.** When running with `-nographic`, QEMU
multiplexes standard input onto the emulated serial port (COM1), not the PS/2
keyboard controller. Characters typed in the terminal reach the UART and raise
IRQ4; the 8042 keyboard controller receives nothing and IRQ1 does not fire from
normal input. To inject a PS/2 scancode manually from the same terminal session,
switch to the QEMU monitor with **Ctrl+A C**, issue `sendkey <key>` (e.g.
`sendkey a`), then switch back with **Ctrl+A C**. The monitor command deposits
the scancode directly into the emulated 8042, which asserts IRQ1 exactly as real
hardware would. This is not a workaround — it is the correct mechanism for
exercising the PS/2 path from a headless QEMU session.


## Interrupt 4 from PIC - COM1 / UART

Because `-nographic` routes terminal input to the emulated 16550 UART on COM1
(base I/O port `0x3F8`), IRQ4 is the interrupt that fires when you type in the
terminal. This makes it the practical input path for any kernel running in a
headless QEMU session.

The UART does not raise IRQ4 automatically; two steps are required beyond the
standard PIC configuration:

1. **Enable the UART receive interrupt.** The 16550 has an Interrupt Enable
   Register (IER) at `COM1 + 1` (`0x3F9`). Writing `0x01` to this register
   enables the "Received Data Available" interrupt. During `serial_init()` the
   IER is intentionally set to `0x00` to suppress spurious interrupts while baud
   rate and framing are being configured. It must be re-enabled after the IDT and
   PIC are fully initialised.

2. **Unmask IRQ4 in the master PIC.** IRQ4 is bit 4 of the master PIC's
   Interrupt Mask Register. Clear that bit in the OCW1 byte written to port
   `0x21`.

**Why the handler must read `0x3F8` before sending EOI.** The 8259A operates in
edge-triggered mode: it latches IRQ4 on the rising edge and will not re-fire on
a line that remains continuously asserted. The UART holds IRQ4 high until its
receive register is read. If the handler sends EOI without first reading from
`0x3F8`, the UART keeps the line asserted, the PIC sees no new rising edge, and
no further interrupts are delivered regardless of how many bytes arrive. Reading
the received byte from `0x3F8` as the first action in the handler clears the
UART's interrupt condition and restores normal operation.

### Transmission parameters

When you configure minicom or picocom to talk to a Raspberry Pi over a CP2102
adapter, you set a string like `115200 8N1`. Those four values fully describe a
UART link and both ends must agree on all of them or the received data will be
garbage.

- **Baud rate.** The number of signal transitions per second, which for UART
  equals bits per second. Common values are 9600, 115200, and 38400. There is no
  negotiation — both sides must be configured to the same rate before the
  connection is established. The 16550 derives this from its internal 1.8432 MHz
  clock divided by a 16-bit divisor, which is why that clock frequency was chosen:
  it divides evenly into all standard baud rates.

- **Data bits.** How many bits constitute one character frame. Almost universally
  8 in modern use, which maps directly to one byte. Older teleprinter equipment
  used 5 or 7.

- **Parity.** An optional single bit appended to each frame for basic error
  detection. `N` (None) disables it entirely. `E` (Even) sets the bit so the
  total number of 1s in the frame is even; `O` (Odd) does the inverse. Parity
  catches single-bit errors but not burst errors, and most modern protocols that
  need reliability handle error detection at a higher layer, so `N` is the
  standard choice.

- **Stop bits.** One or two idle bits appended after the data (and parity, if
  present) to give the receiver time to process the frame before the next start
  bit arrives. `1` is standard; `2` was useful for slow mechanical receivers and
  is rarely needed today.

The shorthand `8N1` therefore means: 8 data bits, no parity, 1 stop bit. A
complete frame on the wire is: 1 start bit + 8 data bits + 1 stop bit = 10 bit
periods per byte transmitted.

### Initialization sequence

The 16550 initialization in `serial_comm.c` follows a fixed sequence that the
hardware requires. The steps are:

1. **Disable interrupts (IER — Interrupt Enable Register — `= 0x00`).** Written
   to `0x3F9`. Prevents the UART from raising IRQ4 partway through configuration,
   before a handler is in place.

2. **Set the baud rate divisor.** The 16550 derives its baud rate by dividing an
   internal 1.8432 MHz clock by a 16-bit divisor. To write this divisor, the
   Divisor Latch Access Bit (DLAB) in the LCR (Line Control Register) must first
   be set (`LCR = 0x80`, written to `0x3FB`). With DLAB set, ports `0x3F8` and
   `0x3F9` are remapped to the low and high bytes of the divisor rather than the
   data and IER registers. A divisor of 3 yields 38400 baud (1843200 / (16 × 3)).

3. **Configure line framing and clear DLAB (`LCR = 0x03`).** Written to `0x3FB`.
   Sets 8 data bits, no parity, 1 stop bit (8N1), and clears DLAB to restore
   normal port mapping.

4. **Enable and reset the FIFO (`FCR = 0x07`).** Written to `0x3FA`. Enables the
   16-byte receive and transmit FIFOs, clears both, and sets the interrupt trigger
   threshold to 1 byte. With a 1-byte threshold the UART raises IRQ4 as soon as a
   single byte arrives; a higher threshold (the 16550 supports 1, 4, 8, and 14)
   would buffer incoming bytes and only interrupt once that many had accumulated.

5. **Assert RTS (Request To Send) and DTR (Data Terminal Ready) (`MCR = 0x03`).**
   Written to `0x3FC`. RTS signals to the remote end "I am ready to receive data";
   DTR signals "this terminal is powered and present". Both are holdovers from
   RS-232 hardware handshaking. QEMU does not require these lines to be asserted,
   but omitting them can cause issues on real hardware or with strict emulators.

**Recommended reading for the 16550 UART:**
- [OSDev Wiki - Serial Ports](https://wiki.osdev.org/Serial_Ports) — covers the
  register map, DLAB, baud divisors, and interrupt enable bits; the register
  table on this page maps every offset from `COM1+0` through `COM1+7` for both
  normal mode and DLAB mode
- National Semiconductor PC16550D datasheet (the canonical hardware reference —
  hosted by TI who acquired National Semiconductor; find the current link from
  the OSDev page above)

## Modern Alternatives (APIC / x2APIC)
Note that modern systems use the APIC (Advanced Programmable Interrupt
Controller) architecture.

The LAPIC integrated on each core is **not** the PIC that we're interacting with 
in this specific lab. However, understanding it is vital for multi-core support.

For future context on modern interrupt handling, see Chapter 13 of the Intel SDM
Vol 3A:
The name of the sections are:
- CHAPTER 13 ADVANCED PROGRAMMABLE INTERRUPT CONTROLLER (APIC)
- 13.4.8 Local APIC Version Register - used for reading the version of the
  current CPU's APIC version 
- 13.4.6 Local APIC ID - local APIC Id
- Volume 2A - Chapter 21 - PROCESSOR IDENTIFICATION AND FEATURE DETERMINATION


---


# Other artifacts seen in this lab

## CPUID
The CPUID instruction is useful for finding out information about the current
system.

## Linker ordering
This lab establishes a clear linker ordering so that the `_start` symbol comes
first in the binary output after the 1MB mark. In order to find out that the
`_start` symbol was in the wrong place:
```bash
❯ nm build/src/kernelfull.o | grep -E "_start|kernel_main|cpuid_query|serial_init"
00000750 T cpuid_query
00000180 T kernel_main
000004a0 T serial_init
000002a0 T _start  
```
`_start` should be at `CODE_SEG:0x0100000` as per `boot.asm:194`
now the new linker script that places the start.first section first will place
the `_start` symbol right at that first section that starts after 1MB.
```bash
# pre-linker
❯ nm build/src/kernelfull.o | grep -E "_start|kernel_main|cpuid_query|serial_init"
00000550 T cpuid_query
00000180 T kernel_main
000002a0 T serial_init
00000000 R _start 
```
doing an objdump on the binary after the 1MB offset gets:
```bash
 objdump -D -b binary -m i386 --adjust-vma=0x100000 <path-to-your-build>/kernel.elf | head -35

<path-to-your-build>/kernel.elf:     file format binary


Disassembly of section .data:

00100000 <.data>:
  100000:       66 b8 10 00             mov    $0x10,%ax
  100004:       8e d8                   mov    %eax,%ds
  100006:       8e c0                   mov    %eax,%es
  100008:       8e e0                   mov    %eax,%fs
```
which is the same code as the start section (loading DATA SEG into ax):
```bash
objdump -d -j start.first <path-to-your-build>/kernelfull.o

<path-to-your-build>/kernelfull.o:     file format elf32-i386


Disassembly of section start.first:

00000000 <_start>:
   0:   66 b8 10 00             mov    $0x10,%ax
   4:   8e d8                   mov    %eax,%ds
   6:   8e c0                   mov    %eax,%es
```

## Linker script changed output to ELF32-i386

To properly be able to debug the post-link offsets of kernel functions need to
be known. The previous method generated binary output thus stripping symbol
locations from the output file, making it a binary blob. That was fine for
debugging because loading the kernelfull.o into gdb could trigger relocation
computations at debug time allowing us to stop at functions.
However at some points we may need to break on the address of a certain
instruction or just after a function call. For this to be supported we require
a binary ELF with all the symbols and their locations in memory post-link.

However in order for the kernel to be functional we do still need the binary to
not have ELF-specific headers and sections at the beginning of the file, so we
now use objcopy to remove this part and indeed at the end still have a raw
binary concatenated to the bootloader to provide a raw disk image file.

## New parameter passed to compiler

`-mpreferred-stack-boundary=2` is now passed to the compiler so that stack
alignment is no longer required for our binary. This would cause extra
instructions to be generated to align the stack to 16 bytes, which is overkill.
Since it's a 32-bit operating system 4 bytes are enough, the value of the param
is meant as a power of 2.