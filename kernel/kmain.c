#include "interrupt.h"
#include "kernel.h"
#include "kprint.h"
#include "const.h"
#include "task.h"
#include "utility.h"
#include "logo.h"

extern void TimerHandlerEntry();

void TimerHandler()
{
    static uint i = 0;

	if (i == 0) 
	{
		Schedule();
	}

	SendEOI(MASTER_EOI_PORT);
}

void KMain()
{
    PrintLogo();

    PrintString("GDT Entry: ");
    PrintInt16((uint)gGdtInfo.entry);
    PrintChar('\n');
    
    PrintString("GDT Size: ");
    PrintInt10((uint)gGdtInfo.size);
    PrintChar('\n');

    PrintString("IDT Entry: ");
    PrintInt16((uint)gIdtInfo.entry);
    PrintChar('\n');
    
    PrintString("IDT Size: ");
    PrintInt10((uint)gIdtInfo.size);
    PrintChar('\n');
    
	SetInterruptHandler(gIdtInfo.entry + 0x20, (uint)TimerHandlerEntry);

    InitInterrupt();
    EnableTimer();

    InitTasks();
    LaunchTask();
}

