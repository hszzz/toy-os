#include "interrupt.h"
#include "kernel.h"
#include "kprint.h"
#include "const.h"
#include "task.h"
#include "utility.h"
#include "logo.h"

#include "list.h"
#include "queue.h"

typedef struct
{
    int x;
    int y;

    struct ListHead head;
} TestNode;

void TestKernelList()
{    TestNode node[3];
    struct ListHead list;
    for (int i=0; i<3; ++i)
    {
        node[i].x = i;
        node[i].y = i;

        node->head.prev = NULL;
        node->head.next = NULL;
    }

    ListInit(&list);
    PrintString("test list is empty: ");
    PrintInt10(ListIsEmpty(&list));
    PrintChar('\n');
    for (int i=0; i<3; ++i)
    {
        ListAdd(&list, &node[i].head);
    }

    struct ListHead* pos;
    /*
    ListForEach(pos, &list)
    {
        TestNode* node = ListEntry(pos, TestNode, head);
        PrintInt10(node->x);
        PrintChar(' ');
        PrintInt10(node->y);
        PrintChar('\n');
    }
    */

    TestNode node1[5];
    for (int i=0; i<5; ++i)
    {
        node1[i].x = i;
        node1[i].y = i;

        node1[i].head.prev = NULL;
        node1[i].head.next = NULL;

        ListAddTail(&list, &node1[i].head);
    }
    /*
    ListForEach(pos, &list)
    {
        TestNode* node = ListEntry(pos, TestNode, head);
        PrintInt10(node->x);
        PrintChar(' ');
        PrintInt10(node->y);
        PrintChar('\n');
    }
    */

    PrintString("test list is last: ");
    PrintInt10(ListIsLast(&list, &node1[3].head));
    PrintChar(' ');
    PrintInt10(ListIsLast(&list, &node1[4].head));
    PrintChar('\n');
    PrintString("test list is empty: ");
    PrintInt10(ListIsEmpty(&list));
    PrintChar('\n');

    ListDel(&node1[4].head);
    /*
    ListForEach(pos, &list)
    {
        TestNode* node = ListEntry(pos, TestNode, head);
        PrintInt10(node->x);
        PrintChar(' ');
        PrintInt10(node->y);
        PrintChar('\n');
    }
    */

    TestNode node2;
    node2.x = 9;
    node2.y = 9;
    node2.head.prev = NULL;
    node2.head.next = NULL;

    ListReplace(&node1[3].head, &node2.head);
    ListForEach(pos, &list)
    {
        TestNode* node = ListEntry(pos, TestNode, head);
        PrintInt10(node->x);
        PrintChar(' ');
        PrintInt10(node->y);
        PrintChar('\n');
    }
}

void TestKernelQueue()
{
    TestNode node[3];
    for (int i=0; i<3; ++i)
    {
        node[i].x = i;
        node[i].y = i;

        node[i].head.prev = NULL;
        node[i].head.next = NULL;
    }

    struct QueueHead queue;
    QueueInit(&queue);
    PrintString("test queue is empty: ");
    PrintInt10(QueueIsEmpty(&queue));
    PrintChar('\n');

    for (int i=0; i<3; ++i)
    {
        QueuePush(&queue, &node[i].head);
        PrintString("test queue length: ");
        PrintInt10(QueueLength(&queue));
        PrintChar('\n');
    }

    PrintString("test queue is empty: ");
    PrintInt10(QueueIsEmpty(&queue));
    PrintChar('\n');

    /*
    struct ListHead* pos;
    ListForEach(pos, &queue.head)
    {
        TestNode* node = ListEntry(pos, TestNode, head);
        PrintString("node ");
        PrintString(" x = ");
        PrintInt10(node->x);
        PrintString(" y = ");
        PrintInt10(node->y);
        PrintChar('\n');
    }
    */

    QueueRotate(&queue);

    for (int i=0; i<3; ++i)
    {
        struct ListHead* head = QueueFront(&queue);
        TestNode* temp = ListEntry(head, TestNode, head);

        PrintString("node ");
        PrintInt10(i);
        PrintString(" x = ");
        PrintInt10(temp->x);
        PrintString(" y = ");
        PrintInt10(temp->y);
        PrintChar('\n');

        QueuePop(&queue);
    }
    PrintInt10(QueueLength(&queue));
}

void KMain()
{
    PrintLogo();

    PrintString("GDT Entry: ");
    PrintInt16((uint)gGdtInfo.entry);
    PrintChar('\n');
    
    PrintString("GDT Size: ");
    PrintInt10((uint)gGdtInfo.size);
    PrintChar('\n');

    PrintString("IDT Entry: ");
    PrintInt16((uint)gIdtInfo.entry);
    PrintChar('\n');
    
    PrintString("IDT Size: ");
    PrintInt10((uint)gIdtInfo.size);
    PrintChar('\n');

    // TestKernelList();

    TestKernelQueue();

    // InitInterrupts();
    // InitTasks();
    // LaunchTask();
    while (1);
}

