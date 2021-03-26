; low     <== 0x7c00 ==>    0x7e00 ==>      0x9000 ==>      high
; |-->  stack <--|--> boot <--|--> fat table <--|--> loader <--|

org 0x7c00

%include "blfunc.asm"

BaseOfStack  equ 0x7c00
BaseOfTarget equ 0x9000
Target       db  "LOADER     "
TarLen       equ $ - Target

BLMain:
    mov ax, cs
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov sp, SPInitValue

    call LoadTarget

    cmp dx, 0
    jz output
    jmp BaseOfTarget

output:
    mov bp, Error
    mov cx, ErrLen
	call Print

Error db "Not Found Loader"
ErrLen equ $ - Error

Buffer:
    times 510-($-$$) db 0x00
    db 0x55, 0xaa
