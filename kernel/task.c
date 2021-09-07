#include "task.h"
#include "utility.h"
#include "kprint.h"

extern void (* const RunTask)(volatile Task* t);
extern void (* const LoadTask)(volatile Task* t);

void (* const RunTask)(volatile Task* t);
void (* const LoadTask)(volatile Task* t);

volatile Task* gTaskAddr = NULL;
static struct QueueHead TaskQueue;
static struct TaskNode TaskQueueBuffer[16];
TSS gTSS = {0};

typedef struct QueueHead Queue;

static Queue gFreeTask = {0};
static Queue gReadyTask = {0};
static Queue gRunningTask = {0};
static Queue gWaittingTask = {0};

static void TaskExit()
{
   asm volatile(
        "movl  $1, %eax \n"
        "int   $0x80   \n"
   );
}

static void TaskEntry()
{
    if (gTaskAddr)
    {
        gTaskAddr->tentry();
    }

    TaskExit();
    while (1);
}

void TaskA()
{
    int i = 0;
    
    SetPrintPosition(0, 19);
    
    PrintString("Task A: ");
    
    while (i<10)
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

void TaskD()
{
    char buf[] = "task d is running ...";
    int i = 0;

    SetPrintPosition(0, 22);

    PrintString("Task D: ");

    while (1)
    {
        if (i == sizeof buf - 1)
        {
            SetPrintPosition(8, 22);
            for (int j=0; j<sizeof buf; ++j)
            {
                PrintChar(' ');
            }
        }

        SetPrintPosition(8 + i, 22);
        PrintChar(buf[i]);
        i = (i + 1) % sizeof buf;
        Delay(1);
    }
}

void TaskE()
{
    static char buf[] = "hello world";
    uint i = 0;

    SetPrintPosition(0, 23);

    PrintString("Task E: ");

    SetPrintPosition(8, 23);
    while (1)
    {
        if (i == sizeof(buf) - 1)
        {
            SetPrintPosition(8, 23);
            PrintString("           ");
        }

        SetPrintPosition(8 + i, 23);
        PrintChar(buf[i]);
        i = (i + 1) % sizeof(buf);
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
    t->rv.eip = (uint)TaskEntry;
    t->rv.eflags = 0x3202;

    t->tentry = entry;

    SetDescValue(t->ldt + LDT_GRAPHICS_INDEX, 0xB8000, 0x07FFF, DA_DRWA + DA_32 + DA_DPL3);
    SetDescValue(t->ldt + LDT_CODE32_INDEX,   0x00,    0xFFFFF, DA_C    + DA_32 + DA_DPL3);
    SetDescValue(t->ldt + LDT_DATA32_INDEX,   0x00,    0xFFFFF, DA_DRW  + DA_32 + DA_DPL3);

    t->ldtSelector = GDT_TASK_LDT_SELECTOR;
    t->tssSelector = GDT_TASK_TSS_SELECTOR;
}

static void InitTaskTss(volatile Task* t)
{
    gTSS.ss0 = GDT_DATA32_FLAT_SELECTOR;
    gTSS.esp0 = (uint)&t->rv + sizeof(t->rv);
    gTSS.iomb = sizeof(TSS);

    SetDescValue(&gGdtInfo.entry[GDT_TASK_LDT_INDEX], (uint)&t->ldt, sizeof(t->ldt) - 1, DA_LDT + DA_DPL0);
}

void InitTasks()
{
    SetDescValue(&gGdtInfo.entry[GDT_TASK_TSS_INDEX], (uint)&gTSS,   sizeof(gTSS) - 1,   DA_386TSS + DA_DPL0);

	InitTask(&TaskQueueBuffer[0].task, TaskA);
    InitTask(&TaskQueueBuffer[1].task, TaskB);
    InitTask(&TaskQueueBuffer[2].task, TaskC);
    InitTask(&TaskQueueBuffer[3].task, TaskD);
    InitTask(&TaskQueueBuffer[4].task, TaskE);

    QueueInit(&TaskQueue);

    for (int i=0; i<5; ++i)
    {
        QueuePush(&TaskQueue, &TaskQueueBuffer[i].head);
    }
}

void LaunchTask()
{
    gTaskAddr = &QueueEntry(QueueFront(&TaskQueue), struct TaskNode, head)->task;
    InitTaskTss(gTaskAddr);
    RunTask(gTaskAddr);
}

void Schedule()
{
    gTaskAddr = &QueueEntry(QueueFront(&TaskQueue), struct TaskNode, head)->task;
    QueueRotate(&TaskQueue);
    InitTaskTss(gTaskAddr);
    LoadTask(gTaskAddr);
}
