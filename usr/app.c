#include "app.h"

#include "kprint.h"
#include "utility.h"

#define MAX_APP_NUM 32
static struct Application gApps[MAX_APP_NUM] = {0};
static uint gAppNum = 0;

// applications
void TaskA();
void TaskB();
void TaskC();
void TaskD();
void TaskE();

void RegisterApplication(const char* name, void(*entry)())
{
    struct Application* app = &gApps[gAppNum];
    app->name = name;
    app->tentry = entry;

    gAppNum += 1;
}

void InitAppModule()
{
    RegisterApplication("task a", TaskA);
    RegisterApplication("task b", TaskB);
    RegisterApplication("task c", TaskC);
    RegisterApplication("task d", TaskD);
    RegisterApplication("task e", TaskE);
}

struct Application* GetAppInfo(uint index)
{
    struct Application* app = NULL;

    if ((index < MAX_APP_NUM) && (index < gAppNum))
    {
        app = &gApps[index];
    }

    return app;
}

uint GetAppNum()
{
    return gAppNum;
}

// applications
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

    while (i < 20)
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
