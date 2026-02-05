; vim: ts=2 sts=2 sw=2 et
;===============================================================================
; Stage 1 Bootloader - 512 Bytes
;===============================================================================
; This bootloader performs the following:
; 1. Sets up segment registers and stack in real mode
; 2. Transitions from 16-bit real mode to 32-bit protected mode
; 3. Loads the kernel from disk using ATA PIO mode (in 32-bit mode!)
; 4. Jumps to the loaded kernel at 0x0100000 (1MB)
;
; NOTE: This bootloader performs disk I/O in protected mode, which is unusual.
; Most bootloaders use BIOS interrupts (INT 13h) in real mode instead.
; This approach uses direct ATA port I/O for educational purposes.
;===============================================================================

ORG  0x7c00 ; Origin address - BIOS loads bootloader at 0x7c00 in memory
BITS 16     ; Start in 16-bit real mode

; GDT Segment Selector Offsets
; These are byte offsets into the Global Descriptor Table defined below
; They do not occupy memory - they are compile-time constants
CODE_SEG equ gdt_code - gdt_start ; Offset to code segment descriptor (0x08)
DATA_SEG equ gdt_data - gdt_start ; Offset to data segment descriptor (0x10)

_start:
	; Jump over the BIOS Parameter Block (BPB) area
	; The 'short' keyword ensures a 2-byte jump instruction
	; Some BIOSes expect this jump pattern for FAT filesystem compatibility
	jmp short start
	nop ; NOP for alignment (3 bytes total: EB XX 90)

; BIOS Parameter Block (BPB)
; Many BIOSes expect a FAT12/FAT16 BPB structure starting at offset 3
; We fill it with zeros since we're not using a FAT filesystem
; This prevents BIOS from misinterpreting our code as filesystem metadata
times 33 db 0 ; Reserve 33 bytes for BPB (bytes 3-35)

start:
	; Perform a far jump to normalize CS:IP registers
	; Sets CS=0x0000, IP=step2, ensuring consistent segment:offset addressing
	; Without this, CS could be 0x07C0 with IP=0, or CS=0 with IP=0x7C00
	jmp 0:step2
	nop

step2:
	cli ; Disable interrupts while setting up segment registers

	; Initialize all segment registers to 0
	; In real mode, segments are used to calculate physical addresses:
	; Physical Address = (Segment * 16) + Offset
	mov ax, 0x00
	mov ds, ax  ; Data segment
	mov es, ax  ; Extra segment
	mov ss, ax  ; Stack segment

	; Set up stack at 0x7c00 (grows downward toward 0x0000)
	; This places the stack just below the bootloader code
	; Stack range: 0x0000 to 0x7c00 (approximately 31KB)
	mov sp, 0x7c00

	sti ; Re-enable interrupts (safe now that segments/stack are set up)

; Transition from Real Mode to Protected Mode
.load_protected: ; Local label anchored to step2
	cli ; Disable interrupts during mode switch (critical!)

	; Load the Global Descriptor Table (GDT)
	; This defines the memory segments we'll use in protected mode
	lgdt [gdt_descriptor]

	; Enable protected mode by setting bit 0 (PE bit) in CR0 register
	; CR0 is a control register that manages CPU operating modes
	mov eax, cr0
	or eax, 0x1      ; Set PE (Protection Enable) bit
	mov cr0, eax     ; CPU is now in protected mode!

	; Perform a FAR jump to load CS with the new code segment selector
	; This flushes the CPU instruction pipeline and completes the mode switch
	; After this jump, we're executing 32-bit code in protected mode
	jmp CODE_SEG:load32

; Global Descriptor Table (GDT)
; The GDT is a table of segment descriptors used in protected mode
; Each descriptor is 8 bytes and defines a memory segment's properties
gdt_start:

; Null Descriptor (required by x86 architecture)
; The first GDT entry must always be null (all zeros)
; This catches errors: using a null selector will cause a CPU exception
gdt_null:
	dd 0x0  ; Lower 4 bytes
	dd 0x0  ; Upper 4 bytes

; 31                          16|15                          0
; +-----------------------------+----------------------------+
; |  Segment Base 0:15          |    SEG LIMIT 0:15          |
; +-------------+---------------+-------------+--------------+
; | Base 24:31  | Flags | Limit | Access Byte | Base 16:23   |
; |             | 0:4   | 16:19 |						  |							 |
; +-------------+-------+-------+-------------+--------------+
; 63          56|55   52|51   48|47         40|39           32

; offset 0x8
gdt_code:   ; CS (code segment) should point here
  ; remember what we define here grows up, so 0-15 bits come first, i.e.
	; the SEG LIMIT
	dw 0xffff ; Segment LIMIT first 0-15 bits
	; what follows is 2 bytes for the segment base which we set to 0
	dw 0			; Base first 0-15 bits (remember byte=1, word=2bytes, double=4b)
	; then we have a single byte on the second row in the drawing above, i.e.
	; bits 16-23 of the continuation of BASE, so far we have defined:
	; 0x ??00 0000
	db 0			; Base 16-23 bits

	; ACEESS BYTE is a mask composed of the following parts:
	; [7]   present bit - this must be 1 for all valid selectors (some can be dis)
	; [6:5] Priv1       - privilege, 2 bits (i.e. ring 0, 1 .. 3)
	; [4]   S           - descriptor type (1 for code seg, 0 all else)
	; [3]   Ex					- executable bit (if 1 => code, if 0 not exec)
	; [2]   DC				  - direction bit/conforming bit
	;									  - 0 = seg grows up
	;                   - 1 = seg grows down
	;									- if it's a conforming bit:
	;								    - 1 - can be exec'ed from lower priv level
	;										- 0 - can be exec'ed only from code at priv in Privl bits
	; [1] RW          - readable/writeable bit (read access for code seg, etc)
	;										 - for code seg 0=read not allowed, write is nnever allow
	;										 - for data seg bit means write access, 0=false
	; [0] Ac				  - accessed bit - set to 0, the CPU will set to 1 if access
	; FLAGS
	;   - Gr          - granularity bit, 0=1B gran, 1=4KiB gran
	;   - Sz				  - size bit, selector defines 16 bit protected mode if 0,
	;									  32bit protected seg
	; 0x9a - means 10011010 => Pr,Ring0,Code,Exec,Up,Write?,Ac=0
	db 0x9a		; Access byte
	; LIMIT and FLAGS, setting limit 4 bits to 1 all
	db 11001111b ; Gr=1=>4KiB gran, sz=1=>32bit protected seg
	
	; the last 8bit part BASE
	db 0

; Data Segment Descriptor (offset 0x10)
; Used for DS, SS, ES, FS, GS registers
; Almost identical to code segment, but with different access rights
gdt_data:
	dw 0xffff        ; Segment limit 0-15 bits
	dw 0             ; Base 0-15 bits
	db 0             ; Base 16-23 bits
	db 0x92          ; Access byte: 10010010b
	                 ; [7]   Present = 1
	                 ; [6:5] Privilege = 00 (ring 0)
	                 ; [4]   Descriptor type = 1 (code/data segment)
	                 ; [3]   Executable = 0 (data segment, not code)
	                 ; [2]   Direction = 0 (grows up)
	                 ; [1]   Read/Write = 1 (writable)
	                 ; [0]   Accessed = 0 (CPU sets this when accessed)
	db 11001111b     ; Flags + Limit 16-19 bits
	db 0             ; Base 24-31 bits

gdt_end:

gdt_descriptor:
	; GDT Descriptor structure used by LGDT instruction
	dw gdt_end - gdt_start - 1 ; Size: Length of GDT in bytes minus 1
	dd gdt_start               ; Offset: 32-bit linear address of GDT

;===============================================================================
; 32-bit Protected Mode Code
;===============================================================================
[BITS 32]
load32:
	; Load kernel from disk into memory using ATA PIO mode
	;
	; Memory Layout:
	; 0x00000000 - 0x000003FF : Interrupt Vector Table (IVT)
	; 0x00000400 - 0x000004FF : BIOS Data Area (BDA)
	; 0x00000500 - 0x00007BFF : Free conventional memory
	; 0x00007C00 - 0x00007DFF : Bootloader (this code)
	; 0x00007E00 - 0x0009FFFF : Free conventional memory
	; 0x000A0000 - 0x000FFFFF : Video memory, ROM, BIOS reserved
	; 0x00100000 - 0x???????? : Extended memory (kernel loaded here)
	;
	; We load at 1MB (0x0100000) because:
	; - It's above the 1MB barrier (no real mode address conflicts)
	; - It's in extended memory (requires A20 line enabled)
	; - It avoids BIOS reserved areas (0xA0000-0xFFFFF)

	mov eax, 1           ; LBA sector 1 (sector 0 is bootloader)
	mov ecx, 100         ; Read 100 sectors (51,200 bytes = ~50KB)
	mov edi, 0x0100000   ; Destination: 1MB mark in memory
	call ata_lba_read    ; Read from disk using ATA PIO

	; Transfer control to the loaded kernel
	jmp CODE_SEG:0x0100000

	; ATA PIO Mode Documentation: https://wiki.osdev.org/ATA_PIO_Mode
	; Note: No error handling implemented - production code should check
	; status register for ERR, DF (Device Fault), and BSY bits 

; ATA LBA Read Function
; Reads sectors from disk using ATA PIO mode with LBA addressing
;
; Parameters:
;   EAX = LBA (Logical Block Address) - starting sector number
;   ECX = Number of sectors to read
;   EDI = Destination memory address (ES:EDI used by INSW)
;
; ATA Primary Bus I/O Ports:
;   0x1F0 - Data port (16-bit read/write)
;   0x1F1 - Error/Features register
;   0x1F2 - Sector count
;   0x1F3 - LBA low byte (bits 0-7)
;   0x1F4 - LBA mid byte (bits 8-15)
;   0x1F5 - LBA high byte (bits 16-23)
;   0x1F6 - Drive/Head register (bits 24-27 of LBA + drive select)
;   0x1F7 - Command/Status register
;
ata_lba_read:
	mov ebx, eax ; Backup LBA value (we'll need it multiple times)

	; Configure Drive/Head register (port 0x1F6)
	; Format: [7:5]=111 [6]=LBA mode [5]=1 [4]=Drive(0=master) [3:0]=LBA[27:24]
	shr eax, 24              ; Shift to get bits 24-27 of LBA
	or eax, 0xE0             ; 0xE0 = 11100000b (LBA mode, master drive)
	mov dx, 0x1F6            ; Drive/Head register port
	out dx, al               ; Send highest 4 bits of LBA + drive select

	; Send sector count (port 0x1F2)
	mov eax, ecx             ; ECX contains the number of sectors
	mov dx, 0x1F2            ; Sector count register
	out dx, al               ; Send low 8 bits (max 256 sectors)

	; Send LBA bits 0-7 (port 0x1F3)
	mov eax, ebx             ; Restore original LBA
	mov dx, 0x1F3            ; LBA low register
	out dx, al               ; Send bits 0-7

	; Send LBA bits 8-15 (port 0x1F4)
	mov eax, ebx             ; Restore LBA
	shr eax, 8               ; Shift to get bits 8-15
	mov dx, 0x1F4            ; LBA mid register
	out dx, al               ; Send bits 8-15

	; Send LBA bits 16-23 (port 0x1F5)
	mov eax, ebx             ; Restore LBA
	shr eax, 16              ; Shift to get bits 16-23
	mov dx, 0x1F5            ; LBA high register
	out dx, al               ; Send bits 16-23

	; Issue READ SECTORS command (port 0x1F7)
	mov dx, 0x1F7            ; Command/Status register
	mov al, 0x20             ; Command 0x20 = READ SECTORS
	out dx, al               ; Execute read command

.next_sector:
	push ecx ; Save sector counter (will be used by inner loop)

; Poll status register until drive is ready to transfer data
; Status register (0x1F7) bit meanings:
;   Bit 7 (BSY)  - Busy: Drive is busy
;   Bit 6 (DRDY) - Drive Ready
;   Bit 5 (DF)   - Drive Fault
;   Bit 4 (DSC)  - Drive Seek Complete
;   Bit 3 (DRQ)  - Data Request: Drive is ready to transfer data
;   Bit 2 (CORR) - Corrected data (always 0)
;   Bit 1 (IDX)  - Index (always 0)
;   Bit 0 (ERR)  - Error: Check error register for details
.try_again:
	mov dx, 0x1F7            ; Status register
	in al, dx                ; Read status byte
	test al, 8               ; Test bit 3 (DRQ - Data Request Ready)
	jz .try_again            ; If DRQ=0, drive not ready yet, keep polling

; Read one sector (512 bytes = 256 words) from data port
	mov ecx, 256             ; 256 words to read (word = 2 bytes)
	mov dx, 0x1F0            ; Data port (16-bit)
	rep insw                 ; Read words from port DX into ES:EDI
	                         ; INSW: Input word from port DX to [ES:EDI]
	                         ; REP: Repeat ECX times, incrementing EDI by 2
	                         ; After this, EDI points to next sector location
	                         ; See: https://www.felixcloutier.com/x86/ins:insb:insw:insd

	pop ecx                  ; Restore sector counter
	loop .next_sector        ; Decrement ECX, loop if not zero

	; All sectors read successfully
	ret                      ; Return to caller

; Boot Signature
; Pad to 510 bytes and add magic number
; $ = current position, $$ = section start (0x7c00)
; This ensures the bootloader is exactly 512 bytes
times 510 - ($ - $$) db 0    ; Fill remaining space with zeros
dw 0xAA55                     ; Boot signature (little-endian: 0x55AA)
                              ; BIOS checks for this signature at bytes 510-511
                              ; Without it, BIOS won't recognize this as bootable
