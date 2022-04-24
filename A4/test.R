library(igraph)

g <- read.graph("EpidemicSpreading/src/epidemicspreading/networks/BA-500-5-4.net", format = "pajek")
plot(g)