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
global mask_all_interrupts_except_0
mask_all_interrupts_except_0:
    mov al, 0xFF        ; mask all interrupts
    out 0x21, al        ; write to PIC1 data port
    out 0xA1, al        ; write to PIC2 data port
    ret

global enable_interrupts
enable_interrupts:
    sti ; set interrupt flag to enable interrupts
    ret

extern printk

section .rodata
    isr_message db "Interrupt occurred\n", 0

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

global make_interrupt_handler
make_interrupt_handler:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]  ; get function pointer argument
    call eax            ; call the interrupt handler function
    pop ebp
    iret                ; return from interrupt

