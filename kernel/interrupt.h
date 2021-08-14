#ifndef INTERRUPT_H
#define INTERRUPT_H

#include "kernel.h"


extern void (* const InitInterrupt)();
extern void (* const EnableTimer)();
extern void (* const SendEOI)(uint port);

int SetInterruptHandler(Gate* gate, uint func);
int GetInterruptHandler(Gate* gate, uint* func);

void InitInterrupts();

#endif // INTERRUPT_H

