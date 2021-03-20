# Contents

In this file compilation process is briefly explained and analysis of resulting files is given.

## Chapters

1. [Compilation process](#compilation-process)
2. [ELF file dump](#elf-file-dump)
3. [BIN file dump](#bin-file-dump)

# Compilation process

Compilation process is handled using [Makefile](../Makefile) and `make` utility. Source code is written in C; ARM architecture allows for pure C implementation of startup file, including all exception handlers. C code is compiled to object file (*src/main.c* to *build/main.o*). Linker `ld` then takes all object files as input and links final ELF file according to [linker script](../ld/stm32f030x8.ld). However, ELF file can not be directly flashed to MCU (as it contains ELF header, debug information and other components unknown to the MCU). Therefore `objcopy` utility (or more precisely `arm-none-eabi-objcopy`) is used to transform ELF file to .bin file. This file is then flashed to MCU using SWD/JTAG programmer.

Following sections gives analysis of ELF and bin files.

# ELF file dump

Throughout this document we assume `make` has been invoked and compiled files are located in `build/` folder.

## ELF and bin file distinction

[ELF](https://en.wikipedia.org/wiki/Executable_and_Linkable_Format) (executable and linkable format) file is executable file format containing compiled code. It is the final product of compiling and linking process. However, as it contains ELF header, debug symbols and other components it cannot be directly flashed to MCU. For this purpose *objcopy* utility strips it from all undesired bits and creates *bin* file, which can be bit-by-bit copied to MCU.

Having ELF file is still useful for debugging (when invoking debugger ELF file must be used as argument).

*Note: debug symbols are only present if compiled with -g option*

## ELF file inspection

Utilities *arm-none-eabi-nm* and *arm-none-eabi-objdump* can be used for ELF file inspection.

### `nm` dump

Starting with *nm* (which is a bit less descriptive):

```
> arm-none-eabi-nm build/stm32f0_baremetal.elf
080000d2 T HardFault
08000004 T InterruptVectors
080000cc T NMI
080000d8 T Reset
20000000 T _ebss
20000000 T _edata
20002000 T _estack
08000134 T _etext
20000000 T _sbss
20000000 T _sdata
080000c0 T main
08000000 T stack_initial_value
```

First column contains symbol value (corresponding to address where given function/data item is located). Address is in MCU address space (the actual address MCU will use, not offset in elf file). This is the address space MCU uses when application is executed, meaning 0x20000000 points to start of RAM, 0x08000000 points to start of flash. More information can be found in [linker script explanation](linker_script_explanation.md).

Second column shows symbol type. *T* stands for symbol in text section (that's the section executable code is located). More information can be found in `man nm`.

Third column is the symbol name. This corresponds to name of the C function, interrupt handler, data item etc.

In this case, symbols have following meaning:

* `stack_initial_value` corresponds to first dword (32-bits, first 4 B) of flash memory (address 0x08000000). This is where ARM Cortex-M processor expects initial value for MSP (master stack pointer). Name of this symbol and value assignment is defined in [startup\_stm32f030x.c](../src/startup_stm32f030x.c). However actual value (`_estack`, end of stack) is calculated in [linker script](../ld/stm32f030x8.ld) as end (highest address) of RAM (as stack grows to lower addresses with each `push` instruction)
* InterruptVectors symbol corresponds to start of interrupt vector table. Table itself has data type defined in [interrupt\_vectors.h](../include/interrupt_vectors.h) as `InterruptVectors_t`. Actual variable `InterruptVectors` is initialized in [startup\_stm32f030x.c](../src/startup_stm32f030x.c). This is just a bunch of pointers to exception/interrupt handlers (including `Reset`). As most of exception handlers are not defined, they point to zero address (probably poor practice, better would be to point to catch-all exception with infinite loop or breakpoint)
* `HardFault`, `NMI` (non-maskable interrupt) and `Reset` are actual exception/interrupt service routines (in in ARM terminology, *interrupt* is a subset of *exception*). They are implemented as C function in [startup\_stm32f030x.c](../src/startup_stm32f030x.c). Addresses in first column are actual places in memory where these functions are located (their first instruction, to be exact).
* `_ebss` is end of bss section (section in RAM for uninitialized variables, which are zero-filled in `Reset` handler)
* `_sbss` is start of bss section, therefore `_ebss`-`_sbss` gives size of bss section
* `_edata` is end of data section, where static and initialized variables are located. The catch here is that data section has two different addresses (LMA and VMA), see [linker script explanation](linker_script_explanation.md). Short version is that since initialized variables have some value, they have to be stored in flash (LMA address). On runtime, they have to be copied to RAM (VMA address) - copying itself is done in `Reset` handler. After data has been copied to RAM, application (usually) only works with VMA address.
* `_sdata` is the start of data section *in RAM* (VMA address)
* `_estack` is the highest address of RAM (end of RAM), used as initial value for stack pointer
* `_etext` is end of text section (where executable code is stored). Start of data section (*in flash memory*, LMA address) also starts at this address. Note that this is silently assumed - you could probably break this with incorrectly written linker script

**To clarify the confusion with dual addressing data section:**

From [ld documentation](https://sourceware.org/binutils/docs/ld/Basic-Script-Concepts.html):

> Every loadable or allocatable output section has two addresses. The first is the VMA, or virtual memory address. This is the address the section will have when the output file is run. The second is the LMA, or load memory address. This is the address at which the section will be loaded. In most cases the two addresses will be the same. An example of when they might be different is when a data section is loaded into ROM, and then copied into RAM when the program starts up (this technique is often used to initialize global variables in a ROM based system). In this case the ROM address would be the LMA, and the RAM address would be the VMA.

### `objdump` dump

```
> arm-none-eabi-objdump -x build/stm32f0_baremetal.elf
build/stm32f0_baremetal.elf:     file format elf32-littlearm
build/stm32f0_baremetal.elf
architecture: armv6s-m, flags 0x00000112:
EXEC_P, HAS_SYMS, D_PAGED
start address 0x08000000

Program Header:
    LOAD off    0x00010000 vaddr 0x08000000 paddr 0x08000000 align 2**16
         filesz 0x00000134 memsz 0x00000134 flags r-x
private flags = 5000200: [Version5 EABI] [soft-float ABI]

Sections:
Idx Name          Size      VMA       LMA       File off  Algn
  0 .text         00000134  08000000  08000000  00010000  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
  1 .debug_info   000003e0  00000000  00000000  00010134  2**0
                  CONTENTS, READONLY, DEBUGGING
  2 .debug_abbrev 00000123  00000000  00000000  00010514  2**0
                  CONTENTS, READONLY, DEBUGGING
  3 .debug_aranges 00000040  00000000  00000000  00010637  2**0
                  CONTENTS, READONLY, DEBUGGING
  4 .debug_line   000000f0  00000000  00000000  00010677  2**0
                  CONTENTS, READONLY, DEBUGGING
  5 .debug_str    0000045c  00000000  00000000  00010767  2**0
                  CONTENTS, READONLY, DEBUGGING
  6 .comment      00000021  00000000  00000000  00010bc3  2**0
                  CONTENTS, READONLY
  7 .ARM.attributes 0000002c  00000000  00000000  00010be4  2**0
                  CONTENTS, READONLY
  8 .debug_frame  00000094  00000000  00000000  00010c10  2**2
                  CONTENTS, READONLY, DEBUGGING
SYMBOL TABLE:
08000000 l    d  .text	00000000 .text
00000000 l    d  .debug_info	00000000 .debug_info
00000000 l    d  .debug_abbrev	00000000 .debug_abbrev
00000000 l    d  .debug_aranges	00000000 .debug_aranges
00000000 l    d  .debug_line	00000000 .debug_line
00000000 l    d  .debug_str	00000000 .debug_str
00000000 l    d  .comment	00000000 .comment
00000000 l    d  .ARM.attributes	00000000 .ARM.attributes
00000000 l    d  .debug_frame	00000000 .debug_frame
00000000 l    df *ABS*	00000000 startup_stm32f030x.c
00000000 l    df *ABS*	00000000 main.c
08000134 g       .text	00000000 _etext
20000000 g       .text	00000000 _sbss
080000cc g     F .text	00000006 NMI
20000000 g       .text	00000000 _sdata
20000000 g       .text	00000000 _ebss
08000004 g     O .text	000000bc InterruptVectors
080000d8 g     F .text	0000005c Reset
080000c0 g     F .text	0000000c main
08000000 g     O .text	00000004 stack_initial_value
20002000 g       .text	00000000 _estack
080000d2 g     F .text	00000006 HardFault
20000000 g       .text	00000000 _edata
```

Here we can see more sections, including debug. These are not included in final binary (*bin* file). Fifth column denotes length of the function/data item (we can for example see that `stack_initial_value` is 4 bytes long, as expected.

# BIN file dump

```
> hexdump -C build/stm32f0_baremetal.bin

00000000  00 20 00 20 d9 00 00 08  cd 00 00 08 d3 00 00 08  |. . ............|
00000010  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
*
000000c0  80 b5 00 af 01 be c0 46  bd 46 80 bd 80 b5 00 af  |.......F.F......|
000000d0  fe e7 80 b5 00 af fe e7  80 b5 84 b0 00 af 10 4b  |...............K|
000000e0  fb 60 10 4b bb 60 07 e0  fa 68 13 1d fb 60 bb 68  |.`.K.`...h...`.h|
000000f0  19 1d b9 60 12 68 1a 60  ba 68 0b 4b 9a 42 f3 d3  |...`.h.`.h.K.B..|
00000100  0a 4b 7b 60 04 e0 7b 68  1a 1d 7a 60 00 22 1a 60  |.K{`..{h..z`.".`|
00000110  7a 68 07 4b 9a 42 f6 d3  ff f7 d2 ff fe e7 c0 46  |zh.K.B.........F|
00000120  34 01 00 08 00 00 00 20  00 00 00 20 00 00 00 20  |4...... ... ... |
00000130  00 00 00 20                                       |... |
00000134
```

## Initial stack pointer value

ARM Cortex-M expects initial stack pointer value to be stored in first 4 bytes of flash memory (address 0x08000000, this corresponds to first 4 bytes of bin file). This value has symbol name `initial_stack_value` in ELF file dump. As (in this case) byte order is little-endian, first four bytes `00 20 00 20` actually have the value of 0x20002000, which is RAM starting address (0x20000000) plus RAM length (8 KB = 0x00002000 B).

## Vector table

Following 47\*4 B = 188 B belong to vector table. Each vector is 4 B long and points to exception handler for corresponding exception. C type definition for vector table can be found in [interrupt\_vectors.h](../include/interrupt_vectors.h). Initialization of the table can be found in [startup\_stm32f030x.c](../src/startup_stm32f030x.c). Only first three interrupts are implemented: Reset, NMI and HardFault. Note that more robust implementation should weak link all unused exceptions to some default handler (with infinite loop) to catch all exceptions. Should some non-implemented exception come, having address of 0x00000000 would probably crash the system.

### Reset handler

Next four bytes `d9 00 00 08` are `Reset` handler address, which is 0x080000d9. As we can see in `objdump` output above, actual location of `Reset` handler is 0x080000d8. Last bit differs because it is used to indicate *Thumb interworking* (switching between A32 (ARM) and T32 (Thumb) instructions). As ARMv6-M only supports Thumb, last bit of all exception handler vector (and, generally, anything that goes into PC (program counter) register) is always set to 1. All instructions write bits [31:1]:'0' when updating PC (taken from [ARMv6-M Architecture Reference Manual](https://developer.arm.com/documentation/ddi0419/latest) section 4.1.1).

### NMI handler

Four bytes 0x080000cd correspond to 0x080000cc in elf dump.

### HardFault handler

Four bytes 0x080000d3 correspond to 0x080000d2 in elf dump.

### Rest of the vector table

All the other vectors are zero-filled (again, this is probably not good idea for production - unused exceptions should be weak links to some catch-all exception).
