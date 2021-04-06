#include "kprint.h"

static int printPosW = 0;
static int printPosH = 0;
static int printColor = PRINT_WHITE;

int setPrintPosition(int w, int h)
{
	int ret = 0;

	ret = ((0 <= w) && (w <= SCREEN_WIDTH) && (0 <= h) && (h <= SCREEN_HEIGHT));
	if (ret)
	{
		printPosW = w;
		printPosH = h;
		
		unsigned short bx = SCREEN_WIDTH * h + w;
        asm volatile(
            "movw %0,      %%bx\n"
            "movw $0x03D4, %%dx\n"
            "movb $0x0E,   %%al\n"
            "outb %%al,    %%dx\n"
            "movw $0x03D5, %%dx\n"
            "movb %%bh,    %%al\n"
            "outb %%al,    %%dx\n"
            "movw $0x03D4, %%dx\n"
            "movb $0x0F,   %%al\n"
            "outb %%al,    %%dx\n"
            "movw $0x03D5, %%dx\n"
            "movb %%bl,    %%al\n"
            "outb %%al,    %%dx\n"
            :
            : "r"(bx)
            : "ax", "bx", "dx"
        );
	}
	return ret;
}

void setPrintColor(PrintColor color) 
{
	printColor = color;
}

void clearScreen()
{
	int w = 0;
	int h = 0;
	setPrintPosition(0, 0);

	for (w=0; w<SCREEN_WIDTH; w++)
	{
		for (h=0; h<SCREEN_HEIGHT; h++)
		{
			printChar(' ');
		}
	}
	setPrintPosition(0, 0);
}

int printChar(char c)
{
	int ret;

	if ((c == '\n') || (c == '\r'))
	{
		ret = setPrintPosition(0, printPosH + 1);
	}
	else
	{
		int w = printPosW;
		int h = printPosH;

		if ((0 <= w) && (w <= SCREEN_WIDTH) && (0 <= h) && (h <= SCREEN_HEIGHT))
		{
			int edi = (SCREEN_WIDTH * h + w) * 2; 
			char ah = printColor;
			char al = c;

			asm volatile
			(
				"movl %0, %%edi\n"
				"movb %1, %%ah\n"
				"movb %2, %%al\n"
				"movw %%ax, %%gs:(%%edi)\n"
				:
				: "r"(edi), "r"(ah), "r"(al)
				: "ax", "edi"
			);

			w++;

			if (w == SCREEN_WIDTH)
			{
				w = 0;
				h = h + 1;
			}

			ret = 1;
		}

		setPrintPosition(w, h);
	}

	return ret;
}

int printString(const char* s)
{
	int ret = 0;

	if (s != NULL)
	{
		while (*s)
		{
			ret += printChar(*s++);
		}
	}
	else
	{
		ret = -1;
	}

	return ret;
}

int printInt16(int n)
{
	int i = 0;
	char hex[11] = {'0', 'x', 0};
	for (i=9; i>=2; i--)
	{
		int p = n & 0xF; // low 4 bits

		if (p < 10)
		{
			hex[i] = '0' + p;
		}
		else
		{
			hex[i] = 'A' + p - 10;
		}

		n = n >> 4;
	}

	return printString(hex);
}

int printInt10(int n)
{
	int ret = 0;

	if (n < 0) 
	{
		printChar('-');
		n = -n;
		ret += printInt10(n);
	}
	else
	{
		if (n < 10)
		{
			ret += printChar('0' + n);
		}
		else
		{
			printInt10(n / 10);
			printInt10(n % 10);
		}
	}

	return ret;
}

