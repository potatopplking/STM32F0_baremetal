# Toolchain
CC=arm-none-eabi-gcc
LD=arm-none-eabi-ld
OC=arm-none-eabi-objcopy
GDB=arm-none-eabi-gdb

# MCU definition
MCU_SPEC = cortex-m0

# Compiler flags
# Note that often following arguments are often used for ARM Cortex-M MCUs:
#  --specs=nosys.specs
#    Equivalent to -lnosys, defines that system calls should
#    be implemented as stubs that return error.
#
#    Spec files contains specs-strings, which controls
#    what subprocesses gcc should invoke and what parameters
#    to pass to them.
#    
#  --nostdlib
#    Do not use standard system startup files or libraries
#
# However, in this case they are not needed and have no effect on the final binary,
# therefore they are omitted.
INCLUDE = -I ./include
CFLAGS = \
	  -c \
	  -mcpu=$(MCU_SPEC) \
	  -mthumb \
	  -Wall \
	  -O0 \
	  -g

# Linker flags
LSCRIPT = ./ld/stm32f030x8.ld
LFLAGS += \
	  --print-memory-usage \
	  -T$(LSCRIPT)

# Input/output files
TARGET = stm32f0_baremetal
BUILD_DIR = build
SRC_DIR = ./src
C_SRC += \
	 main.c \
	 startup_stm32f030x.c
OBJS = $(addprefix $(BUILD_DIR)/, $(C_SRC:.c=.o))

.PHONY: all clean flash debug
.PRECIOUS: $(BUILD_DIR)/%.elf $(BUILD_DIR)/%.o
all: $(BUILD_DIR)/$(TARGET).bin

# create build folder
$(BUILD_DIR):
	mkdir $@

$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf
	$(OC) -S -O binary $< $@

$(BUILD_DIR)/%.elf: $(OBJS)
	$(LD) $(LFLAGS) $^ -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(INCLUDE) -o $@ $<

flash:
	st-flash write $(BUILD_DIR)/$(TARGET).bin 0x8000000

debug:
	@echo -e "\n\nAfter gdb starts, execute command \"target remote :4242\"\n\n"
	st-util & arm-none-eabi-gdb $(BUILD_DIR)/$(TARGET).elf

clean:
	rm -rf $(BUILD_DIR)
