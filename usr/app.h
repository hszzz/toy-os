#ifndef APP_H
#define APP_H

#include "types.h"

struct Application
{
    const char* name;
    void (*tentry)();
    ushort priority;
};

void InitAppModule();
struct Application* GetAppInfo(uint index);
uint GetAppNum();

#endif // APP_H
