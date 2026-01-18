ORG   0 ; origin set to 0
BITS 16
_start:
	jmp short start
	nop

times 33 db 0 ; define 33 0-bytes. i.e. the BPB

; DISK - READ SECTOR(S) INTO MEMORY
; AH = 02h
; AL = number of sectors to read (must be nonzero)
; CH = low eight bits of cylinder number ----\
; CL = (bits 0-5) - sector number 1-63        \_ 10 bits for cylinder
;      (bits 6-7) - high two bits of cylinder /
; DH = head number
; DL = drive number (bit 7 set for HDD)
; ES:BX -> data buffer
;
; RETURN:
; - CF - set on error/clear on success
; - if AH = 11h (corected ECC error), AL = burst length
; - AH status - see more on Ralph Brown's BIOS interrupts page
; - AL = number of sectors transferred

start:
	jmp 0x7c0:step2
	nop

step2:
	cli ; clear interrupts
	mov ax, 0x07c0
	mov ds, ax
	mov es, ax     ; <--------+
	mov ax, 0x00   ;          |
	mov ss, ax     ;          |
	mov sp, 0x7c00 ;          |
	sti ;                     +___________________________________________
                     ;                                                        \
	mov ah, 0x02 ; READ SECTOR COMMAND                                     \
	mov al, 0x01 ; READ ONE SECTOR                                          \
	mov ch, 0x00 ; Cyld low eight bits                                       \
	mov cl, 0x02 ; Read sector two                                            \
	mov dh, 0x00 ; HEAD NUMBER                                                 |
	mov bx, buffer ; the address where the read will be at: ES:BX, ES is 0x00 -+
	int 0x13 ; the READ SECTOR interrupt
	jc error ; if carry flag is set something went wrong
	mov si, buffer ; print the read text which is now at &buffer
	call print
	jmp $ ; infinite loop

error:
  mov si, error_message
	call print
	jmp $ ; infinite loop

print: ; remember to put the message addr in si if you want to print
	mov ah, 0x03
	mov bh, 0
	int 0x10
loop:
	lodsb		; Load byte at DS:SI into AL, then increment SI
	cmp al, 0
	je done
	mov ah, 0x09 ; Write Character and Attribute (for color ;) )
	mov bl, 0x05 ; magenta
	mov bh, 0x00; page 0
	mov cx, 1; print only once
	int 0x10; print through BIOS interrupt
	inc dl
	mov ah, 0x02 ; move cursor
	mov bh, 0x00 ; page 0
	int 0x10	
	jmp loop
done:
  ret

error_message: db "Failed to load sector", 0x0

times 510 - ($ - $$) db 0 
dw 0xAA55

buffer: ; this memory adddress is not loaded into memory because the BIOS
        ; only loaded 1 sector, the second is not in memory
