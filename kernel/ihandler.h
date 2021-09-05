#ifndef IHANDLER_H
#define IHANDLER_H

#include "types.h"

extern void TimerHandlerEntry();
void TimerHandler();

extern void SystemCallHandlerEntry();
void SystemCallHandler(ushort ax, ushort bx);

#endif // IHANDLER_H
