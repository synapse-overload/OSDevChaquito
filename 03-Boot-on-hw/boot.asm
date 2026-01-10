ORG   0 ; origin set to 0
BITS 16
_start:
	jmp short start
	nop

; the BIOS parameter block might as well be empty but it's good to have it
; calculated so that we can jump over it because the BIOS may overwrite that
; area and cause our program to break if it's there, we might as well just fill
; bytes with 0 in the are where this BIOS parameter block is expected

times 33 db 0 ; define 33 0-bytes. i.e. the BPB

start:
	jmp 0x7c0:step2
	nop

step2:
	cli ; clear interrupts
	mov ax, 0x07c0 ; put right shifted address by 4 bits here
		       ; in 16-bit mode the CPU can adress 20bits
		       ; by using 2 registers, the first of which being ds
		       ; in this case the register value is always right-shift
		       ; by 4 bits and is parrt of the DS:SI address which is
		       ; passed to lodsb
	mov ds, ax
	mov es, ax
	mov ax, 0x00
	mov ss, ax ; set the stack SEGMENT to 0
	mov sp, 0x7c00 ; -> set the stack POINTER to the ORG we had before 
	; NOTE: The stack grows downwards below 0x7c00 and the code moves up.
	sti ; enables interrupts
	; !!!!!!!!!!!!! ;
	mov si, message ; because ORG is at 0 this may be at a very low address
			; 
	mov ah, 0x03
	mov bh, 0
	int 0x10
loop:
    lodsb		; Load byte at DS:SI into AL, then increment SI
    cmp al, 0
    je done
    mov ah, 0x09
    mov bl, 0x05
    mov bh, 0x00
    mov cx, 1
    int 0x10
    inc dl
    mov ah, 0x02
    mov bh, 0x00
    int 0x10	
    jmp loop

message: db "Six seveeen", 0

done:
    nop
times 510 - ($ - $$) db 0 
dw 0xAA55

