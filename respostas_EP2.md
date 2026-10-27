---
title: "EP2 — IAA: Comparação de tempo de execução entre quicksort e radix sort"
author: "Igor Fernando Casita Ferreira da Silva — RA 18245598"
date: \today
---

# Questão 1 — Chave secreta

A chave secreta foi gerada com o mesmo método de `calcSecret.c`, fornecido
pelo professor: o gerador congruencial linear de `rng.c` (as mesmas
constantes do `java.util.Random`) é inicializado com `setSeed(semente)` e a
função `next(31)` é chamada `vezes` vezes seguidas; o último valor
retornado é a chave.

- **Semente:** `18245598` (RA do aluno)
- **Vezes:** `31`
- **Chave secreta resultante:** **`1906028835`**

Comando usado (ver `src/secretkey_gen.c`, versão não interativa de
`calcSecret.c` para permitir automação e reprodutibilidade):

```
$ gcc -O2 rng.c secretkey_gen.c -o secretkey_gen
$ ./secretkey_gen 18245598 31
1906028835
```

Esse mesmo valor (`1906028835`) é o identificador usado para marcar as
linhas deste aluno na planilha compartilhada.

# Questão 2 — Crítica ao método de geração da chave secreta

O gerador usado não é um gerador de números aleatórios "de verdade": é um
**gerador congruencial linear (LCG)**, definido por

```
seed(n+1) = (seed(n) * 0x5DEECE66D + 0xB) mod 2^48
next(bits) = seed >> (48 - bits)
```

Essas são exatamente as constantes do `java.util.Random`. Avaliando esse
método com base no que se sabe (cientificamente) sobre LCGs:

**1. Estado pequeno e período limitado.** O estado interno tem apenas 48
bits, logo o período máximo da sequência é, no limite, 2^48 (~2,8×10^14).
Isso é irrelevante para o uso específico aqui (gerar *um* identificador por
aluno), mas seria um problema sério se o gerador fosse usado para gerar
muitos valores em sequência (ex.: Monte Carlo de larga escala), pois a
sequência eventualmente se repete.

**2. Não é criptograficamente seguro.** Um LCG é completamente
determinístico e **invertível**: como a relação entre `seed(n)` e
`seed(n+1)` é linear (módulo 2^48) e as constantes do multiplicador e do
incremento são públicas (estão no código-fonte!), conhecendo-se uma saída
de `next(31)` é possível reconstruir boa parte do estado interno e prever
os próximos valores com buscas de força bruta pequenas (faltam apenas os
17 bits baixos descartados por `next(31)`, triviais de testar
exaustivamente: 2^17 ≈ 131 mil tentativas). Isso é documentado
oficialmente pela própria Oracle/Sun para o `java.util.Random`: "not
cryptographically strong". Para o propósito deste EP (um identificador de
experimento, não um segredo que precise resistir a ataques), essa
fragilidade não compromete o uso, mas seria inaceitável se "chave secreta"
fosse levada ao pé da letra como segredo criptográfico.

**3. Estrutura de reticulado (lattice) nos bits baixos.** É um resultado
clássico (Marsaglia, *"Random numbers fall mainly in the planes"*, PNAS,
1968) que **todo** LCG, quando usado para gerar pontos em dimensão *k*
(ex.: tuplas `(x_i, x_{i+1}, ..., x_{i+k-1})`), produz pontos que caem em
um número relativamente pequeno de hiperplanos paralelos, em vez de
preencher o espaço uniformemente — um artefato estrutural inerente à
recorrência linear, não um bug de implementação. Além disso, os bits de
**baixa ordem** de um LCG com módulo 2^48 têm período muito curto: o bit
menos significativo da sequência bruta tem período no máximo 2, o segundo
bit no máximo 4, e assim por diante (período do bit *i* ≤ 2^(i+1)). A
implementação de `next(bits)` mitiga parcialmente esse problema
descartando os bits baixos e devolvendo os bits **mais altos** do estado
(`seed >> (48-bits)`), que têm qualidade estatística bem melhor — isto é,
o projeto do gerador já incorpora essa correção conhecida.

**4. Determinismo como propriedade desejada aqui, não como defeito.** Ao
contrário de um gerador "aleatório de verdade" (ex.: baseado em entropia de
hardware), este método é **reprodutível por construção**: dados a mesma
semente e o mesmo número de iterações, qualquer pessoa obtém exatamente a
mesma chave. Isso é, na verdade, desejável no contexto do EP (permite
conferência/depuração), mas significa que "secreta" aqui deve ser
entendido como "específica de cada aluno", não como "imprevisível para
quem souber o método".

**5. Risco de colisão entre alunos.** O espaço de saída de `next(31)` tem
2^31 ≈ 2,1 bilhões de valores possíveis. Pelo paradoxo do aniversário, com
uma turma de *k* alunos escolhendo sementes e números de iterações
*independentes o bastante*, a probabilidade de colisão é
aproximadamente `k²/(2·2^31)` — para `k=100`, isso é ≈ 2,3×10⁻⁶,
desprezível. **Porém**, a independência não está garantida: se vários
alunos usarem sementes "parecidas" (ex.: o próprio RA, que tem estrutura
sequencial dentro de uma mesma turma/ano) **e** um número pequeno de
iterações, a relação de recorrência ainda não teve "tempo" suficiente para
misturar o estado (poucas iterações de uma função linear preservam parte
da proximidade entre sementes próximas), o que pode gerar chaves
correlacionadas — e, em casos extremos, até colisões, se a semente
escolhida coincidir (duas pessoas usando o mesmo RA não existe, mas usar
"as letras do nome" como sugerido no enunciado tem mais chance de colisão
entre nomes parecidos). Usar `vezes=31` (um número não trivial de
iterações) e uma semente longa e específica (o RA) como feito aqui reduz
esse risco.

**Conclusão da crítica:** para o propósito declarado — gerar um
identificador determinístico, específico por aluno, usado para rastrear
linhas em uma planilha compartilhada — o método é **adequado**: é simples,
reprodutível, e com baixíssima chance prática de colisão dado o espaço de
saída de 31 bits. Ele **não deveria** ser usado onde se exige
imprevisibilidade real (jogos de azar, criptografia, sorteios com dinheiro
em jogo), pois é um LCG clássico, com toda a literatura conhecida sobre
suas fraquezas estruturais (reticulados, período curto nos bits baixos,
invertibilidade).

# Questão 3 — Código-fonte

Todo o código-fonte implementado está na pasta `src/` entregue junto com
este relatório (mesma pasta do Google Drive indicada pelo aluno):

- `rng.c` / `rng.h` — gerador fornecido pelo professor (não alterado).
- `utilarray.c` / `utilarray.h` — utilitários de array fornecidos pelo
  professor (não alterados).
- `elapsedRunningTime.c` / `elapsedRunningTime.h` — medição de tempo
  fornecida pelo professor (não alterada).
- `quicksort.c` / `quicksort.h` — **implementação própria** de quicksort
  com pivô por mediana de três, partição de Hoare, corte para insertion
  sort em sub-arrays pequenos (≤16) e eliminação de recursão de cauda
  (recursão sempre no menor lado).
- `radixsort.c` / `radixsort.h` — **implementação própria** de radix sort
  LSD (least-significant-digit first), base 256 (dígitos de 8 bits), 4
  passadas, cada uma um counting sort estável.
- `gen_input.c` — gera e grava em arquivo binário um array de entrada
  (usando `rng.c`), para garantir que os dois algoritmos sejam testados
  sobre **exatamente a mesma entrada** em cada tamanho.
- `run_sort.c` — lê o array binário, ordena com o algoritmo escolhido
  (`qs` ou `radix`), mede o tempo só da ordenação (com `start()`/`stop()`
  de `elapsedRunningTime.c`, igual ao padrão de `testSort.c`), confere
  corretude com `crescente()` e imprime uma linha CSV.
- `secretkey_gen.c` — versão não interativa de `calcSecret.c`, usada na
  questão 1.
- `bench.sh` — script que orquestra a bateria de experimentos (tamanhos e
  repetições) e grava `raw_results.csv`.
- `platforminfo.h` — informação de hardware/software do ambiente de
  execução (ver questão 5).

Compilação (mesma convenção dos comentários `gcc ...` do código do
professor):

```
gcc -O2 rng.c utilarray.c gen_input.c -o gen_input
gcc -O2 rng.c utilarray.c elapsedRunningTime.c quicksort.c radixsort.c \
    run_sort.c -o run_sort
```

# Questão 4 — Preenchimento da planilha

A planilha compartilhada
(`1Z-5QVFHl0WzqMRSkdoEY5XxhGWhDQgy8R1BIUpdY3Bs`) foi preenchida com os
tempos médios de execução (em segundos, medidos com `gettimeofday()`) de
`quicksort` e `radix sort`, para cada tamanho de entrada testado, na(s)
linha(s) identificada(s) pela chave secreta `1906028835`, sem apagar
linhas de outros alunos. Nenhum algoritmo se aproximou do limite de 3600s
no maior tamanho testado (200 milhões de elementos: ~27s para quicksort e
~5,6s para radix sort), portanto nenhuma célula precisou ser marcada como
"timeout reached".

# Questão 5 — Discussão científica

## 5.1 Metodologia

Para cada tamanho de entrada *n* ∈ {10³, 10⁴, 10⁵, 5×10⁵, 10⁶, 5×10⁶, 10⁷,
5×10⁷, 10⁸, 2×10⁸}, foi gerado **um único array de inteiros
pseudoaleatórios não-negativos** (valores de `next(31)`, uniformes em
[0, 2³¹−1]) por repetição, e **o mesmo array** foi usado tanto para o
quicksort quanto para o radix sort — isso controla a entrada como variável
de confusão: a diferença de tempo medida vem apenas do algoritmo, não de
sorte na geração dos dados. Tamanhos pequenos (≤10⁵) foram repetidos 5–7
vezes e tamanhos maiores 1–3 vezes (o tempo de execução já é muito menos
ruidoso em valores absolutos grandes, e repetir uma ordenação de 2×10⁸
elementos tem custo alto para um ganho estatístico pequeno). O tempo
reportado é o de `gettimeofday()`, medindo **apenas a fase de ordenação**
(a geração do array e a checagem de corretude com `crescente()` ficam fora
da medição). Todas as execuções (100% delas) terminaram com o array
corretamente ordenado.

## 5.2 Resultados agregados (tempo médio de parede, em segundos)

| n           | quicksort (s) | radix sort (s) | razão qs/radix |
|-------------|---------------:|----------------:|---------------:|
| 1.000       | 0,000057 | 0,000015 | 3,9× |
| 10.000      | 0,000616 | 0,000101 | 6,1× |
| 100.000     | 0,008978 | 0,001331 | 6,7× |
| 500.000     | 0,047612 | 0,008546 | 5,6× |
| 1.000.000   | 0,109214 | 0,020645 | 5,3× |
| 5.000.000   | 0,560269 | 0,128673 | 4,4× |
| 10.000.000  | 1,083806 | 0,258689 | 4,2× |
| 50.000.000  | 6,147409 | 1,351841 | 4,5× |
| 100.000.000 | 13,232630 | 2,821044 | 4,7× |
| 200.000.000 | 27,038782 | 5,638415 | 4,8× |

(tabela completa, com desvio-padrão e número de repetições, em
`resultados/raw_results.csv` e `resultados/agg_results.json`; gráfico em
`resultados/comparacao_quicksort_radix.png`)

## 5.3 Por que radix sort venceu, e por que isso era esperado

**Complexidade teórica.** O quicksort implementado é um algoritmo **de
comparação**: todo o processo de ordenação se baseia em comparar pares de
elementos (`A[i] < A[j]?`) para decidir sua posição relativa. Qualquer
algoritmo de ordenação por comparação tem, no pior caso, complexidade
**Ω(n log n)** — este é um limite inferior demonstrável por um argumento
de teoria da informação / árvore de decisão (CLRS, cap. 8): existem *n!*
permutações possíveis de *n* elementos distintos, uma árvore de decisão
binária que as distingue todas precisa de altura ≥ log₂(n!) = Θ(n log n)
(por Stirling). Com pivô por mediana de três e partição balanceada em
expectativa sobre entrada aleatória, o quicksort implementado atinge o
caso médio **Θ(n log n)** (CLRS cap. 7, análise via variáveis indicadoras
e linearidade da esperança), o que é consistente com o crescimento
observado nos dados.

O radix sort, em contraste, **não compara elementos** — ele extrai
dígitos (bytes) de cada chave e usa counting sort (estável) para
posicioná-los. Por não ser um algoritmo de comparação, ele **não está
sujeito** ao limite inferior Ω(n log n): sua complexidade é
**Θ(d·(n+b))**, onde *d* é o número de dígitos (aqui, 4, para inteiros de
32 bits em base 256) e *b* é a base (256). Como *d* e *b* são constantes
fixas (não dependem de *n*), isso se reduz a **Θ(n)** — linear no
tamanho da entrada. Essa é a razão estrutural pela qual o radix sort é
assintoticamente mais rápido: ele "contorna" o limite inferior dos
algoritmos de comparação ao explorar uma propriedade específica da chave
(ser um inteiro de largura fixa), algo que um algoritmo de comparação
genérico não pode assumir.

**O fator constante observado (~4×–7×) e por que ele não cresce como o
previsto pela teoria pura.** Se comparássemos *apenas* os expoentes
assintóticos, a razão tempo(quicksort)/tempo(radix) deveria crescer
proporcionalmente a log₂(n) conforme n aumenta — entre n=10³ (log₂n≈10)
e n=2×10⁸ (log₂n≈27,6), a razão "deveria" crescer por um fator de
≈2,8×. Nos dados medidos, a razão fica relativamente estável, entre 3,9×
e 6,7×, sem essa tendência de crescimento monotônico clara. Isso tem
explicação científica, não é ruído puro:

- **Efeitos de cache dominam em n pequeno/médio.** Para n pequeno o
  suficiente para caber no cache L2/L3 do processador, ambos os
  algoritmos rodam quase inteiramente dentro do cache, e o fator
  dominante não é o número de operações, mas o overhead de chamadas de
  função (recursão do quicksort) vs. o overhead de inicializar múltiplos
  arrays de contagem a cada passada (radix). Isso explica a razão subir
  de 3,9× (n=10³) até um pico de 6,7× (n=10⁵) — nessa faixa, o
  overhead constante do quicksort recursivo pesa proporcionalmente mais.
- **Radix sort tem pior localidade de acesso à memória.** Cada passada de
  counting sort faz escritas **dispersas** (não sequenciais) no array de
  destino, posicionando cada elemento conforme seu dígito — um padrão de
  acesso ruim para cache quando o array já não cabe mais no cache (n
  grande). O quicksort, embora também acesse memória de forma menos
  previsível que um sort sequencial, tem localidade razoável dentro de
  cada partição recursiva (sub-arrays cada vez menores, eventualmente
  cabendo em cache). Esse efeito **penaliza relativamente mais o radix
  sort** à medida que n cresce além da capacidade do cache, parcialmente
  cancelando o ganho assintótico teórico e explicando por que a razão cai
  de 6,7× (n=10⁵) para ~4,2× (n=10⁷) antes de voltar a subir lentamente
  (4,8× em n=2×10⁸) quando o termo log n finalmente volta a pesar mais
  que os efeitos de cache.
- **Memória extra do radix sort.** A implementação usada aloca um array
  auxiliar do mesmo tamanho (O(n) de memória extra) e troca os papéis de
  origem/destino a cada passada — para n=2×10⁸, isso significa manipular
  ~1,6 GB de memória (800 MB × 2), o que também aumenta a pressão sobre a
  hierarquia de memória e o tempo de alocação, um custo que o quicksort
  (essencialmente in-place, com apenas O(log n) de pilha graças à
  eliminação de recursão de cauda implementada) não paga.

**Ruído de medição.** Os desvios-padrão em `agg_results.json` mostram
variação de ~5–20% entre repetições, especialmente para tamanhos médios —
esperado em um ambiente de container compartilhado (sem isolamento de
CPU dedicado, sujeito a jitter do escalonador do SO), por isso a
metodologia usou médias de múltiplas repetições para tamanhos menores (o
tempo relativo é mais sensível a ruído quando o tempo absoluto é da ordem
de dezenas de microssegundos).

## 5.4 Conclusão

Os dados confirmam, de forma consistente com a teoria de algoritmos, que
o **radix sort é assintoticamente superior ao quicksort** para esta
tarefa específica (ordenar um grande volume de inteiros de 32 bits não
negativos), sendo entre 3,9× e 6,7× mais rápido em todos os tamanhos
testados, sem jamais perder para o quicksort. Isso não significa que
radix sort seja "melhor" de forma absoluta: ele só se aplica a chaves com
representação de largura fixa e conhecida (inteiros, strings de tamanho
limitado), exige O(n) de memória auxiliar, e sua vantagem assintótica é
parcialmente mascarada, em n intermediários, por efeitos de cache —
exatamente o tipo de nuance que a análise assintótica pura (contar apenas
operações "a menos de constante") não captura, mas que a medição empírica
revela. O quicksort, por sua vez, continua sendo a escolha mais geral:
funciona para qualquer tipo com relação de ordem total e comparação
O(1), roda essencialmente in-place, e sua degradação para o pior caso
O(n²) foi evitada aqui pelo uso de mediana de três e por os dados serem
uniformemente aleatórios (exatamente o cenário em que o caso médio
Θ(n log n) se aplica).

## 5.5 Ambiente de execução (hardware/software)

Ver `src/platforminfo.h` para os valores formatados no padrão sugerido.
Resumo:

- **CPU:** Intel(R) Xeon(R) Processor @ 2.10GHz, 2 vCPUs (ambiente de
  container/sandbox Linux efêmero fornecido pela ferramenta de IA usada
  para implementar e executar este trabalho — não é o notebook pessoal do
  aluno; isso é documentado explicitamente por transparência científica,
  pois afeta a comparação de tempos *absolutos* com colegas, mas não afeta
  as conclusões sobre o crescimento *relativo* entre os dois algoritmos,
  que dependem apenas de *n*, não do hardware específico).
- **RAM:** 8.220.252 kB total, 7.676.584 kB disponível no momento dos
  testes.
- **SO:** Ubuntu 24.04.5 LTS (kernel Linux, container).
- **Compilador:** gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, flags
  `-O2`.
