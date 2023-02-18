#ifndef DIV64_H
#define DIV64_H

// just a nasty hack to get the compiler to generate 64-bit division
// instructions. Future plans to remove this file and use the compiler
// intrinsics instead.

#include <stdint.h>

uint64_t __udivdi3(uint64_t a, uint64_t b);
uint64_t __umoddi3(uint64_t a, uint64_t b);
uint64_t __divmoddi4(uint64_t a, uint64_t b, uint64_t *rem_p);

#endif
