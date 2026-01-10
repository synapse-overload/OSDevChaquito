ORG 0x7c00 ; This is the start address
BITS 16 ; tell the assembler we'll be using 16 bit REAL mode

.start:	; the start label, right now the start symbol doesn't matter as 
	; we're just in the bootloader
	mov si, message
	mov ah, 0x03 	; get current ucrsor position
	mov bh, 0	; page set to 0 for text mode
	int 0x10	; DH will be filled with current row, DL col
			; CH - cursor start line, CL = cursor end scanline
; When writing whe select the VIDEO function with AH (0x0E is TELETYPE)
; Int 10/AH=09h - VIDEO - WRITE CHARACTER AND ATTRIBUTE AT CURSOR POSITION
;   AL = character to display
;   BH = page number
;   BL = attribute (text mode) or color (graphics mode)
;        if bit 7 set in <256-color graphics mode, character is XOR'ed
;        onto screen
;   CX = number of times to write character
.loop:
    lodsb		; Load byte at DS:SI into AL, then increment SI
    cmp al, 0
    je .done
    mov ah, 0x09	; Write Character and Attribute (for color ;) )
    mov bl, 0x05	; magenta
    mov bh, 0x00	; page 0
    mov cx, 1		; print only once
    int 0x10		; print through BIOS interrupt
					; for BIOS interrupt fun check out Ralph Brown's web page on ctyme.com
    inc dl
    mov ah, 0x02	; move cursor
    mov bh, 0x00	; page 0, not really necessary but best to remember it exists
    int 0x10		; "write" the position move
    jmp .loop

message: db "Six seveeen", 0

.done:  ;  end of the road do nothing
; we need the boot signature 0x55 0xAA
times 510 - ($ - $$) db 0 ; we need to fill 510 bytes of data (remember boot sect = 512b)
			; notice the $ - $$ means how many bytes left from the start
dw 0xAA55 ; little endian

