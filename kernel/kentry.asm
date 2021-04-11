%include "common.asm"

global _start

extern KMain
extern gGdtInfo
extern clearScreen

[section .text]
[bits 32]
_start:
    mov ebp, 0 
    call InitGdt
    call clearScreen
    call KMain
    
    jmp $

; store GDT entry in shared memory to gGdtInfo in kernel
; kernel can visit all of GDT through GDT entry
InitGdt:
    push ebp
    mov ebp, esp
    
    mov eax, dword [GdtEntry]
    mov [gGdtInfo], eax
    mov eax, dword [GdtSize]
    mov [gGdtInfo + 4], eax
    
    leave  ;
    
    ret
