; low     <== 0x7c00 ==>    0x7e00 ==>      0x9000 ==>      high
; |-->  stack <--|--> boot <--|--> fat table <--|--> loader <--|

org 0x7c00

%include "blfunc.asm"
%include "common.asm"

BaseOfStack  equ 0x7c00
BaseOfLoader equ 0x9000

Loader       db  "LOADER     "
LoaderLen    equ ($ - Loader)

BLMain:
    mov ax, cs
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov sp, SPInitValue

    push word Buffer
    push word BaseOfLoader / 0x10
    push word BaseOfLoader
    push word LoaderLen
    push word Loader
    call LoadTarget

    cmp dx, 0
    jz output
    jmp BaseOfLoader

output:
    mov ax, cs
    mov es, ax
    mov bp, Error
    mov cx, ErrLen
    xor dx, dx
    mov ax, 0x1301
    mov bx, 0x0007
    int 0x10

    jmp $

Error  db  "No Loader"
ErrLen equ ($ - Error)

Buffer:
    times 510-($-$$) db 0x00
    db 0x55, 0xaa
