# EP2 - IAA: quicksort vs radix sort

Ver `respostas_EP2.docx` (ou `.md`) para as respostas às 5 questões do
questionário, incluindo a discussão científica pedida na questão 5.

## Estrutura do repositório

| Caminho | Conteúdo |
| :--- | :--- |
| `testSort.c` | **Arquivo único e autocontido**: RNG, utilarray, medição de tempo, quicksort e radix sort juntos, com `main()` que ordena a mesma entrada com os dois algoritmos e confere a corretude. Só precisa da biblioteca padrão do C. |
| `src/` | Código-fonte modular (C): arquivos do professor sem alterações (`rng`, `utilarray`, `elapsedRunningTime`), implementações próprias (`quicksort`, `radixsort`) e programas de execução/medição (`gen_input`, `run_sort`, `secretkey_gen`, `benchmark_clock`, `benchmark_gettimeofday`), mais `bench.sh`, `bench.ps1` e `COMANDOS.md`. |
| `src/output/` | Executáveis `.exe` compilados (Windows). |
| `src/tempos_planilha_*.csv` | Tabelas dos tamanhos oficiais da planilha do professor (`clock()` e `gettimeofday()`). |
| `src/raw_results.csv` | Resultado bruto da bateria completa (`bench.sh` / `bench.ps1`). |
| `resultados/` | Dados agregados (média/desvio), regressão, gráficos e o script R `graficos_r/analise.R`. |
| `codigo/`, `figuras/`, `anexos/` | Cópias do código, figuras do relatório e a planilha do professor. |
| `relatorio.tex`, `abnt/` | Fontes LaTeX do relatório. |
| `scripts/`, `graficos/` | **Não pertencem ao EP2.** São de um trabalho anterior (cálculo de raiz quadrada: `sqrt`, `test.sh`, `plots.sh`...). Não são necessários para rodar quicksort/radix sort. |

## Requisitos

- **gcc** (testado com o gcc do MinGW/Strawberry Perl no Windows 11; funciona também no Linux).
- **PowerShell** (para `bench.ps1`) ou **bash** (para `bench.sh`).
- **R** (`Rscript`), só se for regenerar os gráficos de `resultados/graficos_r/`.
- Os tamanhos grandes exigem RAM: cada `int` ocupa 4 bytes, então `n = 200000000` usa ~800 MB (mais o vetor auxiliar do radix sort).

Os comandos abaixo assumem o terminal na raiz do repositório, salvo indicação contrária. Os exemplos de bash funcionam também no Git Bash; os de PowerShell estão marcados.

---

## 1. Forma mais simples: `testSort.c` (um único arquivo)

```
gcc -O2 testSort.c -o testSort
./testSort              # n = 1.000.000 (padrão)
./testSort 5000000      # n escolhido por você
./testSort 5000000 -csv # só duas linhas CSV, para scripts
```

Gera **um** vetor aleatório, copia para um segundo vetor idêntico, ordena o primeiro com quicksort e o segundo com radix sort, mede cada tempo (`clock()` e `gettimeofday()`) e confere três coisas: quicksort em ordem crescente, radix sort em ordem crescente e os dois vetores finais idênticos. O código de saída é 0 se tudo estiver certo e 1 se algo falhar.

Saída padrão (exemplo):

```
=== testSort: quicksort vs radix sort ===
Elementos (n): 1000000   (int de 31 bits, gerados com rng.c)
Memória: 3.8 MB por vetor
Primeiros elementos (antes) : 1569741360 1785505948 516548029 ...

Resultados:
  Quicksort   clock():   0.052000 s   gettimeofday():   0.051550 s   ordenado: SIM
  Radix sort  clock():   0.006000 s   gettimeofday():   0.006153 s   ordenado: SIM

Primeiros elementos (depois): 665 7614 9194 12522 19791 ...
Maior elemento              : 2147480122

Conferência:
  Quicksort em ordem crescente : OK
  Radix sort em ordem crescente: OK
  Os dois vetores são idênticos: OK

Radix sort foi 8.4x mais rápido que o quicksort (tempo de relógio).

RESULTADO: tudo certo.
```

Com `-csv` a saída é `algoritmo;n;tempo_clock_s;tempo_wall_s;ordenado`, uma linha por algoritmo (`ordenado = 1` é correto). No Windows com MSVC o programa usa uma `gettimeofday()` própria; no MinGW e no Linux usa a da libc.

---

## 2. Compilação dos programas modulares (`src/`)

```
cd src
mkdir -p output

# Gerador de entradas
gcc -O2 rng.c utilarray.c gen_input.c -o output/gen_input

# Executor/medidor de um algoritmo sobre um arquivo de entrada
gcc -O2 rng.c utilarray.c elapsedRunningTime.c quicksort.c radixsort.c run_sort.c -o output/run_sort

# Chave secreta (questão 1)
gcc -O2 rng.c secretkey_gen.c -o output/secretkey_gen

# Testes embutidos de cada algoritmo
gcc -O2 -D TEST_RADIXSORT rng.c utilarray.c radixsort.c -o output/test_radix
gcc -O2 -D TEST_QUICKSORT rng.c utilarray.c quicksort.c -o output/test_qs

# Medidores das tabelas da planilha do professor
gcc -O2 rng.c utilarray.c quicksort.c radixsort.c benchmark_clock.c -o output/benchmark_clock
gcc -O2 rng.c utilarray.c quicksort.c radixsort.c benchmark_gettimeofday.c -o output/benchmark_gettimeofday
```

No PowerShell, crie a pasta com `if (-not (Test-Path output)) { New-Item -ItemType Directory output }` e use `output\nome.exe` nos caminhos de saída. As compilações geram avisos `-Woverflow` em `utilarray.c` (constantes como `10000000000L` em `long` de 32 bits no Windows); são inofensivos e vêm do arquivo do professor.

A pasta `src/.vscode/tasks.json` tem as mesmas compilações como tarefas do VS Code.

---

## 3. Chave secreta (questão 1)

```
./output/secretkey_gen 18245598 31
```

Saída esperada: `1906028835` (RA `18245598`, 31 repetições de `next(31)`).

---

## 4. Testes rápidos de cada algoritmo

Ordenam 1.000.000 de elementos e conferem o resultado:

```
./output/test_radix
./output/test_qs
```

Saída esperada em ambos: `ordenado corretamente: SIM (crescente() retornou 1000000, length=1000000)`.

---

## 5. Medição manual: gerar entrada e rodar cada algoritmo

Os dois algoritmos devem ordenar exatamente a mesma entrada, por isso a entrada é gerada uma vez em arquivo binário.

```
# ./output/gen_input <n> <semente> <arquivo>
./output/gen_input 10000000 42 entrada.bin

# ./output/run_sort <qs|radix> <arquivo>
./output/run_sort qs entrada.bin
./output/run_sort radix entrada.bin

rm entrada.bin
```

Saída: `algoritmo;n;tempo_clock_s;tempo_wall_s;ok_ordenado`, por exemplo `radix;10000000;0.082000;0.081540;1`.

Tamanhos de referência (aprox., na máquina usada):

| n | Radix sort | Quicksort |
| :--- | :--- | :--- |
| 100 mil (`100000`) | ~0,0006 s | ~0,005 s |
| 1 milhão (`1000000`) | ~0,008 s | ~0,06 s |
| 10 milhões (`10000000`) | ~0,08 s | ~0,8 s |
| 100 milhões (`100000000`) | ~2,5 s | ~12 s |
| 200 milhões (`200000000`) | ~5,5 s | ~27 s |

Cuidado com os zeros: 100 bilhões (`100000000000`) exigiria ~400 GB de RAM.

---

## 6. Bateria completa de testes (`raw_results.csv`)

Roda 10 tamanhos (de 1.000 a 200.000.000), com repetições maiores nos tamanhos pequenos, e grava uma linha por execução em `raw_results.csv` (colunas `algoritmo;n;repeticao;seed;tempo_clock_s;tempo_wall_s;ok_ordenado`). Execução com timeout de 3600 s por algoritmo.

**PowerShell** (dentro de `src/`; compila sozinho se os `.exe` de `output\` não existirem):

```powershell
.\bench.ps1 -Quick     # só 1.000 a 1.000.000, poucos segundos
.\bench.ps1            # bateria oficial completa, até 200 milhões
.\bench.ps1 -TimeoutSeconds 600
```

**Bash/Linux** (dentro de `src/`; o script espera os binários `./gen_input` e `./run_sort` na pasta atual):

```
gcc -O2 rng.c utilarray.c gen_input.c -o gen_input
gcc -O2 rng.c utilarray.c elapsedRunningTime.c quicksort.c radixsort.c run_sort.c -o run_sort
./bench.sh
```

Atenção: o `bench.ps1` **acrescenta** ao `raw_results.csv` existente (só escreve o cabeçalho se o arquivo não existir), enquanto o `bench.sh` **recria** o arquivo. Apague ou renomeie o CSV antigo se quiser uma bateria limpa. Os arquivos de entrada temporários vão para a pasta temporária do sistema e são apagados ao final de cada repetição.

---

## 7. Tabelas da planilha do professor

Tamanhos: `T(1E6)`, `T(2E6)`, `T(5E6)`, `T(1E7)`, `T(2E7)`, `T(5E7)`, `T(1E8)`, `T(2E8)`, `T(5E8)`, `T(1E9)`, `T(2E9)`, `T(6E9)`, `T(8E9)`, `T(10E9)`. Cada tamanho é medido com quicksort e radix sort sobre a mesma entrada (semente = semente base + n).

```
cd src

# clock()  ->  tempos_planilha_clock.csv
./output/benchmark_clock 18245598

# gettimeofday()  ->  tempos_planilha_gettimeofday.csv
./output/benchmark_gettimeofday 18245598
```

- O 1º argumento é a semente base (padrão: `18245598`, o RA).
- O 2º argumento, opcional, limita o maior `n` testado, para um teste rápido (ex.: `./output/benchmark_clock 18245598 10000000` pula tudo acima de 10 milhões).
- Os arquivos são gravados **na pasta atual**; por isso rode de dentro de `src/`.
- Tamanhos acima de 2.147.483.647 elementos (`T(6E9)`, `T(8E9)`, `T(10E9)`) não cabem em `long` de 32 bits do Windows e/ou na RAM, e saem como `Sem memoria`. O mesmo vale para qualquer tamanho cuja alocação falhe.
- A bateria completa até 2 bilhões de elementos leva vários minutos e precisa de muita RAM (2E9 elementos = ~8 GB por vetor).

**Vírgula decimal para Excel/Sheets em pt-BR:** os programas gravam números com ponto (`1.050000`), que o Excel em pt-BR interpreta como milhar. Os CSVs versionados em `src/` já estão com vírgula. Depois de gerar de novo, converta (Git Bash, dentro de `src/`):

```
sed -i -E '2,$ s/([0-9])\.([0-9])/\1,\2/g' tempos_planilha_clock.csv tempos_planilha_gettimeofday.csv
```

---

## 8. Gráficos e estatísticas (R)

Os gráficos de `resultados/graficos_r/` e o resumo estatístico vêm de `resultados/graficos_r/analise.R`, que lê `raw_results.csv` e `tempos_planilha_clock.csv` e grava:
`01_tempo_vs_n_loglog.png`, `02_razao_qs_radix.png`, `03_boxplot_variabilidade.png`, `04_planilha_oficial_loglog.png`, `resumo_estatistico.csv` e `regressao.txt`.

```
Rscript resultados/graficos_r/analise.R
```

Confira no início do script de onde ele espera encontrar os CSVs (ele cria a pasta `graficos_r` no diretório atual), copiando `raw_results.csv` e `tempos_planilha_clock.csv` para lá se necessário. O R não estava instalado na máquina em que este README foi verificado, então este passo não foi executado.

---

## Verificação

Os passos das seções 1 a 5 foram compilados e executados com gcc (MinGW) no Windows 11: a chave secreta deu `1906028835`, os dois testes embutidos deram `SIM`, e `run_sort` e `testSort` retornaram `ordenado = 1` para 1.000.000 de elementos. Os passos 6 a 8 (bateria completa, planilha completa e R) não foram reexecutados na verificação por serem demorados ou dependerem de R.
