#ifndef LIST_H_
#define LIST_H_

#include "utility.h"

struct ListHead
{
	struct ListHead* prev;
	struct ListHead* next;
};

#define ListForEach(pos, list) for ((pos)=(list)->next; (list)!=(pos); (pos)=(pos)->next)
#define ListEntry(ptr, type, member) ContainerOf(ptr, type, member)

void ListInit(struct ListHead* list);
void ListAdd(struct ListHead* list, struct ListHead* node);
void ListAddTail(struct ListHead* list, struct ListHead* node);
void ListDel(struct ListHead* node);
void ListReplace(struct ListHead* old, struct ListHead* node);

int ListIsLast(struct ListHead* list, struct ListHead* node);
int ListIsEmpty(struct ListHead* list);

#endif // LIST_H_
