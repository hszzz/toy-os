#include "kernel.h"

gdtInfo gGdtInfo = {0};
IdtInfo gIdtInfo = {0};
void (* const RunProcess)(Process* pt) = NULL;
void (* const InitInterrupt)() = NULL;
void (* const EnableTimer)() = NULL;
void (* const SendEOI)(uint port) = NULL;

int setDescValue(Descriptor* desc, uint base, uint limit, ushort attr)
{
	int ret = 0;

	if ((ret = (desc != NULL)))
	{
		desc->limit1       = limit & 0xFFFF;
		desc->base1        = base & 0xFFFF;
		desc->base2        = (base >> 16) & 0xFF;
		desc->attr1        = attr & 0xFF;
		desc->attr2_limit2 = ((attr >> 8) & 0xF0) | ((limit >> 16) & 0xF);
		desc->base3        = (base >> 24) & 0xFF;
	}

	return ret;
}

int getDescValue(Descriptor* desc, uint* base, uint* limit, ushort* attr)
{
	int ret = 0;

	if ((ret = (desc && base && limit && attr)))
	{
		*base  = (desc->base3 << 24) | (desc->base2 << 16) | desc->base1;
		*limit = ((desc->attr2_limit2 & 0xF) << 16) | desc->limit1;
		*attr  = ((desc->attr2_limit2 & 0xF0) << 8) | desc->attr1;
	}

	return ret;
}

int SetInterruptHandler(Gate* gate, uint func)
{
	int ret = 0;

	if ((ret = (gate != NULL)))
	{
		gate->offset1 = func & 0xFFFF;
		gate->selector = GDT_CODE32_FLAT_SELECTOR;
		gate->dcount = 0;
		gate->attr = DA_386IGate + DA_DPL0;
		gate->offset2 = (func >> 16) & 0xFFFF;
	}

	return ret;
}

int GetInterruptHandler(Gate* gate, uint* func) 
{
	int ret = 0;
	return ret;
}

