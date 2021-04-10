#include "kernel.h"
#include "kprint.h"

void KMain()
{
	printString("toy-os\n");
    uint base = 0;
    uint limit = 0;
    ushort attr = 0;
    int i = 0;
    
    printString("GDT Entry: ");
    printInt16((uint)gGdtInfo.entry);
    printChar('\n');
    
    for(i=0; i<gGdtInfo.size; i++)
    {
        getDescValue(gGdtInfo.entry + i, &base, &limit, &attr);
    
        printInt16(base);
        printString("    ");
    
        printInt16(limit);
        printString("    ");
    
        printInt16(attr);
        printChar('\n');
    }
	
}
