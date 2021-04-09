#ifndef KERNEL_H
#define KERNEL_H

#include "types.h"
#include "const.h"

typedef struct
{
	ushort limit1;
	ushort base1;
	byte   base2;
	byte   attr1;
	byte   attr2_limit2;
	byte   base3;
} Descriptor;

typedef struct
{
	Descriptor* const entry;
	const int         size;
} gdtInfo;

typedef struct
{
	uint gs;
	uint fs;
	uint es;
	uint ds;
	uint edi;
	uint esi;
	uint ebp;
	uint kesp;
	uint ebx;
	uint edx;
	uint ecx;
	uint eax;
	uint raddr;
	uint eip;
	uint cs;
	uint eflags;
	uint esp;
	uint ss;
} regValue;

typedef struct 
{
	uint   previous;
	uint   esp0;
	uint   ss0;
	uint   unused[22];
	ushort reserved;
	ushort iomb;
} TSS;

typedef struct
{
	regValue   rv;
	Descriptor ldt[3];
	TSS        tss;
	ushort     ldtSelectot;
	ushort     tssSelectot;
	uint       id;
	char       name[8];
	byte       stack[512];
} Process;

int setDescValue(Descriptor* desc, uint base, uint limit, ushort attr);
int getDescValue(Descriptor* desc, uint* base, uint* limit, ushort* attr);

#endif

