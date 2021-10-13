#include "interrupt.h"
#include "ihandler.h"

void (* const InitInterrupt)();
void (* const EnableTimer)();
void (* const SendEOI)(uint port);

int SetInterruptHandler(Gate* gate, uint func)
{
	int ret = 0;

	if ((ret = (gate != NULL)))
	{
		gate->offset1 = func & 0xFFFF;
		gate->selector = GDT_CODE32_FLAT_SELECTOR;
		gate->dcount = 0;
		gate->attr = DA_386IGate + DA_DPL3; //!!! DA_DPL0 -> DA_DPL3, soft interrupt is running in DPL3
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

void InitInterruptModule()
{
    // timer
	SetInterruptHandler(gIdtInfo.entry + 0x20, (uint)TimerHandlerEntry);
	// system call
    SetInterruptHandler(gIdtInfo.entry + 0x80, (uint)SystemCallHandlerEntry);

    InitInterrupt();
    EnableTimer();
}
