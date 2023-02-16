#ifndef STDIO_H
#define STDIO_H

#include <stdint.h>

void putchar(uint8_t x, uint8_t y, uint8_t c);
void putcolor(uint8_t x, uint8_t y, uint8_t color);
void puts(const uint8_t *s);

void clrscr(void);

#endif
