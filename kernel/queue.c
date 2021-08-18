#include "queue.h"
#include "const.h"

void QueueInit(struct QueueHead* queue)
{
    queue->len = 0;
    ListInit(&queue->head);
}

void QueuePush(struct QueueHead* queue, struct ListHead* node)
{
    ListAddTail(&queue->head, node);
    queue->len++;
}

void QueuePop(struct QueueHead* queue)
{
    ListDel(queue->head.next);
    queue->len--;
}

struct ListHead* QueueFront(struct QueueHead* queue)
{
    return queue->head.next;
}

int QueueIsEmpty(struct QueueHead* queue)
{
    return queue->len == 0;
}

int QueueIsContained(struct QueueHead* queue, struct ListHead* node)
{
    int ret = 0;

    struct ListHead* pos;
    ListForEach(pos, &queue->head)
    {
        if (pos == node)
        {
            ret = 1;
            break;
        }
    }

    return ret;
}

int QueueLength(struct QueueHead* queue)
{
    return queue->len;
}

void QueueRotate(struct QueueHead* queue)
{
    struct ListHead* node = queue->head.next;
    ListDel(queue->head.next);
    ListAddTail(&queue->head, node);
}
