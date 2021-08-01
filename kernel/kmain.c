#include "interrupt.h"
#include "kernel.h"
#include "kprint.h"
#include "const.h"

#include "logo.h"

Task* gTaskAddr = NULL;
Task p = {0};

extern void TimerHandlerEntry();

void Delay(int n)
{
    while( n > 0 )
    {
        int i = 0;
        int j = 0;
        
        for(i=0; i<1000; i++)
        {
            for(j=0; j<1000; j++)
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
    
    while(1)
    {
        SetPrintPosition(8, 19);
        PrintChar('A' + i);
        i = (i + 1) % 26;
        Delay(1);
    }
}

void TimerHandler()
{
    static uint i = 0;

    i = (i + 1) % 10;

    SetPrintPosition(0, 16);
    PrintString("Timer: ");

	if (i == 0) 
	{
		static uint j = 0;
		j %= 10;
		SetPrintPosition(0, 16);
		PrintString("Timer: ");

		SetPrintPosition(8, 16);
		PrintInt10(j++);
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

    PrintString("RunTask: ");
    PrintInt16((uint)RunTask);
    PrintChar('\n');

    PrintString("InitInterrupt: ");
    PrintInt16((uint)InitInterrupt);
    PrintChar('\n');
    
    PrintString("EnableTimer: ");
    PrintInt16((uint)EnableTimer);
    PrintChar('\n');

    PrintString("SendEOI: ");
    PrintInt16((uint)SendEOI);
    PrintChar('\n');

    p.rv.cs = LDT_CODE32_SELECTOR;
    p.rv.gs = LDT_GRAPHICS_SELECTOR;
    p.rv.ds = LDT_DATA32_SELECTOR;
    p.rv.es = LDT_DATA32_SELECTOR;
    p.rv.fs = LDT_DATA32_SELECTOR;
    p.rv.ss = LDT_DATA32_SELECTOR;
    
    p.rv.esp = (uint)p.stack + sizeof(p.stack);
    p.rv.eip = (uint)TaskA;
    p.rv.eflags = 0x3202;
    
    p.tss.ss0 = GDT_DATA32_FLAT_SELECTOR;
    p.tss.esp0 = 0x9000;
    p.tss.iomb = sizeof(p.tss);
    
    SetDescValue(p.ldt + LDT_GRAPHICS_INDEX, 0xB8000, 0x07FFF, DA_DRWA + DA_32 + DA_DPL3);
    SetDescValue(p.ldt + LDT_CODE32_INDEX,   0x00,    0xFFFFF, DA_C    + DA_32 + DA_DPL3);
    SetDescValue(p.ldt + LDT_DATA32_INDEX,   0x00,    0xFFFFF, DA_DRW  + DA_32 + DA_DPL3);
    
    p.ldtSelector = GDT_TASK_LDT_SELECTOR;
    p.tssSelector = GDT_TASK_TSS_SELECTOR;
    
    SetDescValue(&gGdtInfo.entry[GDT_TASK_LDT_INDEX], (uint)&p.ldt, sizeof(p.ldt)-1, DA_LDT    + DA_DPL0);
    SetDescValue(&gGdtInfo.entry[GDT_TASK_TSS_INDEX], (uint)&p.tss, sizeof(p.tss)-1, DA_386TSS + DA_DPL0);

	SetInterruptHandler(gIdtInfo.entry + 0x20, (uint)TimerHandlerEntry);

    InitInterrupt();
    EnableTimer();

    gTaskAddr = &p;
    RunTask(gTaskAddr);
}
