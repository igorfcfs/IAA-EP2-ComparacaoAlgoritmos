#!/usr/bin/env Rscript
# analise.R - Analise estatistica e graficos comparativos quicksort vs radix sort
# EP2 - IAA - dados reais coletados na maquina do aluno (Windows 11,
# i7-1355U, 16GB RAM) via run_sort.exe / benchmark_clock.exe.
#
# Entradas:
#   raw_results.csv          - medicoes repetidas (clock + wall), n = 1e3 .. 2e8
#   tempos_planilha_clock.csv - medicoes unicas (so clock), n = 1e6 .. 1e10
#                               (tamanhos oficiais da planilha do professor)
# Saidas (em ./graficos_r/):
#   01_tempo_vs_n_loglog.png
#   02_razao_qs_radix.png
#   03_boxplot_variabilidade.png
#   04_planilha_oficial_loglog.png
#   resumo_estatistico.csv
#   regressao.txt

suppressWarnings(suppressMessages({
  library(stats)
}))

dir.create("graficos_r", showWarnings = FALSE)

## ---------------------------------------------------------------
## 1. Carrega e limpa raw_results.csv (medicoes repetidas)
## ---------------------------------------------------------------
raw <- read.csv("raw_results.csv", sep = ";", stringsAsFactors = FALSE,
                 colClasses = "character", fileEncoding = "UTF-8-BOM")
names(raw) <- trimws(names(raw))
names(raw)[1] <- "algoritmo"  # corrige BOM eventualmente preso ao 1o nome de coluna

raw$n <- as.numeric(raw$n)
raw$tempo_clock_s <- suppressWarnings(as.numeric(raw$tempo_clock_s))
raw$tempo_wall_s  <- suppressWarnings(as.numeric(raw$tempo_wall_s))
raw$ok_ordenado   <- as.integer(raw$ok_ordenado)

n_timeout <- sum(is.na(raw$tempo_wall_s))
if (n_timeout > 0) {
  cat(sprintf("Aviso: %d linha(s) com 'timeout reached' ou valor nao numerico, excluidas da analise de tempo.\n", n_timeout))
}
raw_ok <- raw[!is.na(raw$tempo_wall_s), ]

if (any(raw_ok$ok_ordenado != 1)) {
  stop("ERRO: existe execucao marcada como NAO ordenada corretamente (ok_ordenado=0). Verificar dados antes de prosseguir.")
}

raw_ok$algoritmo <- factor(raw_ok$algoritmo, levels = c("qs", "radix"),
                            labels = c("Quicksort", "Radix Sort"))

## ---------------------------------------------------------------
## 2. Estatisticas descritivas por (algoritmo, n) - usa tempo_wall_s
##    (relogio de parede) como medida principal, pois clock() no
##    Windows/MinGW tem resolucao de ~1ms (CLOCKS_PER_SEC=1000), muito
##    mais grosseira que no Linux (~1us), tornando-o pouco informativo
##    para os tamanhos pequenos deste conjunto de dados.
## ---------------------------------------------------------------
agg <- aggregate(tempo_wall_s ~ algoritmo + n, data = raw_ok,
                  FUN = function(x) c(media = mean(x), sd = sd(x), n_rep = length(x)))
agg <- do.call(data.frame, agg)
names(agg) <- c("algoritmo", "n", "media_s", "sd_s", "n_rep")
agg$sd_s[is.na(agg$sd_s)] <- 0
agg <- agg[order(agg$algoritmo, agg$n), ]

write.csv(agg, "graficos_r/resumo_estatistico.csv", row.names = FALSE)
cat("=== Resumo estatistico (tempo de parede, segundos) ===\n")
print(agg, digits = 6)

## ---------------------------------------------------------------
## 3. Grafico 1: tempo medio vs n, escala log-log, com barras de +-1 sd
## ---------------------------------------------------------------
png("graficos_r/01_tempo_vs_n_loglog.png", width = 1400, height = 1000, res = 150)
par(mar = c(5, 5, 4, 2))

cores <- c("Quicksort" = "#D55E00", "Radix Sort" = "#0072B2")

qs <- agg[agg$algoritmo == "Quicksort", ]
rx <- agg[agg$algoritmo == "Radix Sort", ]

plot(qs$n, qs$media_s, log = "xy", type = "b", pch = 16, col = cores["Quicksort"],
     xlim = range(agg$n), ylim = range(c(agg$media_s - agg$sd_s, agg$media_s + agg$sd_s)[agg$media_s - agg$sd_s > 0], agg$media_s),
     xlab = "n (numero de elementos, escala log)",
     ylab = "tempo medio de execucao (s, escala log)",
     main = "Quicksort vs Radix Sort - tempo de execucao vs n\n(dados reais, Windows 11, i7-1355U, media de 1 a 7 repeticoes)",
     cex.main = 0.95)
lines(rx$n, rx$media_s, type = "b", pch = 17, col = cores["Radix Sort"])

arrows(qs$n, pmax(qs$media_s - qs$sd_s, 1e-7), qs$n, qs$media_s + qs$sd_s,
       angle = 90, code = 3, length = 0.03, col = cores["Quicksort"])
arrows(rx$n, pmax(rx$media_s - rx$sd_s, 1e-7), rx$n, rx$media_s + rx$sd_s,
       angle = 90, code = 3, length = 0.03, col = cores["Radix Sort"])

legend("topleft", legend = c("Quicksort (mediana-de-3, Hoare)", "Radix Sort (LSD, base 256)"),
       col = cores, pch = c(16, 17), lty = 1, bty = "n")
grid(equilogs = FALSE, col = "gray85")
dev.off()

## ---------------------------------------------------------------
## 4. Grafico 2: razao quicksort/radix vs n
## ---------------------------------------------------------------
merged <- merge(qs[, c("n", "media_s")], rx[, c("n", "media_s")], by = "n",
                 suffixes = c("_qs", "_radix"))
merged$razao <- merged$media_s_qs / merged$media_s_radix

png("graficos_r/02_razao_qs_radix.png", width = 1400, height = 1000, res = 150)
par(mar = c(5, 5, 4, 2))
plot(merged$n, merged$razao, log = "x", type = "b", pch = 16, col = "#009E73",
     xlab = "n (numero de elementos, escala log)",
     ylab = "razao tempo(quicksort) / tempo(radix sort)",
     main = "Quantas vezes o quicksort e mais lento que o radix sort, por n",
     cex.main = 0.95)
abline(h = 1, lty = 2, col = "gray50")
text(merged$n, merged$razao, labels = sprintf("%.1fx", merged$razao), pos = 3, cex = 0.7)
grid(equilogs = FALSE, col = "gray85")
dev.off()

## ---------------------------------------------------------------
## 5. Grafico 3: boxplot da variabilidade entre repeticoes (tamanhos
##    com >=3 repeticoes, para ilustrar dispersao real das medicoes)
## ---------------------------------------------------------------
tab_rep <- table(raw_ok$n, raw_ok$algoritmo)
ns_com_reps <- as.numeric(rownames(tab_rep)[apply(tab_rep, 1, min) >= 3])
raw_box <- raw_ok[raw_ok$n %in% ns_com_reps, ]
raw_box$grupo <- factor(paste0(formatC(raw_box$n, format = "d", big.mark = "."),
                                "\n", raw_box$algoritmo),
                         levels = unique(paste0(formatC(sort(ns_com_reps), format = "d", big.mark = "."),
                                                 "\n", rep(c("Quicksort", "Radix Sort"), each = length(ns_com_reps)))))

png("graficos_r/03_boxplot_variabilidade.png", width = 1600, height = 1000, res = 150)
par(mar = c(7, 5, 4, 2))
boxplot(tempo_wall_s ~ algoritmo + n, data = raw_box, log = "y",
        col = rep(c(cores["Quicksort"], cores["Radix Sort"])),
        las = 2, xlab = "", ylab = "tempo de parede (s, escala log)",
        main = "Variabilidade entre repeticoes (tamanhos com >=3 execucoes)",
        cex.axis = 0.8, cex.main = 0.95)
dev.off()

## ---------------------------------------------------------------
## 6. Regressao log-log: estima o expoente empirico de crescimento
##    tempo ~ n^k  =>  log(tempo) = log(a) + k*log(n)
##    Comparar k empirico com a teoria: quicksort ~ n log n (k pouco
##    acima de 1, crescendo lentamente com log n), radix ~ n (k ~ 1,
##    para n fixo de digitos/base, como e o caso aqui: 4 passadas fixas
##    para inteiros de 32 bits, independente de n).
## ---------------------------------------------------------------
sink("graficos_r/regressao.txt")
cat("=== Regressao log(tempo_parede) ~ log(n), por algoritmo ===\n\n")
for (alg in levels(agg$algoritmo)) {
  d <- agg[agg$algoritmo == alg & agg$media_s > 0, ]
  fit <- lm(log(media_s) ~ log(n), data = d)
  cat(sprintf("--- %s ---\n", alg))
  print(summary(fit))
  cat(sprintf("\nExpoente empirico k (tempo ~ n^k): %.4f (IC95%%: %.4f a %.4f)\n",
              coef(fit)[2], confint(fit)[2, 1], confint(fit)[2, 2]))
  cat(sprintf("R^2 ajustado: %.5f\n\n", summary(fit)$adj.r.squared))
}

cat("\n=== Teste pareado (Wilcoxon signed-rank, por n, tempo quicksort vs radix) ===\n")
cat("Cada repeticao usa a MESMA entrada para os dois algoritmos (par natural).\n\n")
pares <- merge(raw_ok[raw_ok$algoritmo == "Quicksort", c("n", "seed", "tempo_wall_s")],
               raw_ok[raw_ok$algoritmo == "Radix Sort", c("n", "seed", "tempo_wall_s")],
               by = c("n", "seed"), suffixes = c("_qs", "_radix"))
wt <- wilcox.test(pares$tempo_wall_s_qs, pares$tempo_wall_s_radix, paired = TRUE)
print(wt)
cat(sprintf("\nn de pares comparados: %d\n", nrow(pares)))
cat(sprintf("Quicksort foi mais lento que radix sort em %d de %d pares (%.1f%%).\n",
            sum(pares$tempo_wall_s_qs > pares$tempo_wall_s_radix), nrow(pares),
            100 * mean(pares$tempo_wall_s_qs > pares$tempo_wall_s_radix)))
sink()

cat(readLines("graficos_r/regressao.txt"), sep = "\n")

## ---------------------------------------------------------------
## 7. Grafico 4: tabela oficial da planilha (tempos_planilha_clock.csv)
##    cobre ate n=2e9 (sucesso) e documenta os tamanhos nao testados
##    (6e9, 8e9, 10e9) por limite de 'long int' de 32 bits no Windows
##    (modelo de dados LLP64) e por limite de RAM (16GB).
## ---------------------------------------------------------------
pl <- read.csv("tempos_planilha_clock.csv", sep = ";", stringsAsFactors = FALSE,
                check.names = FALSE, fileEncoding = "UTF-8-BOM")
names(pl)[1] <- "Algoritmo"
pl_long <- data.frame(label = character(0), n = numeric(0), algoritmo = character(0),
                       tempo_s = numeric(0), testado = logical(0))

label_to_n <- c("T(1E6)" = 1e6, "T(2E6)" = 2e6, "T(5E6)" = 5e6, "T(1E7)" = 1e7,
                 "T(2E7)" = 2e7, "T(5E7)" = 5e7, "T(1E8)" = 1e8, "T(2E8)" = 2e8,
                 "T(5E8)" = 5e8, "T(1E9)" = 1e9, "T(2E9)" = 2e9, "T(6E9)" = 6e9,
                 "T(8E9)" = 8e9, "T(10E9)" = 10e9)

for (i in 1:nrow(pl)) {
  alg <- pl[i, 1]
  for (lbl in names(label_to_n)) {
    if (lbl %in% names(pl)) {
      val <- pl[i, lbl]
      testado <- !grepl("mem", val, ignore.case = TRUE)
      tempo <- if (testado) as.numeric(val) else NA
      pl_long <- rbind(pl_long, data.frame(label = lbl, n = label_to_n[[lbl]],
                                            algoritmo = alg, tempo_s = tempo,
                                            testado = testado))
    }
  }
}
pl_long$algoritmo <- factor(pl_long$algoritmo, levels = c("Quicksort", "Radix Sort"))
write.csv(pl_long, "graficos_r/dados_planilha_oficial_long.csv", row.names = FALSE)

png("graficos_r/04_planilha_oficial_loglog.png", width = 1400, height = 1050, res = 150)
par(mar = c(5, 5, 6, 2))
pl_qs <- pl_long[pl_long$algoritmo == "Quicksort" & pl_long$testado, ]
pl_rx <- pl_long[pl_long$algoritmo == "Radix Sort" & pl_long$testado, ]
pl_qs <- pl_qs[order(pl_qs$n), ]
pl_rx <- pl_rx[order(pl_rx$n), ]

ylim_sup <- max(c(pl_qs$tempo_s, pl_rx$tempo_s)) * 3.5
plot(pl_qs$n, pl_qs$tempo_s, log = "xy", type = "b", pch = 16, col = cores["Quicksort"],
     xlim = range(label_to_n), ylim = c(min(c(pl_qs$tempo_s, pl_rx$tempo_s)), ylim_sup),
     xlab = "n (numero de elementos, escala log)", ylab = "tempo clock() (s, escala log)",
     main = "Tamanhos oficiais da planilha (ate 2 bilhoes) - uma execucao por ponto\nclock(), sem repeticao",
     cex.main = 0.9)
lines(pl_rx$n, pl_rx$tempo_s, type = "b", pch = 17, col = cores["Radix Sort"])
points(2e9, pl_rx$tempo_s[pl_rx$n == 2e9], pch = 8, col = "red", cex = 2)
text(2e9, pl_rx$tempo_s[pl_rx$n == 2e9] * 1.8, "radix fica mais\nlento que quicksort\n(pressao de memoria)",
     pos = 2, cex = 0.65, col = "red")
legend("topleft", legend = c("Quicksort", "Radix Sort"), col = cores, pch = c(16, 17), lty = 1, bty = "n")
grid(equilogs = FALSE, col = "gray85")
dev.off()

cat("\n\nGraficos e resumos gerados em ./graficos_r/\n")
