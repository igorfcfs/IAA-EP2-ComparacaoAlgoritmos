#ifndef _QUICKSORT_H_
#define _QUICKSORT_H_
#include "utilarray.h"

/* Ordena a.A[0..a.length-1] em ordem crescente usando quicksort com:
 *  - escolha de pivô pela mediana de três (primeiro, meio, último) -
 *    reduz drasticamente a chance do pior caso O(n^2) em entradas
 *    adversárias ou já quase ordenadas;
 *  - partição de Hoare;
 *  - troca para insertion sort em sub-arrays pequenos (<= INSERTION_CUTOFF),
 *    pois para n pequeno o fator constante do insertion sort é menor que o
 *    overhead de chamadas recursivas do quicksort;
 *  - recursão de cauda eliminada manualmente (recorre sempre no menor lado e
 *    usa laço para o maior) para manter a pilha em O(log n) mesmo no pior
 *    caso, em vez de O(n).
 */
void quicksort(Array a);

#endif
