%include "blfunc.asm"
%include "common.asm"

; unshort LoadApp(char* app, unshort AppLen, unshort BaseOfApp, unshort BOT_Div_0x10, char* Buffer)
; return:
;     dx --> (dx != 0) ? success : failure
; running on 16 bits, sizeof(char*) = 2
LoadApp:
    mov bp, sp

    mov ax, RootEntryOffset
    mov cx, RootEntryLength
    mov bx, [bp + 10]

    call ReadSector

    mov si, [bp + 2]
    mov cx, [bp + 4]
    mov dx, 0

    call FindEntry
    cmp dx, 0
    jz app_finish

    mov si, bx
    mov di, EntryItem
    mov cx, EntryItemLength
    call MemCpy

    mov bp, sp
    mov ax, FatEntryLength
    mov cx, [BPB_BytsPerSec]
    mul cx
    mov bx, [bp + 6]
    sub bx, ax

    mov ax, FatEntryOffset
    mov cx, FatEntryLength
    call ReadSector

    mov dx, [EntryItem + 0x1A]
    mov es, [bp + 8]
    xor si, si

app_loading:
    mov ax, dx
    add ax, 31
    mov cx, 1
    push dx
    push bx
    mov bx, si
    call ReadSector
    pop bx
    pop cx
    call FatVec
    cmp dx, 0xFF7
    jnb app_finish
    add si, 512
    cmp si, 0
    jnz app_continue
    mov si, es
    add si, 0x1000
    mov es, si
    mov si, 0
app_continue:
    jmp app_loading

app_finish:
    ret
