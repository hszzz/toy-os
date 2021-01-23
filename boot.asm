org 0x7c00

jmp short start
nop

define:
    BaseOfStack equ 0x7c00

header:
    BS_OEMName     db "hszzz"
    BPB_BytsPerSec dw 512
    BPB_SecPerClus db 1
    BPB_RsvdSecCnt dw 1
    BPB_NumFATs    db 2
    BPB_RootEntCnt dw 224
    BPB_TotSec16   dw 2880
    BPB_Media      db 0xF0
    BPB_FATSz16    dw 9
    BPB_SecPerTrk  dw 18
    BPB_NumHeads   dw 2
    BPB_HiddSec    dd 0
    BPB_TotSec32   dd 0
    BS_DrvNum      db 0
    BS_Reserved1   db 0
    BS_BootSig     db 0x29
    BS_VolID       dd 0
    BS_VolLab      db "TOY-OS-0.01"
    BS_FileSysType db "FAT12   "

start:
    mov ax, cs
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov sp, BaseOfStack
    
    mov ax, 34
    mov cx, 1
    mov bx, Buf
    
    call ReadSector
    
    mov bp, Buf
    mov cx, 29
    
    call Print
    
last:
    hlt
    jmp last    

; es:bp --> string address
; cx    --> string length
Print:
    mov ax, 0x1301
    mov bx, 0x0007
    int 0x10
    ret

; no parameter
ResetFloppy:
    push ax
    push dx
    
    mov ah, 0x00
    mov dl, [BS_DrvNum]
    int 0x13
    
    pop dx
    pop ax
    
    ret

; ax    --> logic sector number
; cx    --> number of sector
; es:bx --> target address
ReadSector:
    push bx
    push cx
    push dx
    push ax
    
    call ResetFloppy
    
    push bx
    push cx
    
    mov bl, [BPB_SecPerTrk]
    div bl
    mov cl, ah
    add cl, 1
    mov ch, al
    shr ch, 1
    mov dh, al
    and dh, 1
    mov dl, [BS_DrvNum]
    
    pop ax
    pop bx
    
    mov ah, 0x02

read:    
    int 0x13
    jc read
    
    pop ax
    pop dx
    pop cx
    pop bx
    
    ret

MsgStr db  "Hello, TOY-OS!"    
MsgLen equ ($-MsgStr)
Buf:
    times 510-($-$$) db 0x00
    db 0x55, 0xaa

