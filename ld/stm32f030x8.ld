MEMORY
{
  rom (rx)  : ORIGIN = 0x08000000, LENGTH = 64K
  ram (rwx) : ORIGIN = 0x20000000, LENGTH = 8K
}

_estack = ORIGIN(ram) + LENGTH(ram); /* ram end */

SECTIONS
{
	.text :
	{
		KEEP(*(.stack_init_value))
		KEEP(*(.isr_vector_table))
		*(.text*)
		*(.rodata*)
		_etext = .;

	} > rom

	.data : AT(_etext) /* LMA */
	{
		_sdata = .;
		*(.data*)
		_edata = .;

	} > ram

	.bss (NOLOAD):
	{
		_sbss = .;
		*(.bss*)
		*(COMMON)
		_ebss = .;
	} > ram
}
