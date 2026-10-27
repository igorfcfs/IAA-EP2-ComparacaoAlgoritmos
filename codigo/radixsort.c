/* RADIXSORT.C - Implementação de radix sort (LSD, base 256) para o EP2
 * de IAA.
 *
 * standalone test compilation command:
 *   gcc -D TEST_RADIXSORT rng.c utilarray.c radixsort.c
 */
#include "radixsort.h"
#include <string.h>

#define RADIX_BITS 8
#define RADIX_BASE 256                 /* 2^RADIX_BITS */
#define RADIX_MASK (RADIX_BASE - 1)
#define RADIX_PASSES 4                 /* 32 bits / 8 bits por passada */

/* Uma passada de counting sort estável sobre o byte `shift` de cada
 * elemento de src, escrevendo o resultado em dst. O(n + RADIX_BASE). */
static void countingPass(int *src, int *dst, long int n, int shift) {
  long int count[RADIX_BASE + 1];
  memset(count, 0, sizeof(count));

  for (long int i = 0; i < n; i++) {
    unsigned int digit = ((unsigned int)src[i] >> shift) & RADIX_MASK;
    count[digit + 1]++;
  }
  /* soma prefixa -> count[d] passa a ser a posição inicial do dígito d */
  for (int d = 0; d < RADIX_BASE; d++) {
    count[d + 1] += count[d];
  }
  for (long int i = 0; i < n; i++) {
    unsigned int digit = ((unsigned int)src[i] >> shift) & RADIX_MASK;
    dst[count[digit]++] = src[i];
  }
}

void radixsort(Array a) {
  if (a.length <= 1) return;

  int *aux = (int *)malloc(a.length * sizeof(int));
  if (aux == NULL) {
    printf("radixsort: nao foi possivel alocar array auxiliar de %ld "
           "elementos.\n", a.length);
    return;
  }

  int *src = a.A;
  int *dst = aux;
  for (int pass = 0; pass < RADIX_PASSES; pass++) {
    int shift = pass * RADIX_BITS;
    countingPass(src, dst, a.length, shift);
    /* troca os papeis de src/dst para a próxima passada, em vez de copiar
     * de volta (evita uma cópia O(n) extra por passada) */
    int *tmp = src;
    src = dst;
    dst = tmp;
  }
  /* após RADIX_PASSES (par) trocas, o resultado ordenado está em a.A se
   * RADIX_PASSES for par; garantimos isso com a cópia condicional abaixo
   * para não depender dessa paridade. */
  if (src != a.A) {
    memcpy(a.A, src, a.length * sizeof(int));
  }
  free(aux);
}

#ifdef TEST_RADIXSORT
int main() {
  Array a = alocaArray(1000000);
  randArray(a);
  radixsort(a);
  long int r = crescente(a);
  printf("ordenado corretamente: %s (crescente() retornou %ld, length=%ld)\n",
         (r == a.length) ? "SIM" : "NAO", r, a.length);
  dealocaArray(a);
  return 0;
}
#endif
