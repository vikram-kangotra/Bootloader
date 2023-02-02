ASM=nasm
CC=gcc

SRC_DIR=src
TOOLS_DIR=tools
BUILD_DIR=build

.PHONY: all clean os_always image bootloader kernel tools tools_fat

all: os_image

tools: tools_fat

os_image: $(BUILD_DIR)/os.img

$(BUILD_DIR)/os.img: bootloader kernel
	dd if=/dev/zero of=$(BUILD_DIR)/os.img bs=512 count=2880
	mkfs.fat -F 12 -n "MIOSIS" $(BUILD_DIR)/os.img
	dd if=$(BUILD_DIR)/stage1.bin of=$(BUILD_DIR)/os.img conv=notrunc
	mcopy -i $(BUILD_DIR)/os.img $(BUILD_DIR)/stage2.bin "::stage2.bin"
	mcopy -i $(BUILD_DIR)/os.img $(BUILD_DIR)/kernel.bin "::kernel.bin"

bootloader: stage1 stage2

stage1: $(BUILD_DIR)/stage1.bin

$(BUILD_DIR)/stage1.bin: always
	$(MAKE) -C $(SRC_DIR)/bootloader/stage1 BUILD_DIR=$(abspath $(BUILD_DIR))

stage2: $(BUILD_DIR)/stage2.bin

$(BUILD_DIR)/stage2.bin: always
	$(MAKE) -C $(SRC_DIR)/bootloader/stage2 BUILD_DIR=$(abspath $(BUILD_DIR))

kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: always
	$(MAKE) -C $(SRC_DIR)/kernel BUILD_DIR=$(abspath $(BUILD_DIR))

tools_fat: $(BUILD_DIR)/tools/fat

$(BUILD_DIR)/tools/fat: always $(TOOLS_DIR)/fat/fat.c
	mkdir -p $(BUILD_DIR)/tools
	$(CC) -g -o $(BUILD_DIR)/tools/fat $(TOOLS_DIR)/fat/fat.c

always:
	mkdir -p $(BUILD_DIR)

clean:
	$(MAKE) -C $(SRC_DIR)/bootloader/stage1 BUILD_DIR=$(abspath $(BUILD_DIR)) clean
	rm -rf $(BUILD_DIR)
