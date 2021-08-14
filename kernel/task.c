#include "task.h"
#include "utility.h"
#include "kprint.h"

/*
void (* const RunTask)(volatile Task* t);// = NULL;
void (* const LoadTask)(volatile Task* t);// = NULL;
*/

extern void (* const RunTask)(volatile Task* t);
extern void (* const LoadTask)(volatile Task* t);

void (* const RunTask)(volatile Task* t);
void (* const LoadTask)(volatile Task* t);

volatile Task* gTaskAddr = NULL;
Task p  = {0};
Task p1 = {0};

int index = 0;
Task task[3] = { 0 };

TSS gTSS = {0};

void TaskA()
{
    int i = 0;
    
    SetPrintPosition(0, 19);
    
    PrintString("Task A: ");
    
    while (1)
    {
        SetPrintPosition(8, 19);
        PrintChar('A' + i);
        PrintChar(' ');
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
        PrintChar(' ');
        i = (i + 1) % 10;
        Delay(1);
    }
}

void TaskC()
{
    int i = 0;
    
    SetPrintPosition(0, 21);
    
    PrintString("Task C: ");
    
    while (1)
    {
        SetPrintPosition(8, 21);
        PrintChar('a' + i);
        PrintChar(' ');
        i = (i + 1) % 26;
        Delay(1);
    }
}

static void InitTask(Task* t, void(*entry)())
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

void InitTasks()
{
	/*
    InitTask(&p1, TaskB);
    InitTask(&p,  TaskA);
	*/
	InitTask(&task[1], TaskB);
	InitTask(&task[2], TaskC);
	InitTask(&task[0], TaskA);
}

void LaunchTask()
{
    gTaskAddr = &task[0];
    RunTask(gTaskAddr);
}

void Schedule()
{
    // gTaskAddr = (gTaskAddr == &p) ? &p1 : &p;
    gTaskAddr = &task[index++];

	index %= 3;

    gTSS.ss0 = GDT_DATA32_FLAT_SELECTOR;
    gTSS.esp0 = (uint)&gTaskAddr->rv.gs + sizeof(RegValue);

    SetDescValue(&gGdtInfo.entry[GDT_TASK_LDT_INDEX], (uint)&gTaskAddr->ldt, sizeof(gTaskAddr->ldt) - 1, DA_LDT + DA_DPL0);

    LoadTask(gTaskAddr);
}

