#ifndef TASK_H
#define TASK_H

#include "kernel.h"
#include "queue.h"
#include "list.h"

typedef struct
{
	uint gs;
	uint fs;
	uint es;
	uint ds;
	uint edi;
	uint esi;
	uint ebp;
	uint kesp;
	uint ebx;
	uint edx;
	uint ecx;
	uint eax;
	uint raddr;
	uint eip;
	uint cs;
	uint eflags;
	uint esp;
	uint ss;
} RegValue;

typedef struct 
{
	uint   previous;
	uint   esp0;
	uint   ss0;
	uint   unused[22];
	ushort reserved;
	ushort iomb;
} TSS;

typedef struct
{
	RegValue   rv;
	Descriptor ldt[3];
	ushort     ldtSelector;
	ushort     tssSelector;
	void (*tentry)();
	uint       id;
	char       name[8];
	byte       stack[512];
    // priority
    ushort current;
    ushort total; // 256 - priority
} Task;

struct TaskNode
{
    Task task;
    struct ListHead head;
};

void InitTaskModule();
void LaunchTask();
void Schedule();
void TaskExit();

#endif // TASK_H

