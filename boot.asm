org 0x7c00

jmp short start
nop

define:
    BaseOfStack equ 0x7c00
    RootEntryOffset  equ 19
    RootEntryLength  equ 14

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
    
    mov ax, RootEntryOffset
    mov cx, RootEntryLength
    mov bx, Buf
    
    call ReadSector
    
    mov si, Target
    mov cx, TarLen
    mov dx, 0
    
    call FindEntry
    
    cmp dx, 0
    jz output
    jmp last
    
output:    
    mov bp, MsgStr
    mov cx, MsgLen
    call Print
    
last:
    hlt
    jmp last    

; es:bx --> root entry offset address
; ds:si --> target string
; cx    --> target length
;
; return:
;     (dx != 0) ? exist : noexist
;        exist --> bx is the target entry
FindEntry:
    push di
    push bp
    push cx
    
    mov dx, [BPB_RootEntCnt]
    mov bp, sp
    
find:
    cmp dx, 0
    jz noexist
    mov di, bx
    mov cx, [bp]
    call MemCmp
    cmp cx, 0
    jz exist
    add bx, 32
    dec dx
    jmp find

exist:
noexist:
    pop cx
    pop bp
    pop di
       
    ret

; ds:si --> source
; es:di --> destination
; cx    --> length
;
; return:
;        (cx == 0) ? equal : noequal
MemCmp:
    push si
    push di
    push ax
    
compare:
    cmp cx, 0
    jz equal
    mov al, [si]
    cmp al, byte [di]
    jz goon
    jmp noequal
goon:
    inc si
    inc di
    dec cx
    jmp compare
    
equal:
noequal:   
    pop ax
    pop di
    pop si
    
    ret

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

MsgStr db  "No LOADER ..."    
MsgLen equ ($-MsgStr)
Target db  "LOADER     "
TarLen equ ($-Target)
Buf:
    times 510-($-$$) db 0x00
    db 0x55, 0xaa


