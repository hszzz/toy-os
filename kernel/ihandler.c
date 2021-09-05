#include "ihandler.h"
#include "task.h"
#include "interrupt.h"
#include "syscall.h"

void TimerHandler()
{
	Schedule();
	SendEOI(MASTER_EOI_PORT);
}

void SystemCallHandler(uint ax) // __cdecl__
{
    if (ax == 1)
    {
        _exit();
    }
}
