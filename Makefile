BUILD_DIR=build

.PHONY: all clean bootloader

all: os_image

os_image: $(BUILD_DIR)/os.img

$(BUILD_DIR)/os.img: bootloader always
	dd if=/dev/zero of=$(BUILD_DIR)/os.img bs=512 count=2880
	mkfs.fat -F 12 -n "MIOSIS" $(BUILD_DIR)/os.img
	dd if=$(BUILD_DIR)/stage1.bin of=$(BUILD_DIR)/os.img conv=notrunc
	mcopy -i $(BUILD_DIR)/os.img $(BUILD_DIR)/stage2.bin "::stage2.bin"

bootloader: stage1 stage2

stage1:
	$(MAKE) -C src/bootloader/stage1 BUILD_DIR=$(abspath $(BUILD_DIR))

stage2:
	$(MAKE) -C src/bootloader/stage2 BUILD_DIR=$(abspath $(BUILD_DIR))

always:
	mkdir -p $(BUILD_DIR)

clean:
	$(MAKE) -C src/bootloader/stage1 clean
	$(MAKE) -C src/bootloader/stage2 clean
	rm -rf $(BUILD_DIR)/os.img
