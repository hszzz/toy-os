%include "common.asm"

global _start
global InitAppModule

extern AppMain
extern GetAppInfo
extern GetAppNum

[section .text]
[bits 32]
_start:
InitAppModule:
    push ebp
    mov  ebp, esp

    mov dword [GetAppInfoEntry], GetAppInfo
    mov dword [GetAppNumEntry], GetAppNum
    call AppMain

    leave
    ret