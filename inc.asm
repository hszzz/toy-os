; Segment Attribute
DA_32     equ    0x4000
DA_DR     equ    0x90
DA_DRW    equ    0x90
DA_DRWA   equ    0x93
DA_C      equ    0x98
DA_CR     equ    0x9A
DA_CCO    equ    0x9C
DA_CCOR   equ    0x9E

; Selector Attribute
SA_RPL0    equ    0
SA_RPL1    equ    1
SA_RPL2    equ    2
SA_RPL3    equ    3

SA_TIG    equ    0
SA_TIL    equ    4

; Descriptor
%macro Descriptor 3
    dw  %2 & 0xFFFF
    dw  %1 & 0xFFFF
    db  (%1 >> 16) & 0xFF
    dw  ((%2 >> 8) & 0xF00) | (%3 & 0xF0FF) 
    db  (%1 >> 24) & 0xFF
%endmacro
