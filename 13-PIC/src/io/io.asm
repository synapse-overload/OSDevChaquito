; vim: ts=2 sts=2 sw=2 et
; Port I/O Functions callable from C
;
; x86 has a separate I/O address space accessed via IN/OUT instructions.
; These functions let C code talk to hardware devices through I/O ports.
;
; cdecl calling convention quick reference:
;   - Arguments pushed right-to-left on stack
;   - Caller cleans up stack after call
;   - Return values in EAX (or AL for bytes)
;   - First arg at [esp+4], second at [esp+8], etc.
;
; Example: outb(0x3F8, 'A') in C becomes:
;   push 'A'        ; second arg at [esp+8]
;   push 0x3F8      ; first arg at [esp+4]
;   call outb
;   add esp, 8      ; caller cleans stack

[BITS 32]

; note we don't need the name mangling scheme we were using in
; the bootloader, in ELF format we don't need this, so we can
; specify function names directly as outb as opposed to _outb
; if we were in COFF/PE or a.out
global outb
global inb
global halt

; void outb(unsigned short port, unsigned char value)
; Writes a byte to an I/O port
;
; Parameters (cdecl):
;   [esp+4] = port number (16-bit, but stored as 32-bit on stack)
;   [esp+8] = value to write (8-bit, but stored as 32-bit on stack)
outb:
  mov dx, [esp + 4]     ; port number goes in DX
  mov al, [esp + 8]     ; value goes in AL
  out dx, al            ; send it
  ret

; unsigned char inb(unsigned short port)
; Reads a byte from an I/O port
;
; Parameters (cdecl):
;   [esp+4] = port number (16-bit)
; Returns:
;   AL = byte read (returned in EAX per cdecl, but only AL is valid)
inb:
  mov dx, [esp + 4]     ; port number in DX
  in al, dx             ; read byte into AL
  ret                   ; AL is the return value

halt:
  hlt ; simple instruction to stop CPU execution until an interrupt hits
