%include "common.asm"

PageDirBase0    equ    0x200000
PageTblBase0    equ    0x201000

PageDirBase1    equ    0x700000
PageTblBase1    equ    0x701000

ObjectAddrV     equ    0x401000
TargetAddr1     equ    0xD01000
TargetAddr2     equ    0xE01000

org 0x9000

jmp ENTRY_SEGMENT

[section .gdt]
; GDT Definition BEGIN
GDT_ENTRY     : Descriptor  0,       0,                    0
CODE32_DESC   : Descriptor  0,       Code32SegmentLen - 1, DA_C + DA_32 + DA_DPL0
GRAPHICS_DESC : Descriptor  0xB8000, 0x07FFF,              DA_DRWA + DA_32 + DA_DPL3
DATA32_DESC   : Descriptor  0,       DataSegmentLen - 1,   DA_DR + DA_32 + DA_DPL0
GSTACK_DESC   : Descriptor  0,       TopOfGStack,          DA_DRW + DA_32 + DA_DPL0

; used in back to real mode 
CODE16_DESC   : Descriptor  0,       0xFFFF,               DA_C
UPDATE_DESC   : Descriptor  0,       0xFFFF,               DA_DRW

; task a LDT
TASK_A_LDT_DESC : Descriptor 0,      TaskALdtLen - 1,      DA_LDT

FUNCTION_DESC : Descriptor 0,        FunctionSegmentLen - 1,  DA_C + DA_32 + DA_DPL0 
; Call Gate
FUNC_PRINTSTRING_DESC : Gate FunctionSelector, CG_PrintString, 0, DA_386CGate + DA_DPL3 
; TSS
TSS_DESC      : Descriptor  0,       TSSLen,               DA_386TSS + DA_DPL0

; Page Dir and Tbl Desc
PAGE_DIR_DESC0 : Descriptor PageDirBase0,   4095,            DA_DRW + DA_32 
PAGE_TBL_DESC0 : Descriptor PageTblBase0,   1023,            DA_DRW + DA_LIMIT_4K + DA_32

PAGE_DIR_DESC1 : Descriptor PageDirBase1,   4095,            DA_DRW + DA_32 
PAGE_TBL_DESC1 : Descriptor PageTblBase1,   1023,            DA_DRW + DA_LIMIT_4K + DA_32

; flat memory mode
FLAT_MODE_DESC : Descriptor 0,            0xFFFFF,           DA_DRW + DA_LIMIT_4K + DA_32

; system memory data Desc
SYS_DAT_DESC  : Descriptor 0,        Sysdat32SegLen - 1,       DA_DR + DA_32
; GDT Definition END

GDT_LEN    equ    $ - GDT_ENTRY

GDT_PTR:
    dw GDT_LEN	- 1
    dd 0

; GDT Selector BEGIN
Code32Selector    equ    (0x0001 << 3) + SA_TIG + SA_RPL0
GraphicsSelector  equ    (0x0002 << 3) + SA_TIG + SA_RPL3
Data32Selector    equ    (0x0003 << 3) + SA_TIG + SA_RPL0
GStackSelector    equ    (0x0004 << 3) + SA_TIG + SA_RPL0

Code16Selector    equ    (0x0005 << 3) + SA_TIG
UpdateSelector    equ    (0x0006 << 3) + SA_TIG

TaskALdtSelector  equ    (0x0007 << 3) + SA_TIG

FunctionSelector  equ    (0x0008 << 3) + SA_TIG + SA_RPL0

; Gate Selector
FuncPrintStringSelector    equ    (0x0009 << 3) + SA_TIG + SA_RPL3

TSSSelector       equ    (0x000A << 3) + SA_TIG + SA_RPL0

; Page Dir and Tbl Selector
PageDirSelector0   equ    (0x000B << 3) + SA_TIG + SA_RPL0
PageTblSelector0   equ    (0x000C << 3) + SA_TIG + SA_RPL0
PageDirSelector1   equ    (0x000D << 3) + SA_TIG + SA_RPL0
PageTblSelector1   equ    (0x000E << 3) + SA_TIG + SA_RPL0

; flat mode selector
FlatModeSelector   equ    (0x000F << 3) + SA_TIG + SA_RPL0

; sysdat segment selector 
SysDatSelector     equ    (0x0010 << 3) + SA_TIG + SA_RPL0
; GDT Selector END

[section .idt]
align 32
[bits 32]
LABEL_IDT:

IdtLen    equ    $ - LABEL_IDT
IdtPtr    dw     IdtLen - 1
          dd     0

; TSS
[section .tss]
[bits 32]
TSS_SEGMENT:
    dd 0
    dd TopOfGStack     ; priviliege 0
    dd GStackSelector
    dd 0               ; priviliege 1
    dd 0
    dd 0               ; priviliege 2
    dd 0
    times 4*18 dd 0
    dw 0
    dw $ - TSS_SEGMENT
    db 0xFF
TSSLen    equ    $ - TSS_SEGMENT

TopOfStack16 equ 0x7C00

[section .dat]
[bits 32]
DATA32_SEGMENT:
    TOYOS db "toy-OS!", 0
    TOYOS_LEN  equ $ - TOYOS 
    TOYOS_OFFSET equ TOYOS - $$ ; offset == TOYOS's address

    HELLO db "hello world!", 0
    HELLO_LEN  equ $ - HELLO 
    HELLO_OFFSET equ HELLO - $$
DataSegmentLen equ $ - DATA32_SEGMENT

; storage memory information
[section .sysdat]
[bits 32]
SYSDAT_SEGMENT:
    MEM_SIZE times 4 db 0
    MEM_SIZE_OFFSET equ MEM_SIZE - $$

    MEM_ARDS_NUM times 4 db 0
    MEM_ARDS_NUM_OFFSET equ MEM_ARDS_NUM - $$

    MEM_ARDS times 64*20 db 0
    MEM_ARDS_OFFSET equ MEM_ARDS - $$

Sysdat32SegLen equ $ - SYSDAT_SEGMENT

[section .s16]
[bits 16]
ENTRY_SEGMENT:
    mov	ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, TopOfStack16

    ; get physical memory size
    ; call GetMemSize
    call InitSysDat

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

    ; initialize TSS_DESC
    mov esi, TSS_SEGMENT
    mov edi, TSS_DESC
    call InitDescItem

    ; initialize SYS_DAT_DESC
    mov esi, SYSDAT_SEGMENT
    mov edi, SYS_DAT_DESC
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

    ; Test high privilege --> low privilege
    ; high privilege code CAN'T jump to low privilege code STRAIGHTLY
    ; 1. set stack(push ss, push sp)
    ; 2. set address of low privilege code (Selector : Offset) 
    ; push GStackSelector   ; push ss
    ; push TopOfGStack      ; push sp
    ; push Code32Selector   ; push cs
    ; push 0                ; push ip
    ; retf

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

; get physical memory size to sysdat by ARDS(0xE820) and 0xE801
; MAX(0xE820, 0xE801)
; return :
;    eax --> 0: ok; 1: error
InitSysDat:
    push edi
    push ebx
    push ecx
    push edx

    call GetMemSize

    mov edi, MEM_ARDS
    mov ebx, 0 ; !!!!!

doloop:
    mov eax, 0xE820
    mov edx, 0x534D4150
    mov ecx, 20

    int 0x15

    jc memerr

    cmp dword [edi + 16], 1 ; ensure ARDS type == 1, which is means system can use
    jne next

    mov eax, [edi]
    add eax, [edi + 8] ; BaseAddrLow + LengthLow

    cmp dword [MEM_SIZE], eax
    jnb next

    mov dword [MEM_SIZE], eax

next:
    add edi, 20
    inc dword [MEM_ARDS_NUM]

    cmp ebx, 0
    jne doloop

    mov eax, 0

    jmp memok 

memerr:
    mov dword [MEM_SIZE], 0
    mov dword [MEM_ARDS_NUM], 0
    mov eax, 1

memok:
    pop edx
    pop ecx
    pop ebx
    pop edi
    
    ret

; get physical memory size by 0xE801
GetMemSize:
    push eax
    push ebx
    push ecx
    push edx

    mov dword [MEM_SIZE], 0

   	xor eax, eax ; let cf = 0
    mov eax, 0xE801

    int 0x15
    
    jc geterr

    shl eax, 10 ;(1KB) 0 ~ 15MB 

    shl ebx, 6  ;(64KB) > 16MB
    shl ebx, 10

    mov ecx, 1
    shl ecx, 20 ; ecx = 1MB (16MB)

    add dword [MEM_SIZE], eax
    add dword [MEM_SIZE], ebx
    add dword [MEM_SIZE], ecx

    jmp getok

geterr:
    mov dword [MEM_SIZE], 0

getok:
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

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
; ds:ebp --> string address
; bx     --> attribute
; dx     --> dh: row, dl: col
FuncPrintString:
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
    retf
CG_PrintString    equ    FuncPrintString - $$

FunctionSegmentLen    equ    $ - FUNCTION_SEGMENT  

[section .s32]
[bits 32]
CODE32_SEGMENT:
    mov ax, GraphicsSelector
    mov gs, ax

    ; initialize stack segment through selector
    mov eax, GStackSelector
    mov ss, eax

    mov eax, TopOfGStack
    mov esp, eax

    mov ax, Data32Selector
    mov ds, ax

    ; use flat mode to change memory
    mov ax, FlatModeSelector
    mov es, ax
    
    mov esi, TOYOS_OFFSET
    mov edi, TargetAddr1
    mov ecx, TOYOS_LEN
    call MemCpy32

    mov esi, HELLO_OFFSET
    mov edi, TargetAddr2
    mov ecx, HELLO_LEN
    call MemCpy32

    mov eax, PageDirSelector0
    mov ebx, PageTblSelector0
    mov ecx, PageTblBase0
    call InitPageTable
    
    mov eax, PageDirSelector1
    mov ebx, PageTblSelector1
    mov ecx, PageTblBase1
    call InitPageTable

    mov eax, ObjectAddrV
    mov ebx, TargetAddr1
    mov ecx, PageDirBase0
    call MapAddress ; map virtual address 0x401000 to physical address 0xD01000

    mov eax, ObjectAddrV
    mov ebx, TargetAddr2
    mov ecx, PageDirBase0
    call MapAddress ; map virtual address 0x401000 to physical address 0xE01000

    mov eax, PageDirBase0
    call SwitchPageTable

    ; print Page Table 0: 0x401000 => (0xD01000, "hello toy-os")
    mov ax, FlatModeSelector
    mov ds, ax
    mov ebp, ObjectAddrV
    mov bx, 0x0C
    mov dh, 12
    mov dl, 33
    call PrintString1 

    ; print Page Table 0: 0x401000 => (0xD01000, "hello world")
    mov eax, PageDirBase1
    call SwitchPageTable

    mov ax, FlatModeSelector
    mov ds, ax
    mov ebp, ObjectAddrV
    mov bx, 0x0C
    mov dh, 13
    mov dl, 31
    call PrintString1

    jmp $ 

    mov ebp, TOYOS_OFFSET
    mov bx, 0x0C
    mov dh, 12
    mov dl, 33
    call FunctionSelector : CG_PrintString 

    mov ebp, HELLO_OFFSET
    mov bx, 0x0C
    mov dh, 13
    mov dl, 30
    call FunctionSelector : CG_PrintString

    ; initialize page for simulation task 1
    mov eax, PageDirSelector0
    mov ebx, PageTblSelector0
    mov ecx, PageTblBase0
    call InitPageTable

    ; initialize page for simulation task 2
    mov eax, PageDirSelector1
    mov ebx, PageTblSelector1
    mov ecx, PageTblBase1
    call InitPageTable

    ; simulation task switching 
    mov eax, PageDirBase0
    call SwitchPageTable

    mov eax, PageDirBase1
    call SwitchPageTable

    jmp $

    ; load TSS
    mov ax, TSSSelector
    ltr ax
    
    ; jmp to 16 bits protected mode
    ; jmp Code16Selector : 0
    
    ; load LDT for task A
    mov ax, TaskALdtSelector
    lldt ax

    ; jmp to task A
    push TaskAStack32Selector 
    push TaskATopOfStack32
    push TaskACode32Selector
    push 0
    retf
    ; jmp $

; map virtual address to physical address 
; es    --> flat mode
; eax   --> virtual address
; ebx   --> target address
; ecx   --> page directory base
MapAddress:
    push edi
    push esi
    push eax  ; [esp + 8]
    push ebx  ; [esp + 4]
    push ecx  ; [esp]

    ; 1. Take the high 10 bits of the virtual address
    ;    and calculate the position of the subpage table in the page directory
    mov eax, [esp + 8]
    shr eax, 22 ; >> 22
    and eax, 1111111111b
    shl eax, 2 ; << 2

    ; 2. Take the middle 10 bits of the virtual address 
    ;    and calculate the position of the physical address in the subpage table
    mov ebx, [esp + 8]
    shr ebx, 12
    and ebx, 1111111111b
    shr ebx, 2

    ; 3. Take the starting position of the subpage table
    mov esi, [esp]
    add esi, eax
    mov edi, [es:esi]
    and edi, 0xFFFFF000

    ; 4. Write the target address to the location of the subpage table
    and edi, ebx   
    mov ecx, [esp + 4]
    and ecx, 0xFFFFF000
    or  ecx, PG_P | PG_USU | PG_RWW
    mov [es:edi], ecx

    pop ecx
    pop ebx
    pop eax
    pop esi
    pop edi
    ret

; memory copy under protected mode
; es    --> flat mode selector
; ds:si --> source
; es:di --> destination
; cx    --> length
MemCpy32:
    push esi
    push edi
    push ecx
    push ax

    cmp esi, edi
    
	ja btoe

    add esi, ecx
    add edi, ecx
    dec esi
    dec edi

    jmp etob

btoe:
    cmp ecx, 0
    jz done
    mov al, [ds:esi]
    mov byte [es:edi], al
    inc esi
    inc edi
    dec ecx
    jmp btoe

etob:
    cmp ecx, 0
    jz done
    mov al, [ds:esi]
    mov byte [es:edi], al
    dec esi
    dec edi
    dec ecx
    jmp etob

done:
    pop ax
    pop ecx
    pop edi
    pop esi
    ret

; initialize page table
; eax --> page directory base selector
; ebx --> page table base selector
; ecx --> page table base
InitPageTable:
    push es
    push eax ; [esp + 12]
    push ebx ; [esp + 8]
    push ecx ; [esp + 4]
    push edi ; [esp]

    mov es, ax
    mov ecx, 1024
    mov edi, 0
    mov eax, [esp + 4]
    or  eax, PG_P | PG_USU | PG_RWW

    cld

initdir:
    stosd
    add eax, 4096
    loop initdir

    mov ax, [esp + 8]
    mov es, ax
    mov ecx, 1024 * 1024
    mov edi, 0
    mov eax, PG_P | PG_USU | PG_RWW
    
    cld

inittbl:
    stosd
    add eax, 4096
    loop inittbl

    pop edi
    pop ecx
    pop ebx
    pop eax
    pop es

    ret

; eax --> page directory base
; how to switch?
;   1. close page
;   2. switch page directory base
;   3. open page
SwitchPageTable:
    push eax
    
    ; close page
    mov eax, cr0
    and eax, 0x7FFFFFFF
    mov cr0, eax

    ; switch page directory base address
    mov eax, [esp]

    ; open page
    mov cr3, eax
    mov eax, cr0
    or  eax, 0x80000000
    mov cr0, eax

    pop eax
    ret

PrintString1:
    push ebp
    push edi
    push dx
    push cx
    push eax

print1:
    mov cl, [ds:ebp]
    cmp cl, 0
    je end1
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
    jmp print1

end1:
    pop eax
    pop cx
    pop dx
    pop edi
    pop ebp
    ret
;PrintString1    equ    PrintString1 - $$

Code32SegmentLen    equ    $ - CODE32_SEGMENT

; global stack segment
[section .gs]
[bits 32]
STACK32_SEGMENT:
    times 1024 * 4 db 0
Stack32SegmentLen    equ    $ - STACK32_SEGMENT
TopOfGStack         equ    Stack32SegmentLen - 1

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
    ; call FunctionSelector : CG_PrintString 
    call FuncPrintStringSelector : 0

    ; jmp to 16 bits protected mode
    ; jmp Code16Selector : 0
    jmp $

TaskACode32SegmentLen   equ  $ - TASK_A_CODE32_SEGMENT

