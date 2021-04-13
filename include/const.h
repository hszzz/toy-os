#ifndef CONST_H
#define CONST_H

#define NULL ((void*)0)

#define DA_DPL0 0x00
#define DA_DPL1 0x20
#define DA_DPL2 0x40
#define DA_DPL3 0x60

#define SA_RPL_MASK 0xFFFC

#define SA_RPL0 0
#define SA_RPL1 1
#define SA_RPL2 2
#define SA_RPL3 3

#define SA_TI_MASK 0xFFFB

#define SA_TIG 0
#define SA_TIL 4

#define DA_32 0x4000
#define DA_LIMIT_4K 0x8000

#define DA_DR   0x90
#define DA_DRW  0x92
#define DA_DRWA 0x93
#define DA_C    0x98
#define DA_CR   0x9A
#define DA_CCO  0x9C
#define DA_CCOR 0x9E

#define DA_LDT      0x82
#define DA_TaskGate 0x85
#define DA_386TSS   0x89
#define DA_386CGate 0x8C
#define DA_386IGate 0x8E
#define DA_386TGate 0x8F

#define GDT_ENTRY_INDEX       0
#define GDT_CODE32_INDEX      1
#define GDT_GRAPHICS_INDEX    2 
#define GDT_CODE32_FLAT_INDEX 3 
#define GDT_DATA32_FLAT_INDEX 4

#define GDT_TASK_LDT_INDEX 5
#define GDT_TASK_TSS_INDEX 6

#define	GDT_ENTRY_SELECTOR       ((GDT_ENTRY_INDEX << 3)       + SA_TIG + SA_RPL0)
#define	GDT_CODE32_SELECTOR      ((GDT_CODE32_INDEX << 3)      + SA_TIG + SA_RPL0)
#define	GDT_GRAPHICS_SELECTOR    ((GDT_GRAPHICS_INDEX << 3)    + SA_TIG + SA_RPL0)
#define	GDT_CODE32_FLAT_SELECTOR ((GDT_CODE32_FLAT_INDEX << 3) + SA_TIG + SA_RPL0)
#define	GDT_DATA32_FLAT_SELECTOR ((GDT_DATA32_FLAT_INDEX << 3) + SA_TIG + SA_RPL0)

#define	GDT_TASK_LDT_SELECTOR    ((GDT_TASK_LDT_INDEX << 3) + SA_TIG + SA_RPL0)
#define	GDT_TASK_TSS_SELECTOR    ((GDT_TASK_TSS_INDEX << 3) + SA_TIG + SA_RPL0)

#define	LDT_GRAPHICS_INDEX      0
#define	LDT_CODE32_INDEX        1
#define	LDT_DATA32_INDEX        2

#define	LDT_GRAPHICS_SELECTOR  ((LDT_GRAPHICS_INDEX << 3) + SA_TIL + SA_RPL3)	
#define	LDT_CODE32_SELECTOR    ((LDT_CODE32_INDEX << 3)   + SA_TIL + SA_RPL3)	
#define	LDT_DATA32_SELECTOR    ((LDT_DATA32_INDEX << 3)   + SA_TIL + SA_RPL3)	

#endif

