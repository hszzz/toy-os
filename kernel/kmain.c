#include "interrupt.h"
#include "task.h"
#include "logo.h"

extern void (*InitAppModule)();
void (*InitAppModule)() = (void*)0x1F000;

void KMain()
{
    PrintLogo();
    PrintString("enter kernel !!!\n");
    PrintInt16((int)InitAppModule);
    // void (*InitAppModule)() = (void*)0xF000;

    // PrintString("GDT Entry: ");
    // PrintInt16((uint)gGdtInfo.entry);
    // PrintChar('\n');
    
    // PrintString("GDT Size: ");
    // PrintInt10((uint)gGdtInfo.size);
    // PrintChar('\n');

    // PrintString("IDT Entry: ");
    // PrintInt16((uint)gIdtInfo.entry);
    // PrintChar('\n');
    
    // PrintString("IDT Size: ");
    // PrintInt10((uint)gIdtInfo.size);
    // PrintChar('\n');

    InitAppModule();
    InitTaskModule();
    InitInterruptModule();
    LaunchTask();
    while (1);
}
