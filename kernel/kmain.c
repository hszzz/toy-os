#include "interrupt.h"
#include "kernel.h"
#include "kprint.h"
#include "const.h"

#include "logo.h"

volatile Task* gTaskAddr = NULL;
Task p = {0};
Task p1 = {0};

TSS gTSS = {0};

extern void TimerHandlerEntry();

void InitTask(Task* t, void(*entry)())
{   
   	t->rv.cs = LDT_CODE32_SELECTOR;
    t->rv.gs = LDT_GRAPHICS_SELECTOR;
    t->rv.ds = LDT_DATA32_SELECTOR;
    t->rv.es = LDT_DATA32_SELECTOR;
    t->rv.fs = LDT_DATA32_SELECTOR;
    t->rv.ss = LDT_DATA32_SELECTOR;
    
    t->rv.esp = (uint)t->stack + sizeof(t->stack);
    t->rv.eip = (uint)entry;
    t->rv.eflags = 0x3202;
    
    gTSS.ss0 = GDT_DATA32_FLAT_SELECTOR;
    gTSS.esp0 = (uint)&t->rv + sizeof(t->rv);
    gTSS.iomb = sizeof(TSS);
    
    SetDescValue(t->ldt + LDT_GRAPHICS_INDEX, 0xB8000, 0x07FFF, DA_DRWA + DA_32 + DA_DPL3);
    SetDescValue(t->ldt + LDT_CODE32_INDEX,   0x00,    0xFFFFF, DA_C    + DA_32 + DA_DPL3);
    SetDescValue(t->ldt + LDT_DATA32_INDEX,   0x00,    0xFFFFF, DA_DRW  + DA_32 + DA_DPL3);
    
    t->ldtSelector = GDT_TASK_LDT_SELECTOR;
    t->tssSelector = GDT_TASK_TSS_SELECTOR;
    
    SetDescValue(&gGdtInfo.entry[GDT_TASK_LDT_INDEX], (uint)&t->ldt, sizeof(t->ldt) - 1, DA_LDT    + DA_DPL0);
    SetDescValue(&gGdtInfo.entry[GDT_TASK_TSS_INDEX], (uint)&gTSS,   sizeof(gTSS) - 1,   DA_386TSS + DA_DPL0);
}

void Delay(int n)
{
    while (n > 0)
    {
        int i = 0;
        int j = 0;
        
        for (i=0; i<1000; i++)
        {
            for (j=0; j<1000; j++)
            {
                asm volatile ("nop\n");
            }
        }
        
        n--;
    }
}

void TaskA()
{
    int i = 0;
    
    SetPrintPosition(0, 19);
    
    PrintString("Task A: ");
    
    while (1)
    {
        SetPrintPosition(8, 19);
        PrintChar('A' + i);
        i = (i + 1) % 26;
        Delay(1);
    }
}

void TaskB()
{
    int i = 0;
    
    SetPrintPosition(0, 20);
    
    PrintString("Task B: ");
    
    while (1)
    {
        SetPrintPosition(8, 20);
        PrintChar('0' + i);
        i = (i + 1) % 10;
        Delay(1);
    }
}

void ChangeTask()
{
	gTaskAddr = (gTaskAddr == &p) ? &p1 : &p;

    SetPrintPosition(0, 21);
    PrintInt16(gTaskAddr);

	gTSS.ss0 = GDT_DATA32_FLAT_SELECTOR;
	gTSS.esp0 = (uint)&gTaskAddr->rv.gs + sizeof(RegValue);

    SetDescValue(&gGdtInfo.entry[GDT_TASK_LDT_INDEX], (uint)&gTaskAddr->ldt, sizeof(gTaskAddr->ldt) - 1, DA_LDT + DA_DPL0);

	LoadTask(gTaskAddr);
}

void TimerHandler()
{
    static uint i = 0;

    i = (i + 1) % 5;

	if (i == 0) 
	{
		ChangeTask();
	}

	SendEOI(MASTER_EOI_PORT);
}

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

	InitTask(&p, TaskA);
	InitTask(&p1, TaskB);

	SetInterruptHandler(gIdtInfo.entry + 0x20, (uint)TimerHandlerEntry);

    InitInterrupt();
    EnableTimer();

    gTaskAddr = &p1;
    RunTask(gTaskAddr);
}

