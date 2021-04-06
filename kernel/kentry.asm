
global _start

extern KMain

[section .text]
[bits 32]
_start:
    mov ebp, 0
    
    call KMain
    
    jmp $
