#!/usr/bin/Rscript --vanilla
args = commandArgs(trailingOnly=TRUE)

name = "sqrt-18"; N = 2
#name = "sqrt-18-24"; N = 24

if (length(args) > 0) name = args[1]

if (length(args) > 1) N = as.numeric(args[2])

  
## Dataset

base = "dados"

ndat = paste(name, "dat", sep = ".")
npng = paste("graficos/", name, ".png", sep = "")

url = paste(base, ndat, sep = "/")

raw = read.table(url)

df = data.frame(raw)

names(df) = c("iter", "alg1", "alg2", "bab")


## Plot using ggplot

mlab = paste("Comparação de algoritmos – Raiz quadrada de", N)
xlab = "Número de iterações"
ylab = "Aproximações"

# PNG parameters
w = 960
h = 648

library(ggplot2)

gg = ggplot(df, aes(iter)) +
	geom_line(aes(y = alg1), color = "grey") +
	geom_point(aes(y = alg1), color = "blue") +
	geom_line(aes(y = alg2), color = "orangered") +	
	geom_point(aes(y = alg2), color = "red") +
	geom_line(aes(y = bab),  color = "lightblue") +	
	geom_point(aes(y = bab),  color = "violetred") +	
	#geom_line(aes(y = bab),  color = "green") +	
	#geom_point(aes(y = bab),  color = "darkgreen") +
	geom_hline(yintercept = sqrt(N), colour = "cyan") +
	labs(title = mlab, x = xlab, y = ylab) +
	theme_bw() +
	theme(plot.title = element_text(hjust = 0.5))

gg = gg +
	theme(plot.background = element_rect(fill = "cyan")) +
	theme(axis.line = element_line(linewidth = 2, colour = "grey80"))

png(npng, width = w, height = h, unit = "px", pointsize = 12, res = 96)
plot(gg)
if (dev.cur()[1] != 1 && names(dev.list()) == "png") dev.off()

## EOF
