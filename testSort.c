/* testSort.c - EP2 (Introdução à Análise de Algoritmos, EACH-USP)
 * Igor Fernando Casita Ferreira da Silva - RA 18245598
 *
 * ARQUIVO ÚNICO E AUTOCONTIDO: não depende de nenhum outro arquivo .c/.h
 * além da biblioteca padrão do C. Reúne, nesta ordem:
 *   1) rng.c              - fornecido pelo professor, sem alterações
 *   2) utilarray.c         - fornecido pelo professor, sem alterações
 *   3) elapsedRunningTime.c - fornecido pelo professor, sem alterações
 *      (versão portátil Windows/Linux: no Windows o gettimeofday() do
 *      professor não existe nativamente, então esta versão implementa um
 *      equivalente baseado em GetSystemTimeAsFileTime só para permitir
 *      compilar no mesmo ambiente Windows usado nos benchmarks do
 *      relatório; a interface start()/stop()/printCSVElapsed() e a lógica
 *      de medição em si são as mesmas do original)
 *   4) quicksort  - implementação PRÓPRIA
 *   5) radixsort  - implementação PRÓPRIA
 *   6) main()     - gera uma entrada, ordena com os dois algoritmos, mede
 *      o tempo e confere a corretude
 *
 * Compilação (um único comando, sem nenhum outro arquivo):
 *   gcc -O2 testSort.c -o testSort
 *
 * Uso:
 *   ./testSort [n] [-csv]
 *   n (opcional) = quantidade de elementos a ordenar (padrão: 1000000)
 *   -csv (opcional) = imprime só duas linhas CSV, para uso em scripts
 *
 * O programa gera UM único array aleatório de tamanho n, faz uma cópia
 * idêntica dele (para que os dois algoritmos ordenem exatamente a mesma
 * entrada - mesmo controle experimental usado na coleta de dados do
 * relatório, Seção 2.4), ordena a cópia 1 com quicksort e a cópia 2 com
 * radix sort, mede o tempo de cada ordenação com clock() e gettimeofday(),
 * confere se cada resultado ficou em ordem crescente e se os dois vetores
 * ficaram idênticos.
 *
 * Saída padrão: relatório legível. Com -csv, uma linha por algoritmo:
 *   algoritmo;n;tempo_clock_s;tempo_wall_s;ordenado(1/0)
 * O código de saída é 0 se tudo estiver correto e 1 se houver erro.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* =====================================================================
 * 1) RNG.C - fornecido pelo professor, sem alterações.
 * Gerador congruencial linear, mesmas constantes do java.util.Random.
 * ===================================================================== */
long long seed = 0x5DEECE66DLL;

void setSeed(long long newSeed) {
  seed = (newSeed ^ 0x5DEECE66DLL) & ((1LL << 48) - 1);
}

/**
 * Generates the next pseudorandom number.
 * The general contract of next is that it returns an int value and if the
 * argument bits is between 1 and 32 (inclusive), then that many low-order
 * bits of the returned value will be (approximately) independently chosen
 * bit values, each of which is (approximately) equally likely to be 0 or
 * 1. The method next is implemented by class Random by atomically updating
 * the seed to (seed * 0x5DEECE66DL + 0xBL) & ((1L << 48) - 1) and returning
 * (int)(seed >>> (48 - bits)).
 */
int next(int bits) {
  seed = (seed * 0x5DEECE66DLL + 0xBLL) & ((1LL << 48) - 1);
  return (int)(seed >> (48 - bits));
}

/* =====================================================================
 * 2) UTILARRAY.C - fornecido pelo professor, sem alterações.
 * ===================================================================== */
typedef struct {
  int *A;
  long int length;
} Array;

Array alocaArray(long int length) {
  Array a;
  a.A = (int *)malloc(length * sizeof(int));
  if (a.A == NULL) {
    printf("alocaArray: Não foi possível alocar array de %ld elementos.",
           length);
    a.length = 0;
  } else {
    a.length = length;
  }
  return a;
}

void printArray(Array a) {
  printf("length:%ld\nA:[", a.length);
  for (int i = 0; i < a.length; i++) {
    printf(" %d,", a.A[i]);
  }
  puts("]");
}

Array dealocaArray(Array a) {
  free(a.A);
  a.A = NULL;
  a.length = 0; /* como o parâmetro é passado por cópia, a cópia externa
                   não pode ser modificada dentro da função, então para
                   esta mudança afetar a cópia externa, usa-se uma
                   atribuição. */
  return a;
}

/* Testa se os elementos do array estão em ordem crescente
 * @param a : o array a testar.
 * @return : Retorna o índice do primeiro elemento fora de ordem. Caso o
 * array esteja ordenado, retornará length
 */
long int crescente(Array a) {
  long int i;
  for (i = 1; i < a.length; i++) {
    if (a.A[i - 1] > a.A[i]) break;
  }
  return i;
}

void randArray(Array a) {
  for (long int i = 0; i < a.length; i++) {
    a.A[i] = next(31);
  }
}

/* =====================================================================
 * 3) ELAPSEDRUNNINGTIME.C - fornecido pelo professor (versão portátil
 * Windows/Linux), sem alterações na lógica de medição. O original do
 * professor usa gettimeofday() (POSIX, <sys/time.h>), que não existe
 * nativamente no Windows; o bloco #ifdef _WIN32 abaixo só implementa um
 * equivalente (struct timeval + gettimeofday()) baseado em
 * GetSystemTimeAsFileTime, para permitir compilar no Windows (MSVC) com a
 * MESMA interface start()/stop()/printCSVElapsed(). No Linux e no MinGW
 * (gcc no Windows), que já trazem struct timeval e gettimeofday() em
 * <sys/time.h>, usa a versão real, sem nenhuma mudança.
 * ===================================================================== */
#if defined(_WIN32) && !defined(__MINGW32__) && !defined(__MINGW64__)
#include <windows.h>

struct timeval {
  long tv_sec;
  long tv_usec;
};

static int gettimeofday(struct timeval *tv, void *tzIgnored) {
  (void)tzIgnored;
  FILETIME ft;
  unsigned long long t;
  GetSystemTimeAsFileTime(&ft);
  t = ((unsigned long long)ft.dwHighDateTime << 32) | ft.dwLowDateTime;
  t /= 10;                   /* 100ns -> microssegundos */
  t -= 11644473600000000ULL; /* 1601-01-01 -> 1970-01-01, em us */
  tv->tv_sec = (long)(t / 1000000ULL);
  tv->tv_usec = (long)(t % 1000000ULL);
  return 0;
}
#else
#include <sys/time.h>
#endif

struct timeval wbegin, wend; /* usadas com gettimeofday() */
clock_t begin, end;          /* usadas com clock() */

void start() {
  gettimeofday(&wbegin, 0);
  begin = clock();
}

void stop() {
  end = clock();
  gettimeofday(&wend, 0);
}

void printfElapsed() {
  double elapsed = (double)(end - begin) / CLOCKS_PER_SEC;
  printf("clock() measured elapsed time: %0.6f seconds.\n", elapsed);
  long seconds = wend.tv_sec - wbegin.tv_sec;
  long microseconds = wend.tv_usec - wbegin.tv_usec;
  elapsed = seconds + microseconds * 1.0e-6;
  printf("gettimeofday() measured elapsed time: %0.6f seconds.\n", elapsed);
}

#define CSVSEP ';'

void printCSVElapsed() {
  double elapsed = (double)(end - begin) / CLOCKS_PER_SEC;
  printf("% 0.6f%c", elapsed, CSVSEP);
  long seconds = wend.tv_sec - wbegin.tv_sec;
  long microseconds = wend.tv_usec - wbegin.tv_usec;
  elapsed = seconds + microseconds * 1.0e-6;
  printf(" %0.6f%c", elapsed, CSVSEP);
}

/* =====================================================================
 * 4) QUICKSORT - implementação PRÓPRIA.
 * Pivô por mediana de três, partição de Hoare, corte para insertion sort
 * em sub-arrays pequenos (<=16) e eliminação de recursão de cauda
 * (recursão sempre no menor lado, para manter a pilha em O(log n) mesmo
 * no pior caso). Caso médio Theta(n log n).
 * ===================================================================== */
#define INSERTION_CUTOFF 16

static void qsSwap(int *A, long int i, long int j) {
  int tmp = A[i];
  A[i] = A[j];
  A[j] = tmp;
}

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

static int medianOfThree(int *A, long int lo, long int mid, long int hi) {
  if (A[lo] > A[mid]) qsSwap(A, lo, mid);
  if (A[mid] > A[hi]) qsSwap(A, mid, hi);
  if (A[lo] > A[mid]) qsSwap(A, lo, mid);
  return A[mid];
}

static long int hoarePartition(int *A, long int lo, long int hi, int pivot) {
  long int i = lo - 1;
  long int j = hi + 1;
  while (1) {
    do {
      i++;
    } while (A[i] < pivot);
    do {
      j--;
    } while (A[j] > pivot);
    if (i >= j) return j;
    qsSwap(A, i, j);
  }
}

static void quicksortRec(int *A, long int lo, long int hi) {
  while (hi - lo + 1 > INSERTION_CUTOFF) {
    long int mid = lo + (hi - lo) / 2;
    int pivot = medianOfThree(A, lo, mid, hi);
    long int p = hoarePartition(A, lo, hi, pivot);

    if (p - lo < hi - (p + 1)) {
      quicksortRec(A, lo, p);
      lo = p + 1; /* continua no lado maior */
    } else {
      quicksortRec(A, p + 1, hi);
      hi = p; /* continua no lado maior */
    }
  }
  insertionSort(A, lo, hi);
}

void quicksort(Array a) {
  if (a.length <= 1) return;
  quicksortRec(a.A, 0, a.length - 1);
}

/* =====================================================================
 * 5) RADIX SORT - implementação PRÓPRIA.
 * LSD (least-significant-digit first), base 256 (dígitos de 8 bits), 4
 * passadas, cada uma um counting sort estável. Theta(d*(n+b)) = Theta(n)
 * para d e b fixos (d=4, b=256). Usa um array auxiliar de tamanho n
 * (trocando os papéis de origem/destino a cada passada, para evitar uma
 * cópia O(n) extra por passada).
 * ===================================================================== */
#define RADIX_BITS 8
#define RADIX_BASE 256 /* 2^RADIX_BITS */
#define RADIX_MASK (RADIX_BASE - 1)
#define RADIX_PASSES 4 /* 32 bits / 8 bits por passada */

static void countingPass(int *src, int *dst, long int n, int shift) {
  long int count[RADIX_BASE + 1];
  memset(count, 0, sizeof(count));

  for (long int i = 0; i < n; i++) {
    unsigned int digit = ((unsigned int)src[i] >> shift) & RADIX_MASK;
    count[digit + 1]++;
  }
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
           "elementos.\n",
           a.length);
    return;
  }

  int *src = a.A;
  int *dst = aux;
  for (int pass = 0; pass < RADIX_PASSES; pass++) {
    int shift = pass * RADIX_BITS;
    countingPass(src, dst, a.length, shift);
    int *tmp = src;
    src = dst;
    dst = tmp;
  }
  if (src != a.A) {
    memcpy(a.A, src, a.length * sizeof(int));
  }
  free(aux);
}

/* =====================================================================
 * 6) main() - demonstra e mede os dois algoritmos sobre a MESMA entrada.
 * ===================================================================== */
static double elapsedClock(void) {
  return (double)(end - begin) / CLOCKS_PER_SEC;
}

static double elapsedWall(void) {
  return (double)(wend.tv_sec - wbegin.tv_sec) +
         (double)(wend.tv_usec - wbegin.tv_usec) * 1.0e-6;
}

static void printResultado(const char *nome, double tClock, double tWall,
                           int ordenado) {
  printf("  %-11s clock(): %10.6f s   gettimeofday(): %10.6f s   %s\n", nome,
         tClock, tWall, ordenado ? "ordenado: SIM" : "ordenado: NAO (ERRO)");
}

int main(int argc, char **argv) {
  long int n = 1000000;
  int csv = 0;

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "-csv") == 0) {
      csv = 1;
    } else if (atol(argv[i]) > 0) {
      n = atol(argv[i]);
    } else {
      fprintf(stderr, "uso: %s [n] [-csv]\n", argv[0]);
      return 1;
    }
  }

  /* Gera UM array aleatório e faz uma cópia idêntica, para que quicksort
   * e radix sort ordenem exatamente a mesma entrada (mesmo controle
   * experimental da Seção 2.4 do relatório). */
  Array a1 = alocaArray(n);
  Array a2 = alocaArray(n);
  if (a1.A == NULL || a2.A == NULL) {
    fprintf(stderr, "\nErro: memória insuficiente para n = %ld.\n", n);
    dealocaArray(a1);
    dealocaArray(a2);
    return 1;
  }
  randArray(a1);
  memcpy(a2.A, a1.A, n * sizeof(int));

  if (!csv) {
    printf("=== testSort: quicksort vs radix sort ===\n");
    printf("Elementos (n): %ld   (int de 31 bits, gerados com rng.c)\n", n);
    printf("Memória: %.1f MB por vetor\n",
           (double)n * sizeof(int) / (1024.0 * 1024.0));
    printf("Primeiros elementos (antes) : ");
    for (long int i = 0; i < n && i < 5; i++) printf("%d ", a1.A[i]);
    printf("...\n\nOrdenando...\n");
  }

  /* --- Quicksort --- */
  start();
  quicksort(a1);
  stop();
  double qsClock = elapsedClock(), qsWall = elapsedWall();
  int qsOk = (crescente(a1) == a1.length);

  /* --- Radix sort --- */
  start();
  radixsort(a2);
  stop();
  double rxClock = elapsedClock(), rxWall = elapsedWall();
  int rxOk = (crescente(a2) == a2.length);

  /* Os dois algoritmos precisam produzir exatamente o mesmo vetor. */
  int iguais = (memcmp(a1.A, a2.A, n * sizeof(int)) == 0);
  int ok = qsOk && rxOk && iguais;

  if (csv) {
    printf("algoritmo;n;tempo_clock_s;tempo_wall_s;ordenado\n");
    printf("qs;%ld;%.6f;%.6f;%d\n", n, qsClock, qsWall, qsOk);
    printf("radix;%ld;%.6f;%.6f;%d\n", n, rxClock, rxWall, rxOk);
  } else {
    printf("\nResultados:\n");
    printResultado("Quicksort", qsClock, qsWall, qsOk);
    printResultado("Radix sort", rxClock, rxWall, rxOk);

    printf("\nPrimeiros elementos (depois): ");
    for (long int i = 0; i < n && i < 5; i++) printf("%d ", a1.A[i]);
    printf("...\n");
    printf("Maior elemento              : %d\n", a1.A[n - 1]);

    printf("\nConferência:\n");
    printf("  Quicksort em ordem crescente : %s\n", qsOk ? "OK" : "FALHOU");
    printf("  Radix sort em ordem crescente: %s\n", rxOk ? "OK" : "FALHOU");
    printf("  Os dois vetores são idênticos: %s\n", iguais ? "OK" : "FALHOU");
    if (rxWall > 0) {
      printf("\nRadix sort foi %.1fx mais rápido que o quicksort "
             "(tempo de relógio).\n",
             qsWall / rxWall);
    }
    printf("\n%s\n", ok ? "RESULTADO: tudo certo."
                        : "RESULTADO: HOUVE ERRO!");
  }

  dealocaArray(a1);
  dealocaArray(a2);
  return ok ? 0 : 1;
}
