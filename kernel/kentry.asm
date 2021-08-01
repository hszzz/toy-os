%include "common.asm"

global _start
global TimerHandlerEntry

extern gTaskAddr
extern gGdtInfo
extern gIdtInfo

extern KMain
extern ClearScreen
extern RunTask
extern InitInterrupt
extern EnableTimer
extern SendEOI
extern TimerHandler

; save the interrupt context
%macro ContextSave 0
    sub esp, 4
    
    pushad

    push ds
    push es
    push fs
    push gs

    mov dx, ss
    mov ds, dx
    mov es, dx

    mov esp, 0x9000
%endmacro

; restore the interrupt context
%macro ContextRestore 0
    mov esp, [gTaskAddr]

    pop gs
    pop fs
    pop es
    pop ds

    popad

    add esp, 4
    iret
%endmacro

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

TimerHandlerEntry:
ContextSave
    call TimerHandler
ContextRestore
