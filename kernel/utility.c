#include "utility.h"

void delay(int n)
{
	while (n > 0)
	{
		int i = 0;
		int j = 0;

		for (i; i<1000; i++)
		{
			for (j; j<1000; j++)
			{
				asm volatile("nop\n");
			}
		}
	}
}
