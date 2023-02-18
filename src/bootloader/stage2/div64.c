#include "div64.h"

// just a nasty hack to get the compiler to generate 64-bit division
// instructions. Future plans to remove this file and use the compiler
// intrinsics instead.

uint64_t __udivmoddi4 (uint64_t n, uint64_t d, uint64_t *rp)
{
  uint64_t q = 0, r = n, y = d;
  uint32_t lz1, lz2, i, k;

  /* Implements align divisor shift dividend method. This algorithm
     aligns the divisor under the dividend and then perform number of
     test-subtract iterations which shift the dividend left. Number of
     iterations is k + 1 where k is the number of bit positions the
     divisor must be shifted left to align it under the dividend.
     quotient bits can be saved in the rightmost positions of the dividend
     as it shifts left on each test-subtract iteration. */

  if (y <= r)
    {
      lz1 = __builtin_clzll (d);
      lz2 = __builtin_clzll (n);

      k = lz1 - lz2;
      y = (y << k);

      /* Dividend can exceed 2 ^ (width - 1) - 1 but still be less than the
	 aligned divisor. Normal iteration can drops the high order bit
	 of the dividend. Therefore, first test-subtract iteration is a
	 special case, saving its quotient bit in a separate location and
	 not shifting the dividend. */
      if (r >= y)
	{
	  r = r - y;
	  q =  (1ULL << k);
	}

      if (k > 0)
	{
	  y = y >> 1;

	  /* k additional iterations where k regular test subtract shift
	    dividend iterations are done.  */
	  i = k;
	  do
	    {
	      if (r >= y)
		r = ((r - y) << 1) + 1;
	      else
		r =  (r << 1);
	      i = i - 1;
	    } while (i != 0);

	  /* First quotient bit is combined with the quotient bits resulting
	     from the k regular iterations.  */
	  q = q + r;
	  r = r >> k;
	  q = q - (r << k);
	}
    }

  if (rp)
    *rp = r;
  return q;
}

uint64_t __udivdi3 (uint64_t n, uint64_t d)
{
  return __udivmoddi4 (n, d, (uint64_t *) 0);
}

uint64_t __umoddi3 (uint64_t u, uint64_t v)
{
  uint64_t w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
