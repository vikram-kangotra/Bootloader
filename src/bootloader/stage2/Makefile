TARGET_ASMFLAGS += -f elf
TARGET_CFLAGS += -ffreestanding -nostdlib
TARGET_LIBS += -lgcc
TARGET_LDFLAGS += -T linker.ld -nostdlib

SRC_C=$(wildcard *.c)
SRC_ASM=$(wildcard *.asm)
OBJ_C=$(patsubst %.c, $(BUILD_DIR)/stage2/c/%.o, $(SRC_C))
OBJ_ASM=$(patsubst %.asm, $(BUILD_DIR)/stage2/asm/%.o, $(SRC_ASM))

.PHONY: all clean always stage2

stage2: $(BUILD_DIR)/stage2.bin

$(BUILD_DIR)/stage2.bin: $(OBJ_ASM) $(OBJ_C)
	$(TARGET_LD) $(TARGET_LDFLAGS) $(TARGET_LIBS) -o $@ $^

$(BUILD_DIR)/stage2/asm/%.o: %.asm always
	$(TARGET_ASM) $(TARGET_ASMFLAGS) -o $@ $<

$(BUILD_DIR)/stage2/c/%.o: %.c always
	$(TARGET_CC) $(TARGET_CFLAGS) -c -o $@ $<

always:
	mkdir -p $(BUILD_DIR)/stage2/c
	mkdir -p $(BUILD_DIR)/stage2/asm

clean:
	rm -rf $(BUILD_DIR)/stage2
	rm -f $(BUILD_DIR)/stage2.bin
