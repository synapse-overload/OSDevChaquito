# Cheatsheet for things that you should remember from this course

## Registers you need to restore when returning from a function

This is a System-V ABI specific thing (applies to the i686/i386 calling convention used throughout this project).

**Callee-saved (your function must preserve these):**

| Register  | Notes                                                            |
|-----------|------------------------------------------------------------------|
| `EBX`     | General purpose — save/restore if you use it                     |
| `ESI`     | Source index — save/restore if you use it                        |
| `EDI`     | Destination index — save/restore if you use it                   |
| `EBP`     | Base pointer / frame pointer — save/restore if you use it        |
| `ESP`     | Stack pointer — implicitly preserved by matching push/pop pairs  |

**Caller-saved / scratch (freely clobbered, caller's problem):**

| Register  | Notes                                                     |
|-----------|-----------------------------------------------------------|
| `EAX`     | Also holds the return value                               |
| `ECX`     | Scratch                                                   |
| `EDX`     | Scratch; also upper half of 64-bit return value (EAX:EDX) |

You only need to push/pop callee-saved registers that your function *actually
uses*. If your function never touches `ESI`, skip the push/pop entirely.

Real example from [13-PIC/src/shared/cpuid.asm](13-PIC/src/shared/cpuid.asm).

---

## C-to-ASM stack-prep preamble

The standard **function prologue** establishes a stable stack frame so you can
access arguments at fixed offsets regardless of subsequent pushes inside your
function body.

```nasm
my_function:
  push ebp          ; save caller's frame pointer
  mov  ebp, esp     ; set our frame pointer = current stack top

  ; arguments are now always at fixed offsets from EBP:
  ;   [ebp + 0]  = old EBP (just saved)
  ;   [ebp + 4]  = return address (pushed by CALL)
  ;   [ebp + 8]  = 1st argument
  ...
  pop ebp           ; restore caller's frame pointer
  ret
```

**You don't need this all the time.** Skip the prologue when:
- Your function doesn't use any callee-saved registers, AND
- You only need to access arguments at `[esp+4]`, `[esp+8]`, etc. and you don't
  push anything else after entry.

See [12-IDT/src/idt/idt.asm](12-IDT/src/idt/idt.asm) for a comparison.

> Without `push ebp / mov ebp, esp`, every `push` inside the body shifts `esp`,
so hard-coded `[esp+N]` offsets become wrong. With `ebp` as the frame pointer
the offsets stay fixed.

---

## Don't forget to dereference pointers in functions that take them as out params

When an argument is a **pointer to an output location**, you must dereference it
to write through it. Forgetting this writes into the pointer value itself 
(corrupting a register or random memory) instead of the caller's variable.

Pattern in C:
```c
// Correct — writes through the pointer to the caller's variable
void read_something(uint32_t *out) {
    *out = some_value;
}
```

Pattern in NASM (from [13-PIC/src/shared/cpuid.asm](13-PIC/src/shared/cpuid.asm)):
```nasm
; [ebp+12] = uint32_t *eax_out  (a pointer, not the value)
mov edi, [ebp + 12]   ; load the POINTER into EDI
mov [edi], eax        ; DEREFERENCE: write EAX into the address EDI points to
```

---

## NASM BITS directive

The `[BITS 32]` directive tells NASM to emit 32-bit instruction encodings.
Whether it is strictly required depends on the output format. With `-f bin`
(used for `boot.asm`), NASM defaults to 16-bit mode -- `[BITS 32]` is
**essential** there, placed after the jump into protected mode so that
subsequent instructions are encoded correctly. Without it, 32-bit register
operations would be emitted with a `0x66` operand-size prefix, which in
protected mode has the opposite effect and corrupts execution. With `-f elf`
(used for `idt.asm`, `pic.asm`, and other standalone files), NASM already
defaults to 32-bit mode, so the directive is technically redundant -- but
worth keeping as explicit documentation of the intended execution mode.
The authoritative reference is the
[NASM manual, section 8.1](https://www.nasm.us/doc/nasm08.html#section-8.1).

---

## Bibliography

### Intel Software Developer's Manual (SDM)

The Intel SDM is the authoritative reference for x86 instruction encoding, 
registers, memory models, interrupts, GDT/IDT, paging, and everything else at 
the hardware level.

- **Landing page (always links to the latest):**
  https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html


For this course, **Vol. 3A** (protected mode, GDT, IDT, interrupts, A20) and 
**Vol. 2** (instruction reference for `LIDT`, `LGDT`, `CPUID`, `IN`/`OUT`, 
`HLT`) are the most relevant.

---

### System V ABI Documents

The System V ABI defines the calling convention, ELF file format, object 
linking, and OS-level interfaces. Since this project targets **i686-elf** 
(32-bit), read these two:

- [System V ABI — Generic (gABI)](https://refspecs.linuxfoundation.org/elf/gabi41.pdf)
  -- ELF format, dynamic linking, program loading (Linux Foundation mirror of the original spec)
- [System V ABI — i386 Supplement (psABI)](https://gitlab.com/x86-psABIs/i386-ABI)
  -- i386-specific calling convention, register assignment, stack layout, object format

> The **psABI** is the one that defines callee-saved vs. caller-saved registers,
cdecl argument order, and how the stack frame looks — directly applicable to 
every function in this project.

For 64-bit, the equivalent supplement is the [x86-64 psABI](https://gitlab.com/x86-psABIs/x86-64-ABI)
