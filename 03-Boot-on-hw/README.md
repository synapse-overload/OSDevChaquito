Booting from actual hardware supposes different means of handling the boot
media. This varies across various media. This also varies across different
types of BIOS, you can't really make an assumption about what the BIOS will do
before your bootloader runs so this is why you can do some handliing.

Some BIOSes will require a bios parameter block. Read more about this here:
[OS dev on booot](https://wiki.osdev.org/FAT)

**Note** that this category of issues is tied mostly to BIOS boot to MBR-based
sys. On UEFI based systems the GPT itself contains the required info for
the UEFI boot, BIOS is effectively replaced (and emulated when necessary) by
UEFI on these systems.
[UEFI vs BIOS](https://www.freecodecamp.org/news/uefi-vs-bios/)

**Note** In the current program I had to remove the labels starting with '.'
because nasm associates a local label with the latest previous non-local label
and if we have the first _start label defined as non-local and then we have
some `times 33 db 0` directive this intertwines data with code and influences
the .done label negtively leading to an error that looks like:
```bash
nasm -f bin boot.asm -o boot.bin
boot.asm:42: error: symbol `start.done' not defined
make: *** [Makefile:2: boot.bin] Error 1
```
