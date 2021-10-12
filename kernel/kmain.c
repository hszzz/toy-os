#include "interrupt.h"
#include "kernel.h"
#include "kprint.h"
#include "const.h"
#include "task.h"
#include "utility.h"
#include "logo.h"

void KMain()
{
    PrintLogo();

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

    InitInterrupts();
    InitTasks();
    LaunchTask();
    while (1);
}

