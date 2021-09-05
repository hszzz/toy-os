#ifndef IHANDLER_H
#define IHANDLER_H

#include "types.h"

extern void TimerHandlerEntry();
void TimerHandler();

extern void SystemCallHandlerEntry();
void SystemCallHandler(uint ax);

#endif // IHANDLER_H
