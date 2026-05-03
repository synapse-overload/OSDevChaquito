[BITS 32]

global load_idtr
load_idtr:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8] ; Load the pointer to the IDT descriptor into EAX
    lidt [eax] ; dereference the pointer to the right address
    pop ebp
    ret

; The following functions are for experimentation, they are not required but
; interresting for observing behavior

; As per the 32-bit x86 ABI if I don't change ebx, esi, edi, ebp
; then I don't need to manage the frame pointer or save/restore those registers
; we could've done this for load_idtr as well, since esp would just point at 
; the return address
global mask_all_pic_interrupts_except_kbd
mask_all_pic_interrupts_except_kbd:
    mov al, 0xFD        ; mask all interrupts except keyboard
    out 0x21, al        ; write to PIC1 data port
    out 0xA1, al        ; write to PIC2 data port
    ret

global enable_interrupts
enable_interrupts:
    sti ; set interrupt flag to enable interrupts
    ret

extern printk

section .rodata
    isr_message db "Interrupt occurred", 10, 0
    kbd_message db "Keyboard interrupt received", 10, 0
    uart_message db "UART byte received: ", 0

global isr_generic
isr_generic:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    
    ; The rel hint tells the assembler to encode the reference 
    ; as a relocatable/relative symbol reference
    lea eax, [rel isr_message]
    push eax
    call printk
    add esp, 4
    
    pop edi
    pop esi
    pop ebx
    pop ebp
    iret


global kbd_interrupt_handler
kbd_interrupt_handler:
    cli
    pushad
    in al, 0x60          ; drain PS/2 output buffer, re-arms IRQ1
    lea eax, [rel kbd_message]
    push eax
    call printk
    add esp, 4
    mov al, 0x20
    out 0x20, al
    popad
    iret

global uart_interrupt_handler
uart_interrupt_handler:
    cli
    pushad
    mov dx, 0x3F8
    in al, dx;          ; drain UART receive register, de-asserts IRQ4
    movzx eax, al       ; zero-extend the byte to print it as a number
    mov ebx, 10
    shl ebx, 8
    xor eax, ebx
    push eax            ; save the received byte for printing
    lea eax, [rel uart_message]
    push eax
    call printk
    pop eax ; clean up the message argument, could've just been an add esp
    mov eax, esp        ; get the byte argument (still on stack)
    push eax
    call printk
    add esp, 0x08       ; clean up string addr, string byte [2], [1] and [0]
    mov al, 0x20
    out 0x20, al        ; EOI to Master PIC
    popad
    iret

