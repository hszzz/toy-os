#include "kernel.h"
#include "kprint.h"

#include "logo.h"


Process p = {0};

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
    
    setPrintPosition(0, 19);
    
    printString("Task A: ");
    
    while(1)
    {
        setPrintPosition(8, 19);
        printChar('A' + i);
        i = (i + 1) % 26;
        Delay(1);
    }
}

void KMain()
{
	printLogo();
    
    printString("GDT Entry: ");
    printInt16((uint)gGdtInfo.entry);
    printChar('\n');
    
    printString("GDT Size: ");
    printInt10((uint)gGdtInfo.size);
    printChar('\n');

    printString("IDT Entry: ");
    printInt16((uint)gIdtInfo.entry);
    printChar('\n');
    
    printString("GDT Size: ");
    printInt10((uint)gIdtInfo.size);
    printChar('\n');

    
    printString("runProcess: ");
    printInt16((uint)RunProcess);
    printChar('\n');


    printString("InitInterrupt: ");
    printInt16((uint)InitInterrupt);
    printChar('\n');
    
    p.rv.cs = LDT_CODE32_SELECTOR;
    p.rv.gs = LDT_GRAPHICS_SELECTOR;
    p.rv.ds = LDT_DATA32_SELECTOR;
    p.rv.es = LDT_DATA32_SELECTOR;
    p.rv.fs = LDT_DATA32_SELECTOR;
    p.rv.ss = LDT_DATA32_SELECTOR;
    
    p.rv.esp = (uint)p.stack + sizeof(p.stack);
    p.rv.eip = (uint)TaskA;
    p.rv.eflags = 0x3002;
    
    p.tss.ss0 = GDT_DATA32_FLAT_SELECTOR;
    p.tss.esp0 = 0x9000;
    p.tss.iomb = sizeof(p.tss);
    
    setDescValue(p.ldt + LDT_GRAPHICS_INDEX,  0xB8000, 0x07FFF, DA_DRWA + DA_32 + DA_DPL3);
    setDescValue(p.ldt + LDT_CODE32_INDEX, 0x00,    0xFFFFF, DA_C + DA_32 + DA_DPL3);
    setDescValue(p.ldt + LDT_DATA32_INDEX, 0x00,    0xFFFFF, DA_DRW + DA_32 + DA_DPL3);
    
    p.ldtSelector = GDT_TASK_LDT_SELECTOR;
    p.tssSelector = GDT_TASK_TSS_SELECTOR;
    
    setDescValue(&gGdtInfo.entry[GDT_TASK_LDT_INDEX], (uint)&p.ldt, sizeof(p.ldt)-1, DA_LDT + DA_DPL0);
    setDescValue(&gGdtInfo.entry[GDT_TASK_TSS_INDEX], (uint)&p.tss, sizeof(p.tss)-1, DA_386TSS + DA_DPL0);
    
    InitInterrupt();
    EnableTimer();

    printChar('\n');
    RunProcess(&p);
}
