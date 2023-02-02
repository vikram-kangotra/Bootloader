BUILD_DIR?=build
ASM?=nasm

.PHONY: all clean stage2

all: stage2
	
stage2: $(BUILD_DIR)/stage2.bin

$(BUILD_DIR)/stage2.bin: main.asm
	$(ASM) -f bin -o $@ $<

clean:
	rm -rf $(BUILD_DIR)/stage2.bin
