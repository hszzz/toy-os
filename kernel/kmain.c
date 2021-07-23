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
    
    setPrintPosition(0, 16);
    
    printString("Task A: ");
    
    while(1)
    {
        setPrintPosition(8, 16);
        printChar('A' + i);
        i = (i + 1) % 26;
        Delay(1);
    }
}

void KMain()
{
	printLogo();

    uint base = 0;
    uint limit = 0;
    ushort attr = 0;
    int i = 0;
    
    printString("GDT Entry: ");
    printInt16((uint)gGdtInfo.entry);
    printChar('\n');
    
    for(i=0; i<gGdtInfo.size; i++)
    {
        getDescValue(gGdtInfo.entry + i, &base, &limit, &attr);
    
        printInt16(base);
        printString("    ");
    
        printInt16(limit);
        printString("    ");
    
        printInt16(attr);
        printChar('\n');
    }
    
    printString("runProcess: ");
    printInt16((uint)RunProcess);
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
    p.tss.esp0 = 0;
    p.tss.iomb = sizeof(p.tss);
    
    setDescValue(p.ldt + LDT_GRAPHICS_INDEX,  0xB8000, 0x07FFF, DA_DRWA + DA_32 + DA_DPL3);
    setDescValue(p.ldt + LDT_CODE32_INDEX, 0x00,    0xFFFFF, DA_C + DA_32 + DA_DPL3);
    setDescValue(p.ldt + LDT_DATA32_INDEX, 0x00,    0xFFFFF, DA_DRW + DA_32 + DA_DPL3);
    
    p.ldtSelector = GDT_TASK_LDT_SELECTOR;
    p.tssSelector = GDT_TASK_TSS_SELECTOR;
    
    setDescValue(&gGdtInfo.entry[GDT_TASK_LDT_INDEX], (uint)&p.ldt, sizeof(p.ldt)-1, DA_LDT + DA_DPL0);
    setDescValue(&gGdtInfo.entry[GDT_TASK_TSS_INDEX], (uint)&p.tss, sizeof(p.tss)-1, DA_386TSS + DA_DPL0);
    
    printString("Stack Bottom: ");
    printInt16((uint)p.stack);
    printString("    Stack Top: ");
    printInt16((uint)p.stack + sizeof(p.stack));
    
    printChar('\n');

    RunProcess(&p);
}
