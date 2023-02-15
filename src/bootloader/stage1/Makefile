BUILD_DIR?=build
ASM=nasm
ASMFLAGS=-f bin

.PHONY: all clean always stage1

stage1: $(BUILD_DIR)/stage1.bin

$(BUILD_DIR)/stage1.bin: main.asm always
	$(ASM) $(ASMFLAGS) -o $@ $<

always:
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)/stage1.bin
