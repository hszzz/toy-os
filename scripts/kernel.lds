OUTPUT_FORMAT("elf32-i386")
ENTRY(_start)
phys = 0xB000;

SECTIONS
{
  .text phys : AT(phys) 
  {
    code = .;
    *(.text)
    *(.rodata)
    . = ALIGN(4096); 
  }
  .data : AT(phys + (data - code)) 
  {
    data = .;
    *(.data)
    . = ALIGN(4096); 
  }
  .stab : AT(phys + (stab - code))
  {
      stab = .;
      *(.stab)
      . = ALIGN(4096);
  }
  .stabstr : AT(phys + (stabstr - code))
  {
      stabstr = .;
      *(.stabstr)
      . = ALIGN(4096);
  }
  .bss : AT(phys + (bss - code)) 
  {
    bss = .;
    *(.bss)
    . = ALIGN(4096); 
  }

  /DISCARD/ : { *(.comment) *(.eh_frame) }
}


