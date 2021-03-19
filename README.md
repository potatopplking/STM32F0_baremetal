# About this project

Bare-metal STM32F0x project (ARM Cortex-M0). Contains everything you need to get STM32F0x to main(). Since this project was made for educational purposes, it aims to be as simple as possible.

Startup code is written in pure C. It does not use ARM CMSIS.

Primary source for this project was [Zero to main() series](https://interrupt.memfault.com/blog/zero-to-main-1) on [interrupt.memfault.com](https://interrupt.memfault.com).

Project was tested on Nucleo F030R8 (using MCU STM32F030R8T6).

# Prerequisities

* Compiler (arm-none-eabi-gcc) and linker (arm-none-eabi-ld) (from [ARM GNU toolchain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads))
* Flashing utility ([st-flash](https://github.com/stlink-org/stlink/tree/master) or official [ST flashing utility](https://www.st.com/en/development-tools/stsw-link004.html))

# Usage

* clone repository
* make
* make flash

# Modifying for other MCUs

You will need to:

* modify FLASH and RAM size in linker script
* if architecture other than Cortex-M0 is used, modify MCU\_SPEC variable in Makefile
* if interrupt vector table differs from the one used in STM32F030x, modify it in file interrupt_vectors.h

# Licence

You are free to use and modify this project in any legal way you want. Please don't sue me if your STM32F0x turns into heating element and starts emitting large quantities of black smoke.
