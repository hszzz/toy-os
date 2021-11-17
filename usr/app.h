#ifndef APP_H
#define APP_H

#include "types.h"

struct Application
{
    const char* name;
    void (*tentry)();
    ushort priority;
};

#endif // APP_H
