#include "ihandler.h"
#include "task.h"
#include "interrupt.h"

#include "syscall.h"

void TimerHandler()
{
	Schedule();
	SendEOI(MASTER_EOI_PORT);
}

void SystemCallHandler(ushort ax, ushort bx) // __cdecl__
{
    SetPrintPosition(0, 11);
    PrintString("ax = ");
    PrintInt10(ax);
    PrintString(" bx = ");
    PrintInt10(bx);
    PrintChar('\n');

    SetPrintPosition(0, 16);
    PrintString("enter soft interrupt. \n");

    PrintString("ax=");
    PrintInt10(ax);
    PrintChar('\n');

    if (ax == 1)
    {
        _exit();
    }
}
