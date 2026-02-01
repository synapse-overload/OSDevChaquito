; vim: ts=2 sw=2 sts=2 et
ORG   0x7c00 ; no longer ORIGIN at 0
BITS 16

; the following directives will give us the offsets for the gdts
; they do not occupy memory 
CODE_SEG equ gdt_code - gdt_start ; define the code seg addr macro
DATA_SEG equ gdt_data - gdt_start ; define the data seg addr macro

_start:
  jmp short start
  nop

; BIOS PARAMETER BLOCK
times 33 db 0 ; define 33 0-bytes. i.e. the BPB

start:
  jmp 0:step2
  nop

step2:
  cli ; clear interrupts
  mov ax, 0x00
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov sp, 0x7c00
  sti

.load_protected: ; relative label, anchored to step2
  cli
  lgdt [gdt_descriptor] ; loaded descriptor table
  mov eax, cr0
  or eax, 0x1
  mov cr0, eax ; we just or'ed in cr0
  jmp CODE_SEG:load32 ; FAR jump to another code segment

; GDT: table of segment descriptors describing each segment's properties
gdt_start:
gdt_null: ; always needs to be the first descriptor in the GDT
  dd 0x0
  dd 0x0

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

gdt_data: ; this should be linked to DS, SS, ES, FS, GS
  dw 0xffff 
  dw 0
  db 0
  db 0x92 ; the only change
  db 11001111b
  db 0

gdt_end:

gdt_descriptor:
  dw gdt_end - gdt_start - 1 ; <- this is the size of the descriptor table
  dd gdt_start ; <- this is the offset of the descriptor table

[BITS 32] ; from here on code is 32bit

load32:
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

  jmp $ ; infinite jump

times 510 - ($ - $$) db 0 
dw 0xAA55

