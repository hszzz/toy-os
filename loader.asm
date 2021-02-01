%include "inc.asm"

org 0x9000

jmp CODE16_SEGMENT

[section .gdt]
; GDT Definition BEGIN
GDT_ENTRY     : Descriptor  0,       0,                    0
CODE32_DESC   : Descriptor  0,       Code32SegmentLen - 1, DA_C + DA_32
GRAPHICS_DESC : Descriptor  0xB8000, 0x07FFF,              DA_DRWA + DA_32
DATA32_DESC   : Descriptor  0,       DataSegmentLen - 1,   DA_DR + DA_32
GSTACK_DESC   : Descriptor  0,       TopOfStack32,         DA_DRW + DA_32
; GDT Definition END

GDT_LEN    equ    $ - GDT_ENTRY

GDT_PTR:
    dw GDT_LEN	- 1
    dd 0

; GDT Selector BEGIN
Code32Selector    equ    (0x0001 << 3) + SA_TIG + SA_RPL0
GraphicsSelector  equ    (0x0002 << 3) + SA_TIG + SA_RPL0
Data32Selector    equ    (0x0003 << 3) + SA_TIG + SA_RPL0
GStackSelector    equ    (0x0004 << 3) + SA_TIG + SA_RPL0
; GDT Selector END

TopOfStack16 equ 0x7C00

[section .dat]
[bits 32]
DATA32_SEGMENT:
    TOYOS db "toy-OS!", 0
    TOYOS_OFFSET equ TOYOS - $$ ; offset == TOYOS's address

    HELLO db "hello world!", 0
    HELLO_OFFSET equ HELLO - $$
DataSegmentLen equ $ - DATA32_SEGMENT

[section .s16]
[bits 16]
CODE16_SEGMENT:
    mov	ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, TopOfStack16

   ; initialize GDT for 32 bits code segment
    mov esi, CODE32_SEGMENT
    mov edi, CODE32_DESC
    call InitDescItem

	; initialize DGT for data32 segment
    mov esi, DATA32_SEGMENT
    mov edi, DATA32_DESC
    call InitDescItem

    ; initialize GDT for global segment
	mov esi, STACK32_SEGMENT
	mov edi, GSTACK_DESC
    call InitDescItem

    ; initialize GDT pointer struct
    mov eax, 0
    mov ax,  ds
    shl eax, 4
    add eax, GDT_ENTRY
    mov dword [GDT_PTR + 2], eax
	
    ; load GDT
    lgdt [GDT_PTR]	 ; load GDT 

    cli				 ; close interrupt
	
    in al, 0x92		 ; open A20
    or al, 00000010b 
    out 0x92, al

    mov eax, cr0	 ; enter protect mode
    or eax, 0x01
    mov cr0, eax

    ; jump to 32 bits mode
    jmp dword Code32Selector : 0

; esi --> code segment label
; edi --> descript label
InitDescItem:
    push eax

    mov eax, 0
    mov ax,	 cs
    shl	eax, 4
    add	eax, esi 
    mov word [edi + 2], ax
    shr eax, 16
    mov byte [edi + 4],	al
    mov byte [edi + 7], ah

    pop eax
    ret

[section .s32]
[bits 32]
CODE32_SEGMENT:
    mov ax, GraphicsSelector
    mov gs, ax

    ; initialize stack segment through selector
    mov eax, GStackSelector
    mov ss, eax

    mov eax, TopOfStack32
	mov esp, eax

    mov ax, Data32Selector
    mov ds, ax

    mov ebp, TOYOS_OFFSET
    mov bx, 0x0C
    mov dh, 12
    mov dl, 33
    call PrintString

    mov ebp, HELLO_OFFSET
    mov bx, 0x0C
    mov dh, 13
    mov dl, 30
    call PrintString

    jmp	CODE32_SEGMENT

; ds:ebp --> string address
; bx     --> attribute
; dx     --> dh: row, dl: col
PrintString:
    push ebp
    push edi
    push dx
    push cx
    push eax

print:
    mov cl, [ds:ebp]
    cmp cl, 0
    je end
    mov eax, 80
    mul dh
    add al, dl
    shl eax, 1
    mov edi, eax
    mov ah, bl
    mov al, cl
    mov [gs:edi], ax
    inc ebp
    inc dl
    jmp print

end:
    pop eax
    pop cx
    pop dx
    pop edi
    pop ebp

    ret

Code32SegmentLen    equ    $ - CODE32_SEGMENT

[section .gs]
[bits 32]
STACK32_SEGMENT:
    times 1024 * 4 db 0
Stack32SegmentLen    equ    $ - STACK32_SEGMENT
TopOfStack32         equ    Stack32SegmentLen - 1

