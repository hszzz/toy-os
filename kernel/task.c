#include "task.h"
#include "utility.h"
#include "kprint.h"
#include "app.h"

extern void (* const RunTask)(volatile Task* t);
extern void (* const LoadTask)(volatile Task* t);

void (* const RunTask)(volatile Task* t);
void (* const LoadTask)(volatile Task* t);

volatile Task* gTaskAddr = NULL;
TSS gTSS = {0};

typedef struct QueueHead Queue;
#define MAX_TASK_NUM 4
#define MAX_RUNNING_NUM 2
#define MAX_READY_NUM (MAX_TASK_NUM - MAX_RUNNING_NUM)

static struct TaskNode TaskQueueBuffer[MAX_TASK_NUM];
static Queue gFreeTasks     = {0};
static Queue gReadyTasks    = {0};
static Queue gRunningTasks  = {0};
static Queue gWaittingTasks = {0};

static uint gAppToRunIndex = 0;

// idle task
static struct TaskNode gTaskIdleNode = {0};
// init task
// static struct TaskNode gTaskInitNode = {0};

static void TaskEntry()
{
    if (gTaskAddr)
    {
        gTaskAddr->tentry();
    }

    asm volatile(
    "movl  $1, %eax \n"
    "int   $0x80   \n"
    );
    // while (1);
}

void CheckQueue(Queue* queue, const char* name, int w, int h);
// idle task
void TaskIdle()
{
    while (1)
    {
        SetPrintPosition(0, 7);
        PrintString("idle task");
        CheckQueue(&gFreeTasks, "FREE",   0, 9);
        CheckQueue(&gReadyTasks, "READY", 0, 10);
        CheckQueue(&gRunningTasks, "RUNNING", 0, 11);
        /*
        asm volatile(
        "nop\n"
        );
         */
    }
}

// init task, all task's parent
void TaskInit()
{
    while (1)
    {
        SetPrintPosition(0, 8);
        PrintString("init task ...");
    }
}

static void InitTask(Task* t, const char* name, void(*entry)())
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
    StrCpy(t->name, name);

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

// Application -> task
static void CreateTask()
{
    uint num = GetAppNum();

    while ((gAppToRunIndex < num) && (QueueLength(&gReadyTasks) < MAX_READY_NUM))
    {
        struct TaskNode* task = ListEntry(QueueFront(&gFreeTasks), struct TaskNode, head);
        QueuePop(&gFreeTasks);

        if (task)
        {
            struct Application* app = GetAppInfo(gAppToRunIndex);
            InitTask(&task->task, app->name, app->tentry);
            QueuePush(&gReadyTasks, &task->head);
        }
        else
        {
            break;
        }

        ++gAppToRunIndex;
    }
}

// if no running task, idle task is running
// running queue is full, idle task will be remove
static void CheckRunningTask()
{
    if (QueueLength(&gRunningTasks) == 0)
    {
        QueuePush(&gRunningTasks, &gTaskIdleNode.head);
    }
    else if (QueueLength(&gRunningTasks) > 1)
    {
        if (QueueFront(&gRunningTasks) == &gTaskIdleNode.head)
        {
            QueuePop(&gRunningTasks);
        }
    }
}

static void ReadyToRunning()
{
    struct ListHead* node = NULL;

    if (QueueLength(&gReadyTasks) == 0)
    {
        CreateTask();
    }

    while ((QueueLength(&gReadyTasks) > 0) && (QueueLength(&gRunningTasks) < MAX_RUNNING_NUM))
    {
        node = QueueFront(&gReadyTasks);
        QueuePop(&gReadyTasks);

        QueuePush(&gRunningTasks, node);
    }
}

void InitTaskModule()
{
    QueueInit(&gFreeTasks);
    QueueInit(&gReadyTasks);
    QueueInit(&gRunningTasks);
    QueueInit(&gWaittingTasks);

    for (int i=0; i<MAX_TASK_NUM; ++i)
    {
        QueuePush(&gFreeTasks, &TaskQueueBuffer[i].head);
    }

    SetDescValue(&gGdtInfo.entry[GDT_TASK_TSS_INDEX], (uint)&gTSS, sizeof(gTSS) - 1, DA_386TSS + DA_DPL0);

    // idle task
    InitTask(&gTaskIdleNode.task, "IDLE", TaskIdle);
    // init task
    // InitTask(&gTaskInitNode.task, "INIT", TaskInit);

    // QueuePush(&gRunningTasks, &gTaskInitNode.head);
    // QueuePush(&gRunningTasks, &gTaskIdleNode.head);

    ReadyToRunning();
    CheckRunningTask();
}

void LaunchTask()
{
    gTaskAddr = &QueueEntry(QueueFront(&gRunningTasks), struct TaskNode, head)->task;
    InitTaskTss(gTaskAddr);
    RunTask(gTaskAddr);
}

void Schedule()
{
    ReadyToRunning();
    CheckRunningTask();
    QueueRotate(&gRunningTasks);
    gTaskAddr = &QueueEntry(QueueFront(&gRunningTasks), struct TaskNode, head)->task;
    InitTaskTss(gTaskAddr);
    LoadTask(gTaskAddr);
}

void CheckQueue(Queue* queue, const char* name, int w, int h)
{
    SetPrintPosition(w, h);
    PrintString(name);
    PrintString(" : len=");

    if (!QueueIsEmpty(queue))
    {
        PrintInt10(QueueLength(queue));
        PrintString(" :");
        struct ListHead* pos = NULL;
        ListForEach(pos, &queue->head)
        {
            struct TaskNode* node = ListEntry(pos, struct TaskNode, head);
            PrintString(node->task.name);
            PrintString(", ");
        }
    }
    else
    {
        PrintString("empty");
    }
}

void TaskExit()
{
    struct ListHead* node = QueueFront(&gRunningTasks);
    QueuePop(&gRunningTasks);
    QueuePush(&gFreeTasks, node);

    Schedule();
}
