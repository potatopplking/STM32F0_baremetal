# About this project

Bare-metal STM32F0x project (ARM Cortex-M0). Contains everything you need to get STM32F0x to main(). Since this project was made for educational purposes, it aims to be as simple as possible.

Startup code is written in pure C. It does not use ARM CMSIS.

Primary source for this project was [Zero to main() series](https://interrupt.memfault.com/blog/zero-to-main-1) on [interrupt.memfault.com](https://interrupt.memfault.com).

Project was tested on Nucleo F030R8 (using MCU STM32F030R8T6).

# Prerequisities

* STM32F030 nucleo or stand-alone MCU and SWD/JTAG programmer (different MCU than STM32F0 may be used, but requires changes to code, see [instructions](#modifying-for-other-mcus))
* Compiler (arm-none-eabi-gcc) and linker (arm-none-eabi-ld) (get it using your package manager or use official [ARM GNU toolchain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads))
* Flashing utility ([st-flash](https://github.com/stlink-org/stlink/tree/master) or official [ST flashing utility](https://www.st.com/en/development-tools/stsw-link004.html))

# Usage

Connect your SWD/JTAG debugger to target MCU and host computer. Then execute:

## Compiling

```
git clone https://github.com/potatopplking/STM32F0_baremetal.git
cd STM32F0_baremetal
make
```

Resulting *elf* and *bin* file should be in `build/` folder (use *bin* file for st-flash utility and *elf* file for gdb).

## Flashing

Assuming you have st-flash utility installed and SWD/JTAG programmer (e.g. ST-LINK) connected to your computer:

```
make flash
```

## Debugging

As code by itself doesn't do much, debugger may be used to verify that application works as expected:

```
> make debug
st-util & arm-none-eabi-gdb build/stm32f0_baremetal.elf
st-util 1.6.0
GNU gdb (GNU Arm Embedded Toolchain 10-2020-q4-major) 10.1.90.20201028-git
...
Reading symbols from build/stm32f0_baremetal.elf...
(gdb) 2021-03-20T11:07:34 INFO common.c: Loading device parameters....
2021-03-20T11:07:34 INFO common.c: Device connected is: F0 device, id 0x20006440
2021-03-20T11:07:34 INFO common.c: SRAM size: 0x2000 bytes (8 KiB), Flash: 0x10000 bytes (64 KiB) in pages of 1024 bytes
2021-03-20T11:07:34 INFO gdb-server.c: Chip ID is 00000440, Core ID is  0bb11477.
2021-03-20T11:07:34 INFO gdb-server.c: Listening at *:4242...

(gdb) target remote :4242
Remote debugging using :4242
2021-03-20T11:07:46 INFO gdb-server.c: Found 4 hw breakpoint registers
2021-03-20T11:07:46 INFO gdb-server.c: GDB connected.
Reset () at src/startup_stm32f030x.c:31
31	{
(gdb) 
(gdb) c
Continuing.

Program received signal SIGTRAP, Trace/breakpoint trap.
main () at src/main.c:4
4		__asm("bkpt 1");
(gdb)
```

Program execution should halt at breakpoint instruction (*bkpt*) located in main(). Feel free to delete it and replace it with your own code.

# Modifying for other MCUs

You will need to:

* modify FLASH and RAM size in linker script
* if architecture other than Cortex-M0 is used, modify MCU\_SPEC variable in Makefile
* if interrupt vector table differs from the one used in STM32F030x, modify it in file interrupt\_vectors.h

# License

You are free to use and modify this project in any legal way you want. Please don't sue me if your STM32F0x turns into heating element and starts emitting large quantities of black smoke.
