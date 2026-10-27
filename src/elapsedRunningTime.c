/* elapsedRunningTime.c 
 * standalone test compile command: 
 * gcc -D TEST_ELAPSEDRUNNINGTIME elapsedRunningTime.c 
 * based on
 * https://levelup.gitconnected.com/8-ways-to-measure-execution-time-in-c-c-48634458d0f9
 */


#include <stdio.h>
#include <sys/time.h>
#include <time.h>

// Variáveis do módulo. 
// Estas são usadas para medir o tempo de execução com gettimeofday().
struct timeval wbegin, wend;

// Variáveis do módulo. 
// Estas são usadas para medir o tempo de execução com clock().
clock_t begin, end;

/* Inicia a contagem do tempo - armazena o instante de início nas respectivas 
 * variáveis. Do ponto de vista de acurácia, não é o melhor pois inclui o 
 * overhead de chamada da função start(), mas torna o código mais legível.
 */
void start () {
  gettimeofday(&wbegin, 0);
  // Start measuring time
  begin = clock();
}
  
/* Termina a contagem do tempo - armazena o instante de fim nas respectivas 
 * variáveis. Do ponto de vista de acurácia, não é o melhor pois inclui o 
 * overhead de chamada da função stop(), mas torna o código mais legível.
 */
void stop () {
  end = clock();
  gettimeofday(&wend, 0);
}

/* Escreve na tela o tempo, em segundos, transcorrido entre 
 * as chamadas de start() e end().
 */
void printfElapsed() {
  double elapsed = (double) (end - begin)/CLOCKS_PER_SEC;
  printf("clock() measured elapsed time: %0.6f seconds.\n", elapsed);
  long seconds = wend.tv_sec - wbegin.tv_sec;
  long microseconds = wend.tv_usec - wbegin.tv_usec;
  elapsed = seconds + microseconds*1.0e-6;
  printf("gettimeofday() measured elapsed time: %0.6f seconds.\n", elapsed);
}

/* Escreve na tela o tempo, em segundos, transcorrido entre 
 * as chamadas de start() e end(). Em formato CSV, usando o separador de campos
 * definido por CSVSEP, primeiro o valor obtido com clock(), depois o valor
 * obtido com gettimeofday()
 */
#define CSVSEP ';'

void printCSVElapsed() {
  double elapsed = (double) (end - begin)/CLOCKS_PER_SEC;
  printf("% 0.6f%c", elapsed, CSVSEP);
  long seconds = wend.tv_sec - wbegin.tv_sec;
  long microseconds = wend.tv_usec - wbegin.tv_usec;
  elapsed = seconds + microseconds*1.0e-6;
  printf(" %0.6f%c", elapsed, CSVSEP);
}

#if TEST_ELAPSEDRUNNINGTIME
// se quiser usar o teste abaixo, defina a macro TEST na compilação.
/* Teste: Usa as funções para medir o tempo de execução do código entre as
 * chamadas de start() e end().
 */
int main () {
    double sum = 0;
    double add = 1;

    start();
    int iterations = 1000*1000*1000;
    for (int i=0; i<iterations; i++) {
        sum += add;
        add /= 2.0;
    }

    // Stop measuring time and calculate the elapsed time
    stop();
    printfElapsed();    
    printCSVElapsed();
    return 0;
}
#endif
