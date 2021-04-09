%include "common.asm"

global _start

extern KMain
extern clearScreen

[section .text]
[bits 32]
_start:
    mov ebp, 0
    call clearScreen
    call KMain
    
    jmp $


