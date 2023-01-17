ASM=nasm

SRC_DIR=src
BUILD_DIR=build

.PHONY: all clean os_image bootloader

all: os_image

os_image: $(BUILD_DIR)/os.img

$(BUILD_DIR)/os.img: bootloader
	dd if=/dev/zero of=$(BUILD_DIR)/os.img bs=512 count=2880
	mkfs.fat -F 12 -n "MIOSIS" $(BUILD_DIR)/os.img
	dd if=$(BUILD_DIR)/stage1.bin of=$(BUILD_DIR)/os.img conv=notrunc

bootloader: stage1 

stage1: $(BUILD_DIR)/stage1.bin

$(BUILD_DIR)/stage1.bin: always
	$(MAKE) -C $(SRC_DIR)/bootloader/stage1 BUILD_DIR=$(abspath $(BUILD_DIR))

always:
	mkdir -p $(BUILD_DIR)

clean:
	$(MAKE) -C $(SRC_DIR)/bootloader/stage1 BUILD_DIR=$(abspath $(BUILD_DIR)) clean
	rm -rf $(BUILD_DIR)
