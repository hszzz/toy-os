#include "kernel.h"

GdtInfo gGdtInfo = {0};
IdtInfo gIdtInfo = {0};

int SetDescValue(Descriptor* desc, uint base, uint limit, ushort attr)
{
	int ret = 0;

	if ((ret = (desc != NULL)))
	{
		desc->limit1       = limit & 0xFFFF;
		desc->base1        = base & 0xFFFF;
		desc->base2        = (base >> 16) & 0xFF;
		desc->attr1        = attr & 0xFF;
		desc->attr2_limit2 = ((attr >> 8) & 0xF0) | ((limit >> 16) & 0xF);
		desc->base3        = (base >> 24) & 0xFF;
	}

	return ret;
}

int GetDescValue(Descriptor* desc, uint* base, uint* limit, ushort* attr)
{
	int ret = 0;

	if ((ret = (desc && base && limit && attr)))
	{
		*base  = (desc->base3 << 24) | (desc->base2 << 16) | desc->base1;
		*limit = ((desc->attr2_limit2 & 0xF) << 16) | desc->limit1;
		*attr  = ((desc->attr2_limit2 & 0xF0) << 8) | desc->attr1;
	}

	return ret;
}

void PageConfig()
{
    uint* base = (uint*)PageDirBase;
    uint index = 0x1F000 / 0x1000 - 1;

    for (int i=0; i<=index; ++i)
    {
        uint* addr = base + i;
        uint value = *addr;
        value = value & 0xFFFFFFFD;
        *addr = value;
    }
}
