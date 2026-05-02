[BITS 32]

; void cpuid_query(
;  uint32_t leaf,
;  uint32_t *eax,
;  uint32_t *ebx,
;  uint32_t *ecx,
;  uint32_t *edx
; );
global cpuid_query
cpuid_query:
  push ebp
  mov ebp, esp
  push ebx ; EBX, ESI, EDI, EBP are callee-saved — defined function must restore them before ret
  push edi;
  ; push ecx - no need
  ; push edx - no need
  ; put request for manufacturer string in eax
  mov eax, [ebp + 8]
  cpuid
  mov edi, [ebp + 12]
  mov [edi], eax
  mov eax, [ebp + 16]
  mov [eax], ebx
  mov eax, [ebp + 20]
  mov [eax], ecx
  mov eax, [ebp + 24]
  mov [eax], edx
  ; pop edx - no need
  ; pop ecx - no need
  pop edi
  pop ebx
  pop ebp
  ret