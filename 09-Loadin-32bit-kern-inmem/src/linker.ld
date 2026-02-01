/* vim: ts=2 sts=2 sw=2 et */

/* A linker script is required to specify how big and where each section of the
* ELF file will be 
* The binary that we're linking, however will, at this point, actually 
* represent a disk which is loaded by our qemu emulator and it's rather used
* to represent the contents of that contiguous memory which contains both
* the bootloader and the operating system
*/

ENTRY(_start) /* in x86 32bit assembly this is the real name of the symbol
		 but from C this would be viewed as start, on x86_64 symbols
		 keep their own names, but on 32bit there's this quirk, sheesh!
		 */
OUTPUT_FORMAT(binary) /* this is a binary format even though we define the 
			 kernel as ELF */
SECTIONS
{
	. = 1M; /* 1048576  - this will be the address where the kernel will 
		         be loaded */
	/*
	* Why 1MB? This is a standard kernel loading address - the first 1MB 
	* of memory contains BIOS data, real-mode code, and other legacy 
	* structures that you want to avoid
	*
	* NOTE: The location counter is automatically increased after .
	*
	*/
	.text :
	{
		*(.text) /*  The asterisk * means "from all input files", and 
		  	      *   (.text) means "take their .text sections"
		          */
	}

	.rodata :
	{
		*(.rodata)
	}

	.data :
	{
		*(.data)
	}

	.bss : /* block started by symbol */
	{
		*(COMMON) /* variables declared without static in C, passing -fno-common is something we CAN do */
		*(.bss) /* Standard uninitialized variables */
	}
}
