%include "common.asm"

global _start

extern gGdtInfo
extern gIdtInfo

extern KMain
extern ClearScreen

extern RunTask
extern InitInterrupt
extern EnableTimer
extern SendEOI

[section .text]
[bits 32]
_start:
    mov ebp, 0 

    call InitGlobal
    call ClearScreen
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

    mov eax, dword [RunTaskEntry]
    mov dword [RunTask], eax

    mov eax, dword [InitInterruptEntry]
    mov [InitInterrupt], eax

    mov eax, dword [EnableTimerEntry]
    mov [EnableTimer], eax

    mov eax, dword [SendEOIEntry]
    mov [SendEOI], eax

    leave  
    
    ret
