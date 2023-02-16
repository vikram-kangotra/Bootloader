#include "stdio.h"
#include <stdint.h>

const uint8_t SCREEN_WIDTH = 80;
const uint8_t SCREEN_HEIGHT = 25;
const uint8_t DEFAULT_COLOR = 0x7;

uint8_t* g_ScreenBuffer = (uint8_t*) 0xb8000;
uint8_t g_ScreenX = 0;
uint8_t g_ScreenY = 0;

void putchar(uint8_t x, uint8_t y, uint8_t c) {
    g_ScreenBuffer[2 * (y * SCREEN_WIDTH + x)] = c;
}

void putcolor(uint8_t x, uint8_t y, uint8_t color) {
    g_ScreenBuffer[2 * (y * SCREEN_WIDTH + x) + 1] = color;
}

void puts(const uint8_t* str) {
    for (int i = 0; str[i] != '\0'; i++) {
        putchar(g_ScreenX, g_ScreenY, str[i]);
        g_ScreenX++;
        if (g_ScreenX >= SCREEN_WIDTH) {
            g_ScreenX = 0;
            g_ScreenY++;
        }
    }
}

void clrscr(void) {
    for (int y = 0; y < SCREEN_HEIGHT; ++y) {
        for (int x = 0; x < SCREEN_WIDTH; ++x) {
            putchar(x, y, '\0');
            putcolor(x, y, DEFAULT_COLOR);
        }
    }
    g_ScreenX = 0;
    g_ScreenY = 0;
}
