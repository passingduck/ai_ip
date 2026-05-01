ROOT_DIR := ../..
TOOLCHAIN_DIR := $(ROOT_DIR)/tools/learn-fpga/FemtoRV/FIRMWARE/TOOLCHAIN/riscv64-unknown-elf-gcc-8.3.0-2020.04.0-x86_64-linux-ubuntu14
TOOLCHAIN_BIN := $(TOOLCHAIN_DIR)/bin

CC := $(TOOLCHAIN_BIN)/riscv64-unknown-elf-gcc
OBJCOPY := $(TOOLCHAIN_BIN)/riscv64-unknown-elf-objcopy
OBJDUMP := $(TOOLCHAIN_BIN)/riscv64-unknown-elf-objdump
FIRMWARE_WORDS := $(ROOT_DIR)/tools/learn-fpga/FemtoRV/FIRMWARE/TOOLS/firmware_words

BUILD := build
TARGET := $(BUILD)/rtos_lcd_counter

CFLAGS := -march=rv32im -mabi=ilp32 -Os -ffreestanding -fno-pic -fno-builtin \
          -fno-stack-protector -Wall -Wextra -Iinclude
ASFLAGS := -march=rv32im -mabi=ilp32 -Iinclude
LDFLAGS := -nostdlib -nostartfiles -Wl,--no-relax -Tld/linker.ld

SRCS_C := src/main.c src/isr.c src/rtos.c
SRCS_S := arch/riscv/startup.S arch/riscv/trap.S
OBJS := $(SRCS_C:%.c=$(BUILD)/%.o) $(SRCS_S:%.S=$(BUILD)/%.o)

.PHONY: all clean tree

all: $(TARGET).elf $(TARGET).bin $(TARGET).hex $(TARGET).list

$(TARGET).elf: $(OBJS) ld/linker.ld
	$(CC) $(CFLAGS) $(LDFLAGS) $(OBJS) -o $@

$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

$(TARGET).hex: $(TARGET).elf $(FIRMWARE_WORDS)
	$(FIRMWARE_WORDS) $< -ram 65536 -max_addr 65536 -out $@

$(TARGET).list: $(TARGET).elf
	$(OBJDUMP) -Mnumeric -D $< > $@

$(BUILD)/%.o: %.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/%.o: %.S
	mkdir -p $(dir $@)
	$(CC) $(ASFLAGS) -c $< -o $@

tree:
	find . -maxdepth 3 -type f | sort

clean:
	rm -rf $(BUILD)
