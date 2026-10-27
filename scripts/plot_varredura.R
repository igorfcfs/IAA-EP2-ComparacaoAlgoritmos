#!/usr/bin/Rscript --vanilla
# Grafico da varredura em N (varredura_n.sh): iteracoes de p+u e q+u para
# tolerancia fixa, com a previsao teorica k / (-log10 r) sobreposta.
# Estilo baseado em plots.R (Scripts do Professor).
args = commandArgs(trailingOnly=TRUE)

k = 10
if (length(args) > 0) k = as.numeric(args[1])

## Dataset

raw = read.table(paste("dados/varredura-", k, ".dat", sep = ""))
names(raw) = c("N", "iter_pu", "stall_pu", "time_pu", "iter_qu", "stall_qu", "time_qu")

s = sqrt(raw$N)
D = raw$N * (2*s + 1) * (s + 1)^2
r_p = 1 - 2*s/D
r_q = 1 - 2*s/(2*raw$N + 1)

mp = "p_k + u_k (Teo. 16.1.2 + babilônico)"
mq = "q_k + u_k (Teo. 16.1.3 + babilônico)"

df = rbind(
	data.frame(N = raw$N, iter = raw$iter_pu, teoria = k / -log10(r_p), metodo = mp),
	data.frame(N = raw$N, iter = raw$iter_qu, teoria = k / -log10(r_q), metodo = mq))
df$metodo = factor(df$metodo, levels = c(mp, mq))

## Plot using ggplot

# PNG parameters
w = 960
h = 648

library(ggplot2)

gg = ggplot(df, aes(N, iter, colour = metodo)) +
	geom_point(size = 1.5) +
	geom_line(aes(y = teoria), linetype = "dashed") +
	scale_y_log10() +
	scale_colour_manual(values = c("blue", "red"), name = NULL) +
	labs(title = paste("Iterações em função de N – erro menor que 1e-", k,
			" (tracejado: previsão k / (-log10 r))", sep = ""),
		x = "N (números que não são quadrados perfeitos)",
		y = "Número de iterações (escala log)") +
	theme_bw() +
	theme(plot.title = element_text(hjust = 0.5), legend.position = "bottom") +
	theme(plot.background = element_rect(fill = "cyan")) +
	theme(axis.line = element_line(linewidth = 2, colour = "grey80"))

png(paste("graficos/varredura-", k, ".png", sep = ""), width = w, height = h,
	unit = "px", pointsize = 12, res = 96)
plot(gg)
if (dev.cur()[1] != 1 && names(dev.list()) == "png") dev.off()

## EOF
