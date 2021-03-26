org 0x9000

%include "blfunc.asm"
%include "common.asm"

BaseOfStack  equ 0x9000
BaseOfTarget equ 0xB000
Target       db  "KERNEL     "
TarLen       db  $ - Target

[section .gdt]
; GDT Definition BEGIN
GDT_ENTRY     : Descriptor  0,       0,                    0
CODE32_FLAT_DESC : Descriptor 0,     0xFFFFF,              DA_C + DA_32
CODE32_DESC   : Descriptor  0,       Code32SegmentLen - 1, DA_C + DA_32
; GDT Definition END

GDT_LEN    equ    $ - GDT_ENTRY

GDT_PTR:
    dw GDT_LEN	- 1
    dd 0

; GDT Selector BEGIN
Code32FlatSelector    equ    (0x0001 << 3) + SA_TIG + SA_RPL0
Code32Selector        equ    (0x0002 << 3) + SA_TIG + SA_RPL0
; GDT Selector END

[section .s16]
[bits 16]
BLMain:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, SPInitValue

    ; initialize GDT for 32 bits code segment
    mov esi, CODE32_SEGMENT
    mov edi, CODE32_DESC
    
    call InitDescItem


    ; initialize GDT pointer struct
    mov eax, 0
    mov ax, ds
    shl eax, 4
    add eax, GDT_ENTRY
    mov dword [GDT_PTR + 2], eax

    call LoadTarget

    cmp dx, 0
    jz output

    ; load GDT
    lgdt [GDT_PTR]

    ; close interrupt
	cli

    ; set IOPL to 3
    pushf
    pop eax
   
    or eax, 0x3000
    
    push eax
    popf

    ; open A20
    in al, 0x92
    or al, 00000010b
    out 0x92, al

    ; enter protected mode
    mov eax, cr0
    or eax, 0x01
    mov cr0, eax

    ; jmp to 32 bits code segment
    jmp dword Code32Selector : 0

output:	
    mov bp, Error
    mov cx, ErrLen
	call Print
				
	jmp $

; esi  --> code segment 
; edi  --> descriptor
InitDescItem:
    push eax

    mov eax, 0
    mov ax, cs
    shl eax, 4
    add eax, esi
    mov word [edi + 2], ax
    shr eax, 16
    mov byte [edi + 4], al
    mov byte [edi + 7], ah

    pop eax

	ret

[section .s32]
[bits 32]
CODE32_SEGMENT:
    jmp dword Code32FlatSelector : BaseOfTarget

Code32SegmentLen    equ    $ - CODE32_SEGMENT

Error  db  "No KERNEL"	
ErrLen equ $ - Error

Buffer db  0

