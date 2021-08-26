#include "ihandler.h"
#include "task.h"
#include "interrupt.h"

void TimerHandler()
{
	Schedule();

	SendEOI(MASTER_EOI_PORT);
}

void SystemCallHandler()
{

}
