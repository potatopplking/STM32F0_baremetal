# Toolchain
CC=arm-none-eabi-gcc
LD=arm-none-eabi-ld
OC=arm-none-eabi-objcopy
GDB=arm-none-eabi-gdb

# MCU definition
MCU_SPEC = cortex-m0

# Compiler flags
INCLUDE = -I ./include
CFLAGS = \
	  -c \
	  -mcpu=$(MCU_SPEC) \
	  # Thumb mode (T32 instruction set) \
	  -mthumb \
	  -Wall \
	  # do not optimize \
	  -O0 \
	  # default debug information; g0 for none \
	  -g \
	  # stdlib may not exist and program start may not be at main \
	  -ffreestanding \
	  # place each function to its own section \
	  -ffunction-sections \
	  # place each data item to its own section \
	  -fdata-sections \
	  # last two arguments are useful if linker uses --gc-sections,
	  # which "garbage collects" unused symbols; this may lead
	  # to smaller executables

# Linker flags
LSCRIPT = ./ld/stm32f030x8.ld
LFLAGS += \
	  -specs=nosys.specs \
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
.PRECIOUS: $(BUILD_DIR)/%.elf
all: $(BUILD_DIR)/$(TARGET).bin

# create build folder
$(BUILD_DIR):
	mkdir $@

$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf
	$(OC) -S -O binary $< $@

$(BUILD_DIR)/%.elf: $(OBJS)
	$(LD) $(LFLAGS) $^ -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	echo $(CC) $(CFLAGS) $(INCLUDE) -o $@ $<
	$(CC) $(CFLAGS) $(INCLUDE) -o $@ $<

flash:
	st-flash write $(BUILD_DIR)/$(TARGET).bin 0x8000000

debug:
	@echo -e "\n\nAfter gdb starts, execute command \"target remote :4242\"\n\n"
	st-util & arm-none-eabi-gdb $(BUILD_DIR)/$(TARGET).elf

clean:
	rm -rf $(BUILD_DIR)
