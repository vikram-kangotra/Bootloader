BUILD_DIR?=build
ASM=nasm
ASMFLAGS=-f elf32
CC=gcc
CFLAGS=-m32 -nostdlib -fno-pie -ffreestanding
LDFLAGS=-T linker.ld

SRC_C=$(wildcard *.c)
SRC_ASM=$(wildcard *.asm)
OBJ_C=$(patsubst %.c, $(BUILD_DIR)/stage2/c/%.o, $(SRC_C))
OBJ_ASM=$(patsubst %.asm, $(BUILD_DIR)/stage2/asm/%.o, $(SRC_ASM))

.PHONY: all clean always stage2

stage2: $(BUILD_DIR)/stage2.bin

$(BUILD_DIR)/stage2.bin: $(OBJ_ASM) $(OBJ_C)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

$(BUILD_DIR)/stage2/asm/%.o: %.asm always
	$(ASM) $(ASMFLAGS) -o $@ $<

$(BUILD_DIR)/stage2/c/%.o: %.c always
	$(CC) $(CFLAGS) -c -o $@ $<

always:
	mkdir -p $(BUILD_DIR)/stage2/c
	mkdir -p $(BUILD_DIR)/stage2/asm

clean:
	rm -rf $(BUILD_DIR)/stage2
	rm -f $(BUILD_DIR)/stage2.bin
