/* QUICKSORT.C - Implementação de quicksort para o EP2 de IAA.
 *
 * standalone test compilation command:
 *   gcc -D TEST_QUICKSORT rng.c utilarray.c quicksort.c
 */
#include "quicksort.h"

#define INSERTION_CUTOFF 16

static void swap(int *A, long int i, long int j) {
  int tmp = A[i];
  A[i] = A[j];
  A[j] = tmp;
}

/* Insertion sort usado como caso base para sub-arrays pequenos. O(k^2) no
 * pior caso, mas com constante muito menor que quicksort, o que compensa
 * para k pequeno (tipicamente k <= 16..32). */
static void insertionSort(int *A, long int lo, long int hi) {
  for (long int i = lo + 1; i <= hi; i++) {
    int key = A[i];
    long int j = i - 1;
    while (j >= lo && A[j] > key) {
      A[j + 1] = A[j];
      j--;
    }
    A[j + 1] = key;
  }
}

/* Mediana de três: escolhe entre A[lo], A[mid], A[hi] o valor mediano e o
 * coloca em A[mid], devolvendo seu valor como pivô. Isso evita o pior caso
 * O(n^2) comum quando se usa sempre o primeiro ou o último elemento como
 * pivô (ex.: array já ordenado ou quase ordenado). */
static int medianOfThree(int *A, long int lo, long int mid, long int hi) {
  if (A[lo] > A[mid]) swap(A, lo, mid);
  if (A[mid] > A[hi]) swap(A, mid, hi);
  if (A[lo] > A[mid]) swap(A, lo, mid);
  return A[mid];
}

/* Partição de Hoare em torno do pivô p. Retorna o índice j tal que
 * A[lo..j] <= pivô <= A[j+1..hi] (particionamento em duas faixas, não três
 * - pode deixar elementos iguais ao pivô em ambos os lados, o que é
 * aceitável e, na prática, mais rápido que o esquema de Lomuto). */
static long int hoarePartition(int *A, long int lo, long int hi, int pivot) {
  long int i = lo - 1;
  long int j = hi + 1;
  while (1) {
    do { i++; } while (A[i] < pivot);
    do { j--; } while (A[j] > pivot);
    if (i >= j) return j;
    swap(A, i, j);
  }
}

/* Núcleo recursivo. Para manter a profundidade de pilha em O(log n) mesmo
 * no pior caso, sempre recorremos explicitamente (chamada de função) no
 * menor dos dois lados e continuamos o laço `while` no maior lado
 * (eliminação de recursão de cauda). */
static void quicksortRec(int *A, long int lo, long int hi) {
  while (hi - lo + 1 > INSERTION_CUTOFF) {
    long int mid = lo + (hi - lo) / 2;
    int pivot = medianOfThree(A, lo, mid, hi);
    long int p = hoarePartition(A, lo, hi, pivot);

    if (p - lo < hi - (p + 1)) {
      quicksortRec(A, lo, p);
      lo = p + 1; // continua no lado maior
    } else {
      quicksortRec(A, p + 1, hi);
      hi = p; // continua no lado maior
    }
  }
  insertionSort(A, lo, hi);
}

void quicksort(Array a) {
  if (a.length <= 1) return;
  quicksortRec(a.A, 0, a.length - 1);
}

#ifdef TEST_QUICKSORT
int main() {
  Array a = alocaArray(1000000);
  randArray(a);
  quicksort(a);
  long int r = crescente(a);
  printf("ordenado corretamente: %s (crescente() retornou %ld, length=%ld)\n",
         (r == a.length) ? "SIM" : "NAO", r, a.length);
  dealocaArray(a);
  return 0;
}
#endif
