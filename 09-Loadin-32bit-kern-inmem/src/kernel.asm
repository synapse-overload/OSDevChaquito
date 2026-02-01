; vim: ts=2 sts=2 sw=2 et
[BITS 32]
; the CODE_SEG and DATA_SEG values are set to
CODE_SEG equ 0x08
DATA_SEG equ 0x10
; the above are called SELECTORS because they refer to offset within the GDT
; a selctor is a 16 bit value with the following layout
; [3-15] - bits indexing into the GDT or LDT
; [2]    - table indicator (0 = GDT, 1 = LDT)
; [0-1]  - privilege level
; 0x08 >> 3 = 1 => index 1 in GDT
; 0x10 >> 3 = 2 => index 2 in GDT

global _start ; exports the _start symbol

_start:
	mov ax, DATA_SEG
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov ebp, 0x00200000 ; set the stack pointer further in mem
	mov esp, ebp

	; Enable the A20 line
	in al, 0x92
	or al, 2
	out 0x92, al



































