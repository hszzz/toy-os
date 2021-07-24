%include "common.asm"

global _start

extern KMain
extern gGdtInfo
extern gIdtInfo
extern clearScreen

extern RunProcess
extern InitInterrupt
extern EnableTimer

[section .text]
[bits 32]
_start:
    mov ebp, 0 

    call InitGlobal
    call clearScreen
    call KMain
    
    jmp $

; store GDT entry in shared memory to gGdtInfo in kernel
; kernel can visit all of GDT through GDT entry
InitGlobal:
    push ebp
    mov ebp, esp
    
    mov eax, dword [GdtEntry]
    mov [gGdtInfo], eax
    mov eax, dword [GdtSize]
    mov [gGdtInfo + 4], eax

    mov eax, dword [IdtEntry]
    mov [gIdtInfo], eax
    mov eax, dword [IdtSize]
    mov [gIdtInfo + 4], eax

    mov eax, dword [RunProcessEntry]
    mov dword [RunProcess], eax

    mov eax, dword [InitInterruptEntry]
    mov dword [InitInterrupt], eax

    mov eax, dword [EnableTimerEntry]
    mov dword [EnableTimer], eax

    leave  
    
    ret
