#include "interrupt.h"
#include "task.h"
#include "logo.h"

extern void (*InitAppModule)();
void (*InitAppModule)() = (void*)0x1F000;

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

    InitAppModule();
    PrintString("init app module\n");
    InitTaskModule();
    PrintString("init task module\n");
    InitInterruptModule();
    PrintString("init int module\n");

    // PageConfig();
    PrintString("init page module\n");

    LaunchTask();
    while (1);
}
