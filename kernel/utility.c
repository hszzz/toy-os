#include "utility.h"

void Delay(int n)
{
	while (n > 0)
	{
		int i = 0;
		int j = 0;

		for (i=0; i<1000; i++)
		{
			for (j=0; j<1000; j++)
			{
                asm volatile ("nop\n");
			}
		}
		
		n--;
	}
}

char* StrCpy(char* dst, const char* src)
{
    char* ret = dst;

    while ((*dst++ = *src++) != '\0');

    return ret;
}
