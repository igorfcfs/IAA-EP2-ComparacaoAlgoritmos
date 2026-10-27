/* RNG.C - Funções para geração de números aleatórios e teste de seu 
 * funcionamento.
 * standalone test compilation command: gcc -D TEST_RNG rng.c
 */
#include "rng.h"

long long seed=0x5DEECE66DLL;

void setSeed (long long newSeed) {
  seed=(newSeed ^ 0x5DEECE66DLL) & ((1LL << 48) - 1);
//  seed=newSeed;
}

/**
* Generates the next pseudorandom number. 
* The general contract of next is that it returns an int value and if the 
* argument bits is between 1 and 32 (inclusive), then that many low-order 
* bits of the returned value will be (approximately) independently chosen 
* bit values, each of which is (approximately) equally likely to be 0 or 
* 1. The method next is implemented by class Random by atomically updating 
* the seed to (seed * 0x5DEECE66DL + 0xBL) & ((1L << 48) - 1) and returning
*  (int)(seed >>> (48 - bits)).
*/

int next(int bits) {
 seed=(seed * 0x5DEECE66DLL + 0xBLL) & ((1LL << 48) - 1);
 return (int)(seed >> (48 - bits));
}

#ifdef TEST_RNG
void main (void) {
	int i;
	for (i=0;i<50;i++) {
		printf ("%d ", next(31));
	}
}
#endif
