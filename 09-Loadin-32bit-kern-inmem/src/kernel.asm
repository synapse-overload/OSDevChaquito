; vim: ts=2 sts=2 sw=2 et
[BITS 32]
CODE_SEG equ 0x08
DATA_SEG equ 0x10

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



































