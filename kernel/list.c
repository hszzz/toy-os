#include "list.h"
#include "const.h"

void ListInit(struct ListHead* list)
{
    list->prev = list;
    list->next = list;
}

static void _ListAdd(struct ListHead* prev, struct ListHead* next, struct ListHead* node)
{
    node->prev = prev;
    node->next = next;
    prev->next = node;
    next->prev = node;
}

void ListAdd(struct ListHead* list, struct ListHead* node)
{
    _ListAdd(list, list->next, node);
}

void ListAddTail(struct ListHead* list, struct ListHead* node)
{
    _ListAdd(list->prev, list, node);
}

static void _ListDel(struct ListHead* prev, struct ListHead* next)
{
    prev->next = next;
    next->prev = prev;
}

void ListDel(struct ListHead* node)
{
    _ListDel(node->prev, node->next);

    node->prev = NULL;
    node->next = NULL;
}

void ListReplace(struct ListHead* old, struct ListHead* node)
{
    node->prev = old->prev;
    node->next = old->next;
    old->prev->next = node;
    old->next->prev = node;

    old->prev = NULL;
    old->next = NULL;
}

int ListIsLast(struct ListHead* list, struct ListHead* node)
{
    return node->next == list;
}

int ListIsEmpty(struct ListHead* list)
{
    return list->next == list;
}
