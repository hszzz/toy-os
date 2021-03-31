#ifndef PRINT_H
#define PRINT_H

#include "const.h"

#define SCREEN_WIDTH  80
#define SCREEN_HEIGHT 25

typedef enum
{
	PRINT_GRAY   = 0x07,
	PRINT_BLUE   = 0x09,
	PRINT_GREEN  = 0x0A,
	PRINT_RED    = 0x0C,
	PRINT_YELLOW = 0x0E,
	PRINT_WHITE  = 0x0F
} PrintColor;

int setPosition(int w, int h);
void setPrintColor(PrintColor);

void clearScreen();

int printChar(char);
int printString();
int printInt10();
int printInt16();

#endif

