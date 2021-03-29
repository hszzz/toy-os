#include "kernel.h"
#include "print.h"

void KMain()
{
	clearScreen();
	setPrintColor(PRINT_RED);

	printString("hello toy-os!\n");
	printInt10(666);
	printInt16(666);
}
