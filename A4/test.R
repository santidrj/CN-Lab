library(igraph)

g <- read.graph("EpidemicSpreading/ER.net", format = "pajek")
plot(g)