org 0x9000

%include "blfunc.asm"
%include "common.asm"

BaseOfStack  equ 0x9000
BaseOfTarget equ 0xD000
Target       db  "KERNEL     "
TarLen       equ $-Target

[section .gdt]
; GDT definition
GDT_ENTRY          :   Descriptor    0,       0,                    0
CODE32_DESC        :   Descriptor    0,       Code32SegmentLen - 1, DA_C + DA_32 + DA_DPL0
GRAPHICS_DESC      :   Descriptor    0xB8000, 0x07FFF,              DA_DRWA + DA_32 + DA_DPL0
CODE32_FLAT_DESC   :   Descriptor    0,       0xFFFFF,              DA_C + DA_32 + DA_DPL0
DATA32_FLAT_DESC   :   Descriptor    0,       0xFFFFF,              DA_DRW + DA_32 + DA_DPL0

; these two descriptor can load a process dynamicly
TASK_LDT_DESC      :   Descriptor    0,       0,                    0
TASK_TSS_DESC      :   Descriptor    0,       0,                    0
; GDT end

GdtLen    equ   $ - GDT_ENTRY

GDT_PTR:
          dw   GdtLen - 1
          dd   0
          
          
; GDT Selector
Code32Selector      equ  (0x0001 << 3) + SA_TIG + SA_RPL0
GraphicsSelector    equ  (0x0002 << 3) + SA_TIG + SA_RPL0
Code32FlatSelector  equ  (0x0003 << 3) + SA_TIG + SA_RPL0
Data32FlatSelector  equ  (0x0004 << 3) + SA_TIG + SA_RPL0
; end of gdt section

[section .idt]
align 32
[bits 32]
IDT_ENTRY:
%rep 256
    Gate    Code32Selector,    DefaultHandler,     0,    DA_386IGate + DA_DPL0
%endrep

IdtLen    equ    $ - IDT_ENTRY

IDT_PTR:
    dw IdtLen - 1
    dd 0

; end of idt section

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

    ; initialize IDT pointer struct
    mov eax, 0
    mov ax, ds
    shl eax, 4
    add eax, IDT_ENTRY
    mov dword [IDT_PTR + 2], eax

    call LoadTarget
	
    cmp dx, 0
    jz output

    call StoreGlobalFunc

    ; 1. load GDT
    lgdt [GDT_PTR]
    
    ; 2. close interrupt
    ;    set IOPL to 3
    cli 

    ; load IDT
    lidt [IDT_PTR]

    pushf
    pop eax
    
    or eax, 0x3000
    
    push eax
    popf
    
    ; 3. open A20
    in al, 0x92
    or al, 00000010b
    out 0x92, al
    
    ; 4. enter protect mode
    mov eax, cr0
    or eax, 0x01
    mov cr0, eax
    
    ; 5. jump to 32 bits code
    jmp dword Code32Selector : 0

output:	
    mov bp, Error
    mov cx, ErrLen
    call Print
	
    jmp $

; esi --> code segment label
; edi --> descriptor label
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

; store GDT to shared memory
StoreGlobalFunc:
    ; store RunProcess to shared memory
    ; due to kernel wants to switch process
    mov dword [RunTaskEntry], RunTask

    mov dword [InitInterruptEntry], InitInterrupt
    mov dword [EnableTimerEntry], EnableTimer
    mov dword [SendEOIEntry], SendEOI
    mov dword [LoadTaskEntry], LoadTask

    ; store gdt to sharedmemory
    mov eax, dword [GDT_PTR + 2]
    mov dword [GdtEntry], eax
    mov dword [GdtSize], GdtLen / 8

    ; store gdt to sharedmemory
    mov eax, dword [IDT_PTR + 2]
    mov dword [IdtEntry], eax
    mov dword [IdtSize], IdtLen / 8

    ret

; this segment define interrupt functions 
[section .ifunc]
[bits 32]
Delay:
    %rep 5
    nop
    %endrep
    ret

Init8259A:
    push ax
    
    mov al, 00010001B
    out MASTER_ICW1_PORT, al
    call Delay

    mov al, 0x20
    out MASTER_ICW2_PORT, al
    call Delay

    mov al, 00000100B
    out MASTER_ICW3_PORT, al
    call Delay

    mov al, 00010001B
    out MASTER_ICW4_PORT, al
    call Delay

    mov al, 00010001B
    out SLAVE_ICW1_PORT, al
    call Delay

    mov al, 0x28
    out SLAVE_ICW2_PORT, al
    call Delay

    mov al, 00000010B
    out SLAVE_ICW3_PORT, al
    call Delay

    mov al, 00000001B
    out SLAVE_ICW4_PORT, al
    call Delay

    pop ax
    ret

; al -> IMR register value
; dx -> 8259a port
WriteIMR:
    out dx, al
    call Delay
    ret

; dx -> 8259a
;    return ax -> IMR register value
ReadIMR:
    in ax, dx
    call Delay
    ret

; dx -> 8259a port
WriteEOI:
    push ax

    mov al, 0x20
    out dx, al
    call Delay

    pop ax
    ret

; function in this segment 
; will be called by kernel
[section .kfunc]
[bits 32]
; RunTask(Task* p)
RunTask:
    push ebp
    mov  ebp, esp

    mov  esp, [ebp + 8] 

    lldt word [esp + 200]
    ltr  word [esp + 202]

    ; store previous process context
    pop gs
    pop fs
    pop es
    pop ds

    popad

    add esp, 4
    iret

; void LOadTask(Task*);
LoadTask:
    push ebp
    push ebp, esp

    mov eax, [ebp + 8]
    lldt word [eax + 200]

    leave
    ret

; init 8259a interrupt in kernel
InitInterrupt:
    push ebp
    mov ebp, esp

    push ax
    push dx

    call Init8259A

    ; open interrupt
    sti 

    mov ax, 0xFF
    mov dx, MASTER_IMR_PORT
    call WriteIMR

    mov ax, 0xFF
    mov dx, SLAVE_IMR_PORT
    call WriteIMR

    pop dx
    pop ax

    leave
    ret

EnableTimer:
    push ebp
    mov ebp, esp

    push ax
    push dx

    mov dx, MASTER_IMR_PORT
    call ReadIMR

    and ax, 0xFE
    call WriteIMR

    pop dx
    pop ax

    leave
    ret

; void SendEOI(uint port);
SendEOI:
    push ebp
    mov ebp, esp

    mov edx, [ebp + 8]
    mov al, 0x20
    out dx, al

    leave
    ret

[section .s32]
[bits 32]
CODE32_SEGMENT:
    mov ax, GraphicsSelector
    mov gs, ax

    mov ax, Data32FlatSelector
    mov ds, ax
    mov es, ax
    mov fs, ax

    mov ax, Data32FlatSelector
    mov ss, ax
    mov esp, BaseOfStack

    jmp dword Code32FlatSelector : BaseOfTarget

; default interrupt handler
DefaultHandlerFunc:
    iret

DefaultHandler    equ    DefaultHandlerFunc - $$

Code32SegmentLen    equ    $ - CODE32_SEGMENT

Error  db  "No KERNEL"	
ErrLen equ $-Error

Buffer db  0
