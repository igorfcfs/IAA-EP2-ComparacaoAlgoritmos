#ifndef _RADIXSORT_H_
#define _RADIXSORT_H_
#include "utilarray.h"

/* Ordena a.A[0..a.length-1] em ordem crescente usando radix sort LSD
 * (least-significant-digit first), com dígitos de 8 bits (base 256,
 * 4 passadas para int de 32 bits). Cada passada é um counting sort
 * estável sobre o dígito corrente.
 * PRÉ-CONDIÇÃO: todos os elementos são inteiros não-negativos (é o caso
 * dos valores gerados por next(31) em rng.c, que usam apenas 31 bits).
 * Aloca um array auxiliar de mesmo tamanho (O(n) de memória extra).
 */
void radixsort(Array a);

#endif
