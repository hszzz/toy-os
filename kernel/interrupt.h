#ifndef INTERRUPT_H
#define INTERRUPT_H

extern void (* const InitInterrupt)();
extern void (* const EnableTimer)();
extern void (* const SendEOI)(uint port);

int SetInterruptHandler(Gate* gate, uint func);
int GetInterruptHandler(Gate* gate, uint* func);

#endif // INTERRUPT_H

