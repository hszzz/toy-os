%include "inc.asm"

org 0x9000

jmp ENTRY_SEGMENT

[section .gdt]
; GDT Definition BEGIN
GDT_ENTRY     : Descriptor  0,       0,                    0
CODE32_DESC   : Descriptor  0,       Code32SegmentLen - 1, DA_C + DA_32
GRAPHICS_DESC : Descriptor  0xB8000, 0x07FFF,              DA_DRWA + DA_32
DATA32_DESC   : Descriptor  0,       DataSegmentLen - 1,   DA_DR + DA_32
GSTACK_DESC   : Descriptor  0,       TopOfStack32,         DA_DRW + DA_32

; used in back to real mode 
CODE16_DESC   : Descriptor  0,       0xFFFF,               DA_C
UPDATE_DESC   : Descriptor  0,       0xFFFF,               DA_DRW

; task a LDT
TASK_A_LDT_DESC : Descriptor 0,      TaskALdtLen - 1,      DA_LDT

; Call Gate Test
FUNCTION_DESC : Descriptor 0,        FunctionSegmentLen - 1,  DA_C + DA_32  
CG_FUNC_ADD_DESC : Gate    FunctionSelector, CG_Add, 0, DA_386CGate 
CG_FUNC_SUB_DESC : Gate    FunctionSelector, CG_Sub, 0, DA_386CGate 
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

Code16Selector    equ    (0x0005 << 3) + SA_TIG + SA_RPL0
UpdateSelector    equ    (0x0006 << 3) + SA_TIG + SA_RPL0

TaskALdtSelector    equ    (0x0007 << 3) + SA_TIG + SA_RPL0

FunctionSelector  equ    (0x0008 << 3) + SA_TIG + SA_RPL0

CGFuncAddSelector equ    (0x0009 << 3) + SA_TIG + SA_RPL0
CGFuncSubSelector equ    (0x000A << 3) + SA_TIG + SA_RPL0
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
ENTRY_SEGMENT:
    mov	ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, TopOfStack16

    ; HACK TRICK
    ; replace 0 whit cs
    mov [BACK_TO_REAL_MODE + 3], ax

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

    ; initialize GDT for 16 bits protected mode segment
    mov esi, CODE16_SEGMENT
    mov edi, CODE16_DESC
    call InitDescItem

    ; initialize LDT for Task A
    mov esi, TASK_A_LDT_ENTRY
    mov edi, TASK_A_LDT_DESC
    call InitDescItem

    mov esi, TASK_A_CODE32_SEGMENT
    mov edi, TASK_A_CODE32_DESC
    call InitDescItem

    mov esi, TASK_A_DATA32_SEGMENT
    mov edi, TASK_A_DATA32_DESC
    call InitDescItem

    mov esi, TASK_A_STACK32_SEGMENT
    mov edi, TASK_A_STACK32_DESC
	call InitDescItem

    ; initialize FUNCTION_SEGMENT
    mov esi, FUNCTION_SEGMENT
    mov edi, FUNCTION_DESC
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

; 16 bits protected mode back to real mode
BACK_ENTRY_SEGMENT:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, TopOfStack16

    ; close pretected mode 
    in al, 0x92
	and al, 11111101b
    out 0x92, al

    ; open interreputer
    sti

    ; print string in real mode
    mov bp, HELLO
    mov cx, 12
    mov dx, 0
    mov ax, 0x1301
    mov bx, 0x0007
    int 0x10

    jmp $
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

; protected mode --> real mode
; 1. 32 bits protected mode --> 16 bits protected mode
; 2. 16 bits protected mode --> real mode 
[section .s16]
[bits 16]
CODE16_SEGMENT:
    ; update all register used in real mode 
    ; but DON'T update *cs*
    mov ax, UpdateSelector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; notify CPU to exit protected mode
    mov eax, cr0
    and al, 11111110b
	mov cr0, eax

; HACK TRICK: get code segment address when program is running
BACK_TO_REAL_MODE:
    jmp 0 : BACK_ENTRY_SEGMENT

CODE16_SegmentLen    equ    $ - CODE16_SEGMENT

[section .func]
[bits 32]
FUNCTION_SEGMENT:

; ax --> a
; bx --> b
;
; return
;    cx --> a + b
FuncAdd:
    mov cx, ax
	add cx, bx
    retf    ; ret far
CG_Add    equ    FuncAdd - $$

; ax --> a
; bx --> b
;
; return
;    cx --> a - b
FuncSub:
    mov cx, ax
	sub cx, bx
    retf    ; ret far
CG_Sub    equ    FuncSub - $$

FunctionSegmentLen    equ    $ - FUNCTION_SEGMENT  

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

    ; test Call Gate
    mov ax, 1
    mov bx, 1
    call CGFuncAddSelector : 0 ; == call FunctionSelector : CG_Add

    mov ax, 2
    mov bx, 1
    call CGFuncSubSelector : 0 ; == call FunctionSelector : CG_Sub


    ;jmp	CODE32_SEGMENT
    
    ; jmp to 16 bits protected mode
    ; jmp Code16Selector : 0
    
    ; load LDT for task A
    mov ax, TaskALdtSelector
    lldt ax

    ; jmp to task A
    jmp TaskACode32Selector : 0

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

; global stack segment
[section .gs]
[bits 32]
STACK32_SEGMENT:
    times 1024 * 4 db 0
Stack32SegmentLen    equ    $ - STACK32_SEGMENT
TopOfStack32         equ    Stack32SegmentLen - 1

; task A segment

; task a LDT definition 
[section .task-a-ldt]
TASK_A_LDT_ENTRY:
TASK_A_CODE32_DESC    : Descriptor    0,    TaskACode32SegmentLen - 1,    DA_C + DA_32
TASK_A_DATA32_DESC    : Descriptor    0,    TaskAData32SegmentLen - 1,    DA_DR + DA_32
TASK_A_STACK32_DESC   : Descriptor    0,    TaskAStack32SegmentLen -1,    DA_DRW + DA_32

TaskALdtLen equ $ - TASK_A_LDT_ENTRY

; Task A LDT selector
; unlike GDT, the first item(index: 0) of LDT should be used
TaskACode32Selector    equ   (0x0000 << 3) + SA_TIL + SA_RPL0
TaskAData32Selector    equ   (0x0001 << 3) + SA_TIL + SA_RPL0
TaskAStack32Selector   equ   (0x0002 << 3) + SA_TIL + SA_RPL0

[section .task-a-data]
[bits 32]
TASK_A_DATA32_SEGMENT:
    TASK_A_STRING db "task a string", 0
    TASK_A_STRING_OFFSET equ TASK_A_DATA32_SEGMENT - $$
TaskAData32SegmentLen equ $ - TASK_A_DATA32_SEGMENT

[section .task-a-gs]
[bits 32]
TASK_A_STACK32_SEGMENT:
    times 1024 db 0
TaskAStack32SegmentLen equ $ - TASK_A_STACK32_SEGMENT
TaskATopOfStack32      equ TaskAStack32SegmentLen - 1

[section .task-a-s32]
[bits 32]
TASK_A_CODE32_SEGMENT:
    mov ax, GraphicsSelector
    mov gs, ax

    mov ax, TaskAStack32Selector
    mov ss, ax

    mov eax, TaskATopOfStack32
    mov esp, eax

    mov ax, TaskAData32Selector
    mov ds, ax

    mov ebp, TASK_A_STRING_OFFSET
    mov bx, 0x0C
    mov dh, 14
    mov dl, 29
    call TaskAPrintString

    jmp Code16Selector : 0

; ds:ebp    --> string address
; bx        --> attribute
; dx        --> dh : row, dl : col
TaskAPrintString:
    push ebp
    push eax
    push edi
    push cx
    push dx
    
task_print:
    mov cl, [ds:ebp]
    cmp cl, 0
    je task_end
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
    jmp task_print

task_end:
    pop dx
    pop cx
    pop edi
    pop eax
    pop ebp
    
    ret
    
TaskACode32SegmentLen   equ  $ - TASK_A_CODE32_SEGMENT
