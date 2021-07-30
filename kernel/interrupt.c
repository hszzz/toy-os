#include "interrupt.h"

void (* const InitInterrupt)() = NULL;
void (* const EnableTimer)() = NULL;
void (* const SendEOI)(uint port) = NULL;

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

	if ((ret = (gate && func)))
	{
		*func = (gate->offset2 << 16) | gate->offset1;
	}

	return ret;
}

