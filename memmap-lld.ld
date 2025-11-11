
/* start of vector table */
ENTRY( _start )

/* size of the stacj */
__stack_size = __STACK_SIZE__;
PROVIDE( _stack_size = __stack_size );

/* memory size */
MEMORY
{
	FLASH (rx) : ORIGIN = 0x00000000, LENGTH = __FLASH_SIZE__
	RAM (xrw)  : ORIGIN = 0x20000000, LENGTH = __RAM_SIZE__
}

SECTIONS
{
	/* initialize - vector table and reset handler */
	.init :
	{
		KEEP(*(.boot))	/* boot loader */
		_sinit = .;	/* init start */
		. = ALIGN(4);
		KEEP(*(SORT_NONE(.init)))
		. = ALIGN(4);
		_einit = .;	/* init end */
	} >FLASH AT>FLASH

	/* main program code and read-only data in Flash */
	.text :
	{
		. = ALIGN(4);
		*(.text)
		*(.text.*)
		*(.rodata)
		*(.rodata*)
		*(.gnu.linkonce.t.*)
		. = ALIGN(4);
	} >FLASH AT>FLASH

	.fini :
	{
		KEEP(*(SORT_NONE(.fini)))
		. = ALIGN(4);
	} >FLASH AT>FLASH

	/* end of program code sections */
	PROVIDE( _etext = . );
	PROVIDE( _eitcm = . );

	/* table of pre-initialize functions */
	.preinit_array :
	{
		PROVIDE_HIDDEN (__preinit_array_start = .);
		KEEP (*(.preinit_array))
		PROVIDE_HIDDEN (__preinit_array_end = .);
	} >FLASH AT>FLASH

	.init_array :
	{
		PROVIDE_HIDDEN (__init_array_start = .);
		KEEP (*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))
		KEEP (*(.init_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .ctors))
		PROVIDE_HIDDEN (__init_array_end = .);
	} >FLASH AT>FLASH

	.fini_array :
	{
		PROVIDE_HIDDEN (__fini_array_start = .);
		KEEP (*(SORT_BY_INIT_PRIORITY(.fini_array.*) SORT_BY_INIT_PRIORITY(.dtors.*)))
		KEEP (*(.fini_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .dtors))
		PROVIDE_HIDDEN (__fini_array_end = .);
	} >FLASH AT>FLASH

	/* global contructors */
	.ctors :
	{
      /* gcc uses crtbegin.o to find the start of
         the constructors, so we make sure it is
         first.  Because this is a wildcard, it
         doesn't matter if the user does not
         actually link against crtbegin.o; the
         linker won't look for a file to match a
         wildcard.  The wildcard also means that it
         doesn't matter which directory crtbegin.o
         is in.  */
		KEEP (*crtbegin.o(.ctors))
		KEEP (*crtbegin?.o(.ctors))
      /* We don't want to include the .ctor section from
         the crtend.o file until after the sorted ctors.
         The .ctor section from the crtend file contains the
         end of ctors marker and it must be last */
		KEEP (*(EXCLUDE_FILE (*crtend.o *crtend?.o ) .ctors))
		KEEP (*(SORT(.ctors.*)))
		KEEP (*(.ctors))
	} >FLASH AT>FLASH

	/* global destructors */
	.dtors :
	{
		KEEP (*crtbegin.o(.dtors))
		KEEP (*crtbegin?.o(.dtors))
		KEEP (*(EXCLUDE_FILE (*crtend.o *crtend?.o ) .dtors))
		KEEP (*(SORT(.dtors.*)))
		KEEP (*(.dtors))
	} >FLASH AT>FLASH

	/* start of initialized data in RAM (destination address) */
	.dalign :
	{
		. = ALIGN(4);
		PROVIDE(_data_vma = .);	/* virtual memory address of initialized data in RAM (destination address) */
	} >RAM AT>FLASH

	/* start of initialized data in Flash (source address) */
	.dlalign :
	{
		. = ALIGN(4);
		PROVIDE(_data_lma = .);	/* load memory address of initialized data in Flash (source address) */
	} >FLASH AT>FLASH

	/* initialized data in RAM, critical functions in RAM */
	.data :
	{
		. = ALIGN(4);
		*(.gnu.linkonce.r.*)
		*(.data .data.*)
		*(.gnu.linkonce.d.*)
		. = ALIGN(8);
		PROVIDE( __global_pointer$ = . + 0x800 );	/* pointer to global data */
		*(.sdata .sdata.*)
		*(.sdata2*)
		*(.gnu.linkonce.s.*)
		. = ALIGN(8);
		*(.srodata.cst16)
		*(.srodata.cst8)
		*(.srodata.cst4)
		*(.srodata.cst2)
		*(.srodata .srodata.*)
		*(.time_critical*)
		. = ALIGN(4);
		PROVIDE( _edata = .);	/* end of initialized data in RAM */
	} >RAM AT>FLASH

	/* end of initialized data in Flash */
	.flashalign :
	{
		PROVIDE(_sflashslot = .);
	} >FLASH AT>FLASH

	/* flash mini slots on end of flash memory */
	.flashminislot :
	{
		. = ALIGN(4);
		PROVIDE(_sflashminislot = .);
		*(.flashminislot)
		PROVIDE(_eflashminislot = .);
	} >FLASH AT>FLASH

	/* flash slots on end of flash memory */
	.flashslot :
	{
		. = ALIGN(4);
		*(.flashslot)
		PROVIDE(_eflashslot = .);
	} >FLASH AT>FLASH

	/* uninitialized data */
	.bss :
	{
		. = ALIGN(4);
		PROVIDE( _sbss = .);
		*(.sbss*)
		*(.gnu.linkonce.sb.*)
		*(.bss*)
		*(.gnu.linkonce.b.*)
		*(COMMON*)
		. = ALIGN(4);
		PROVIDE( _ebss = .);
	} >RAM

	PROVIDE( _end = _ebss);
	PROVIDE( end = . );

	/* stack in RAM - CRITICAL: Must be at TOP of RAM, not after .bss! */
	.stack ORIGIN(RAM) + LENGTH(RAM) - __stack_size - 16 :
	{
		PROVIDE( _heap_end = . );
		. = ALIGN(4);
		PROVIDE(_susrstack = . );
		. = . + __stack_size;
		PROVIDE( _eusrstack = .);
	} >RAM

	/* loader data sLoaderData - at very top of RAM */
	.loaderdata ORIGIN(RAM) + LENGTH(RAM) - 16 :
	{
		. = ALIGN(4);
		PROVIDE(_sloaderdata = . );
		. = . + 16;
		PROVIDE( _eladerdata = .);
	} >RAM

	/* Discard unwanted sections */
	/DISCARD/ :
	{
		*(.rela*)
		*(.rel*)
		*(.dynamic)
		*(.dynsym)
		*(.dynstr)
		*(.hash)
		*(.gnu.hash)
		*(.gnu.version*)
		*(.eh_frame)
		*(.note*)
	}
}
