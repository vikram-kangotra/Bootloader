#include "stdio.h"
#include <stdint.h>
#include <stdbool.h>
#include "div64.h"

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

typedef enum {
    PRINTF_STATE_NORMAL,
    PRINTF_STATE_LENGTH,
    PRINTF_STATE_LENGTH_SHORT,
    PRINTF_STATE_LENGTH_LONG,
    PRINTF_STATE_SPECIFIER,
} PrintfState;

typedef enum {
    PRINTF_LENGTH_NONE,
    PRINTF_LENGTH_SHORT,
    PRINTF_LENGTH_SHORT_SHORT,
    PRINTF_LENGTH_LONG,
    PRINTF_LENGTH_LONG_LONG,
} PrintfLength;

int* printf_number(int* argp, PrintfLength length, uint8_t radix, bool sign);

void printf(const uint8_t* fmt, ...) {

    int* argp = (int*) &fmt;
    argp += sizeof(fmt) / sizeof(int);

    PrintfState state = PRINTF_STATE_NORMAL;
    PrintfLength length = PRINTF_LENGTH_NONE;
    uint8_t radix = 10;
    bool sign = false;

    while (*fmt) {
        switch (state) {
            case PRINTF_STATE_NORMAL: {
                switch (*fmt) {
                    case '%': state = PRINTF_STATE_LENGTH; break;
                    case '\n': g_ScreenX = 0; g_ScreenY++; break;
                    default: {
                        putchar(g_ScreenX, g_ScreenY, *fmt); 
                        g_ScreenX++;
                    } break;
                }
            } break;
            case PRINTF_STATE_LENGTH: {
                switch (*fmt) {
                    case 'h': {
                        state = PRINTF_STATE_LENGTH_SHORT;
                        length = PRINTF_LENGTH_SHORT;
                    } break;
                    case 'l': {
                        state = PRINTF_STATE_LENGTH_LONG;
                        length = PRINTF_LENGTH_LONG;
                    } break;
                    default: goto PRINTF_STATE_SPECIFIER_;
                }
            } break;
            case PRINTF_STATE_LENGTH_SHORT: {
                if (*fmt == 'h') {
                    state = PRINTF_STATE_SPECIFIER;
                    length = PRINTF_LENGTH_SHORT_SHORT;
                } else {
                    goto PRINTF_STATE_SPECIFIER_;
                }
            } break;
            case PRINTF_STATE_LENGTH_LONG: {
                if (*fmt == 'l') {
                    state = PRINTF_STATE_SPECIFIER;
                    length = PRINTF_LENGTH_LONG_LONG;
                } else {
                    goto PRINTF_STATE_SPECIFIER_;
                }
            } break;
            case PRINTF_STATE_SPECIFIER: {
                PRINTF_STATE_SPECIFIER_:
                switch (*fmt) {
                    case '%': {
                        putchar(g_ScreenX, g_ScreenY, '%');
                        g_ScreenX++;
                    } break;
                    case 'c': {
                        putchar(g_ScreenX, g_ScreenY, (uint8_t) *argp);
                        g_ScreenX++;
                        argp++;
                    } break;
                    case 's': {
                        puts(*(uint8_t**) argp);
                        argp++;
                    } break;

                    case 'd':
                    case 'i': {
                        sign = true;
                        radix = 10;
                        argp = printf_number(argp, length, radix, sign);
                    } break;
                    case 'u': {
                        sign = false;
                        radix = 10;
                        argp = printf_number(argp, length, radix, sign);
                    } break;

                    case 'x':
                    case 'X':
                    case 'p': {
                        sign = false;
                        radix = 16;
                        argp = printf_number(argp, length, radix, sign);
                    } break;

                    case 'o': {
                        sign = false;
                        radix = 8;
                        argp = printf_number(argp, length, radix, sign);
                    } break;
                    
                    // ignore
                    default: break;
                }
                state = PRINTF_STATE_NORMAL;
                length = PRINTF_LENGTH_NONE;
                sign = false;
                radix = 10;
           }
        }
        fmt++;
    }
}

int* printf_number(int* argp, PrintfLength length, uint8_t radix, bool sign) {

    static const char hexdigits[] = "0123456789abcdef";

    uint8_t buffer[32] = {0};
    uint64_t number;
    uint8_t number_sign = 1;
    uint8_t pos = 0;

    switch (length) {
        case PRINTF_LENGTH_NONE:
        case PRINTF_LENGTH_SHORT:
        case PRINTF_LENGTH_SHORT_SHORT: {
            if (sign) {
                int n = *argp;
                if (n < 0) {
                    n = -n;
                    number_sign = -1;
                }
                number = (uint64_t) n;
            } else {
                number = (uint32_t) *argp;
            }
            argp++;
        } break;
        case PRINTF_LENGTH_LONG: {
            if (sign) {
                int32_t n = *(int32_t*) argp;
                if (n < 0) {
                    n = -n;
                    number_sign = -1;
                }
                number = (uint64_t) n;
            } else {
                number = *(uint32_t*) argp;
            }
            argp += 2;
        } break;
        case PRINTF_LENGTH_LONG_LONG: {
            if (sign) {
                int64_t n = *(int64_t*) argp;
                if (n < 0) {
                    n = -n;
                    number_sign = -1;
                }
                number = (uint64_t) n;
            } else {
                number = *(uint64_t*) argp;
            }
            argp += 4;
        } break;
    }
 
    do {
        uint32_t rem = number % radix;
        number /= radix;
        buffer[pos++] = hexdigits[rem];
    } while (number > 0); 

    if (sign && number_sign < 0) {
        buffer[pos++] = '-';
    }

    for (int i = pos - 1; i >= 0; i--) {
        putchar(g_ScreenX, g_ScreenY, buffer[i]);
        g_ScreenX++;
    }

    return argp;
}
