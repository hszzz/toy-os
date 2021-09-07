#ifndef APP_H
#define APP_H

struct Application
{
    char* name;
    void (*tentry)();
};

#endif // APP_H
