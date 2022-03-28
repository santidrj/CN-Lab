library(igraph)
library(dplyr)

# Erdős-Rényi model

N <- 10000
K <- 20000

# Fix seed in order to make the results reproducible
set.seed(20)

stopifnot(K <= N*(N-1)/2)

g <- make_empty_graph(directed = F) + vertices(1:N)


pairs <- expand.grid(1:N, 1:N) %>%
  filter(Var1 != Var2) %>% 
  group_by(grp = paste(pmax(Var1, Var2), pmin(Var1, Var2), sep = "_")) %>%
  slice(1) %>%
  ungroup() %>%
  select(-grp)

final.edges <- sample(mapply(c, pairs$Var1, pairs$Var2, USE.NAMES = F, SIMPLIFY = F), K)

g <- g + edges(unlist(final.edges))

sprintf("Average degree of G: %d", ceiling(mean(degree(g))))

stopifnot(mean(degree(g)) <= 20)

source("utils.R")
if (N < 1000) {
  plot.graph(g, paste("ER-", N, "-", K, sep = ""))
} else {
  p = 2 * K / (N*(N-1))
  n.bins <- length(unique(degree(g)))
  plot.hists(g, paste("ER-", N, "-", K, sep = ""), lambda=N*p, log.log=F)
}
