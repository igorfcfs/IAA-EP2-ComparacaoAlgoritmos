/* UTILARRAY.C - Funções utilitárias para arrays. 
 * 
 * standalone test compilation command: gcc -D TEST_UTILARRAY rng.c utilarray.c
 */
#include "utilarray.h"

Array alocaArray (long int length) {
  Array a;
  a.A=(int *) malloc (length*sizeof(int));
  if (a.A==NULL) {
    printf ("alocaArray: Não foi possível alocar array de %ld elementos.", length); 
    a.length=0;
  } else {
    a.length=length;
  }
  return a;
}

void printArray (Array a) {
  printf ("length:%ld\nA:[", a.length);
  for (int i=0;i<a.length;i++) {
    printf (" %d,", a.A[i]);
  }
  puts("]");
}

Array dealocaArray (Array a) {
  free (a.A);
  a.A=NULL;
  a.length=0; // como o parâmetro é passado por cópia, a cópia externa não
              // pode ser modificada dentro da função, então para esta
              // mudança afetar a cópia externa, usa-se uma atribuição.
  return a;
}

/* Testa se os elementos do array estão em ordem crescente
 * @param a : o array a testar.
 * @return : Retorna o índice do primeiro elemento fora de ordem. Caso o array
 * esteja ordenado, retornará length
 */
long int crescente (Array a) {
  long int i;
  for (i=1;i<a.length;i++) {
    if (a.A[i-1]>a.A[i]) break;
  }
  return i;
}

/* por causa desta função precisa compilar rng.c junto 
 * 
 * */
void randArray (Array a) {
  for (long int i=0;i<a.length;i++) {
    a.A[i]=next(31);
  }
}


/* Testa a alocação de arrays de comprimentos definidos no array lengths, um
 * de cada vez, aloca o maior array possível.
 * Os elementos do array alocado são to tipo inteiro.
 * Se verboso=='S' então apresenta mensagem informando falha ou sucesso.
 * Executar esta função com outros aplicativos (ex.: Navegador, jogos, ...)
 * pode alterar o resultado.
 * info: em um computador com 24GB de RAM, consegui alocar um array de 6bi
 * elementos. Foi o máximo tanto com o ambiente gráfico em execução quanto sem.
 * info: em um notebook com 8GB de RAM consegui alocar um array de 2bi
 * elementos. No mesmo notebook com 4GB, consegui alocar um arrya de 1bi
 * elementos.
 */
Array testaAlocar (char verboso) {
  long int lengths[]={  // do maior para o menor
	  10000000000L,  // 10bi
	   8000000000L,  
	   6000000000L,  
	   4000000000L,  
	   2000000000L, 
	   1000000000L,
	    500000000L
  };
  Array a;
  // cuidado - isto só calcula o comprimento do array em condições específicas!
  int lenlen = sizeof (lengths)/sizeof (long); 
  for (int i=0;i<lenlen;i++){
    a.A=(int *) malloc (lengths[i]*sizeof(int));
    if (verboso=='S') {
      if (a.A==NULL) {
        printf ("Falha na alocação de array de %ld inteiros.\n", lengths[i]);
      } else {
        printf ("Sucesso na alocação de array de %ld inteiros.\n", lengths[i]);
        a.length=lengths[i];
        break;
      }
    }
  }
  return a;
}
#if 0  // só aloca
int main () {
  Array ord=alocaArray (100);
  ord=dealocaArray(ord);
}
#endif

#if 0  // aloca, imprime, dealoca
int main () {
  Array ord=alocaArray (100);
  printArray(ord);
  ord=dealocaArray(ord);
}
#endif

#ifdef TEST_UTILARRAY // aloca, preenche, imprime, dealoca
int main () {
  Array ord=alocaArray (100);
  randArray (ord);
  printArray(ord);
  ord=dealocaArray(ord);
  ord=testaAlocar('S');
  dealocaArray(ord);
}
#endif
