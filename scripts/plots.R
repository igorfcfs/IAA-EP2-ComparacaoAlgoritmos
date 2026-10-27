#!/usr/bin/Rscript --vanilla
args = commandArgs(trailingOnly=TRUE)

name = "sqrt-18"; N = 2
#name = "sqrt-18-24"; N = 24

if (length(args) > 0) name = args[1]

if (length(args) > 1) N = as.numeric(args[2])

  
## Dataset

base = "dados"

ndat = paste(name, "dat", sep = ".")
npng = paste(name, "png", sep = ".")

url = paste(base, ndat, sep = "/")

raw = read.table(url)

df = data.frame(raw)

names(df) = c("exp", "iter", "time")

err = 10**(-df$exp)


## Plot using ggplot

mlab = paste("Iterações em função do erro – Raiz quadrada de", N)
xlab = "Expoente do erro (módulo)"
ylab = "Número de iterações"

# PNG parameters
w = 960
h = 648

library(ggplot2)

gg = ggplot(df, aes(exp)) +
	geom_line(aes(y = iter), color = "grey") +
	geom_point(aes(y = iter), color = "blue") +
	labs(title = mlab, x = xlab, y = ylab) +
	theme_bw() +
	theme(plot.title = element_text(hjust = 0.5))

gg = gg +
	theme(plot.background = element_rect(fill = "cyan")) +
	theme(axis.line = element_line(linewidth = 2, colour = "grey80"))

npng = paste(name, "iter", sep = "-")
npng = paste("graficos/", npng, ".png", sep = "")

png(npng, width = w, height = h, unit = "px", pointsize = 12, res = 96)
plot(gg)
if (dev.cur()[1] != 1 && names(dev.list()) == "png") dev.off()

###

mlab = paste("Tempo de execução em função do erro – Raiz quadrada de", N)
ylab = "Tempo de execução"

gg = ggplot(df, aes(exp)) +
	geom_line(aes(y = time), color = "orangered") +
	geom_point(aes(y = time), color = "red") +
	labs(title = mlab, x = xlab, y = ylab) +
	theme_bw() +
	theme(plot.title = element_text(hjust = 0.5))

gg = gg +
	theme(plot.background = element_rect(fill = "pink1")) +
	theme(axis.line = element_line(linewidth = 2, colour = "grey80"))

npng = paste(name, "time", sep = "-")
npng = paste("graficos/", npng, ".png", sep = "")

png(npng, width = w, height = h, unit = "px", pointsize = 12, res = 96)
plot(gg)
if (dev.cur()[1] != 1 && names(dev.list()) == "png") dev.off()

## EOF
