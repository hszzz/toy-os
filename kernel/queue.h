#ifndef QUEUE_H_
#define QUEUE_H_

#include "list.h"

struct QueueHead
{
    int len;
    struct ListHead head;
};

void QueueInit(struct QueueHead* queue);
void QueuePush(struct QueueHead* queue, struct ListHead* node);
void QueuePop(struct QueueHead* queue);

struct ListHead* QueueFront(struct QueueHead* queue);
int QueueIsEmpty(struct QueueHead* queue);
int QueueIsContained(struct QueueHead* queue, struct ListHead* node);
int QueueLength(struct QueueHead* queue);

void QueueRotate(struct QueueHead* queue);

#endif // QUEUE_H_
