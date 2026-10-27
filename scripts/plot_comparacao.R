#!/usr/bin/Rscript --vanilla
# Graficos de comparacao entre os metodos p+u, q+u, u e q (Exercicios
# 16.2.5 a 16.2.7), a partir de dados/comparacao-N.dat (comparacao.sh).
# Estilo baseado em plots.R (Scripts do Professor).
args = commandArgs(trailingOnly=TRUE)

Ns = c(2, 24, 67)
if (length(args) > 0) Ns = as.numeric(args)

## Dataset

base = "dados"

cols = c("exp", "iter_pu", "stall_pu", "time_pu", "iter_qu", "stall_qu",
	"time_qu", "iter_u", "stall_u", "time_u", "iter_q", "stall_q", "time_q")

metodos = c(pu = "p_k + u_k (Teo. 16.1.2 + babilônico)",
	qu = "q_k + u_k (Teo. 16.1.3 + babilônico)",
	u = "u_k isolado (babilônico)",
	q = "q_k isolado (Teo. 16.1.3)")

df = NULL
for (N in Ns) {
	raw = read.table(paste(base, "/comparacao-", N, ".dat", sep = ""))
	names(raw) = cols
	for (m in names(metodos)) {
		df = rbind(df, data.frame(N = paste("N =", N), exp = raw$exp,
			iter = raw[[paste("iter", m, sep = "_")]],
			time = raw[[paste("time", m, sep = "_")]],
			stall = raw[[paste("stall", m, sep = "_")]],
			metodo = metodos[[m]]))
	}
}
df$N = factor(df$N, levels = paste("N =", Ns))
df$metodo = factor(df$metodo, levels = metodos)

## Plot using ggplot

xlab = "Expoente do erro (módulo)"
cores = c("blue", "red", "violetred", "darkorange")
formas = c(16, 17, 15, 4)

# PNG parameters
w = 960
h = 648

library(ggplot2)

estilo = function(gg, fundo) {
	gg + theme_bw() +
	theme(plot.title = element_text(hjust = 0.5), legend.position = "bottom") +
	theme(plot.background = element_rect(fill = fundo)) +
	theme(axis.line = element_line(linewidth = 2, colour = "grey80")) +
	guides(colour = guide_legend(nrow = 2), shape = guide_legend(nrow = 2))
}

gg = ggplot(df, aes(exp, iter, colour = metodo, shape = metodo)) +
	geom_line() + geom_point(size = 2) +
	geom_point(data = subset(df, stall == 1), shape = 1, size = 5,
		colour = "black", show.legend = FALSE) +
	scale_y_log10() +
	facet_wrap(~ N) +
	scale_colour_manual(values = cores, name = NULL) +
	scale_shape_manual(values = formas, name = NULL) +
	labs(title = "Iterações em função do erro – comparação dos métodos",
		x = xlab, y = "Número de iterações (escala log)")
gg = estilo(gg, "cyan")

png("graficos/comparacao-iter.png", width = w, height = h, unit = "px",
	pointsize = 12, res = 96)
plot(gg)
if (dev.cur()[1] != 1 && names(dev.list()) == "png") dev.off()

gg = ggplot(df, aes(exp, time, colour = metodo, shape = metodo)) +
	geom_line() + geom_point(size = 2) +
	scale_y_log10() +
	facet_wrap(~ N) +
	scale_colour_manual(values = cores, name = NULL) +
	scale_shape_manual(values = formas, name = NULL) +
	labs(title = "Tempo de execução (mediana) em função do erro – comparação dos métodos",
		x = xlab, y = "Tempo de execução em s (escala log)")
gg = estilo(gg, "pink1")

png("graficos/comparacao-time.png", width = w, height = h, unit = "px",
	pointsize = 12, res = 96)
plot(gg)
if (dev.cur()[1] != 1 && names(dev.list()) == "png") dev.off()

## EOF
