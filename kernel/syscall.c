#include "syscall.h"
#include "task.h"

void _exit()
{
    TaskExit();
}
