; vim: ts=2 sts=2 sw=2 et
;===============================================================================
; 32-bit Kernel Entry Point
;===============================================================================
; This is the entry point for the 32-bit protected mode kernel.
; The bootloader loads this code into memory and transfers control here.
; This code initializes segment registers, sets up the stack, and enables
; full 32-bit memory addressing via the A20 line.
;===============================================================================

[BITS 32]

; GDT Segment Selectors
; These values are offsets into the Global Descriptor Table (GDT)
; CODE_SEG points to the code segment descriptor (kernel code)
; DATA_SEG points to the data segment descriptor (kernel data)
CODE_SEG equ 0x08
DATA_SEG equ 0x10

; Segment selectors are 16-bit values with the following layout:
; [3-15] - bits indexing into the GDT or LDT (13 bits = 8192 descriptors)
; [2]    - table indicator (0 = GDT, 1 = LDT)
; [0-1]  - requested privilege level (RPL): 0 = kernel, 3 = user
;
; Examples:
; 0x08 >> 3 = 1 => index 1 in GDT (code segment)
; 0x10 >> 3 = 2 => index 2 in GDT (data segment)

global _start ; exports the _start symbol for the linker

; section .asm ; we can't define this section for separate linkage because
               ; the kernel needs to be in the text section
                
_start:
  ; Initialize all segment registers to point to the kernel data segment
  ; In protected mode, segment registers hold selectors (not base addresses)
  ; All segments (ds, es, fs, gs, ss) point to the same flat data segment
  mov ax, DATA_SEG
  mov ds, ax  ; data segment
  mov es, ax  ; extra segment
  mov fs, ax  ; general purpose segment
  mov gs, ax  ; general purpose segment
  mov ss, ax  ; stack segment
  ; Set up the stack at 2MB mark in memory (0x00200000)
  ; Stack grows downward from this address
  mov ebp, 0x00200000 ; set base pointer (stack frame base)
  mov esp, ebp        ; set stack pointer (top of stack)
  ; Enable the A20 line via Fast A20 Gate (port 0x92)
  ; The A20 line must be enabled to access memory above 1MB
  ; Without this, address line 20 wraps around (legacy 8086 behavior) =>
  ; broken 32bit addressing because A20 is going to be 0 always
  in al, 0x92         ; read from system control port A
  or al, 2            ; set bit 1 (A20 enable bit)
  out 0x92, al        ; write back to enable A20
  ; TODO: Kernel initialization continues here
  ; - Set up interrupt handlers (IDT)
  ; - Initialize drivers
  ; - Jump to kernel main function
  times 512-($-$$) db 0 ; make this section exactly 512 bytes





























