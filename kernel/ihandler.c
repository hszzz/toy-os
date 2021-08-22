#include "ihandler.h"
#include "task.h"
#include "interrupt.h"

void TimerHandler()
{
    static uint i = 0;

	if (i == 0) 
	{
		Schedule();
	}

	SendEOI(MASTER_EOI_PORT);
}

void SystemCallHandler()
{

}
