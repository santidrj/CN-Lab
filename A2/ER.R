library(igraph)
library(dplyr)

# Erdős-Rényi model

N <- 50
K <- 200

# Fix seed in order to make the results of N >= 1000 reproducible
set.seed(20)

stopifnot(K <= N * (N - 1) / 2)

g <- make_empty_graph(directed = F) + vertices(1:N)


pairs <- expand.grid(1:N, 1:N) %>%
  filter(Var1 != Var2) %>%
  group_by(grp = paste(pmax(Var1, Var2), pmin(Var1, Var2), sep = "_")) %>%
  slice(1) %>%
  ungroup() %>%
  select(-grp)

final.edges <-
  sample(mapply(
    c,
    pairs$Var1,
    pairs$Var2,
    USE.NAMES = F,
    SIMPLIFY = F
  ), K)

g <- g + edges(unlist(final.edges))

sprintf("Average degree of G: %d", ceiling(mean(degree(g))))

stopifnot(mean(degree(g)) <= 20)

source("utils.R")
file.name <- paste("ER-", N, "-", K, sep = "")
if (N < 1000) {
  plot.graph(g, file.name)
} else {
  p = 2 * K / (N * (N - 1))
  n.bins <- length(unique(degree(g)))
  plot.hists(g,
             file.name,
             lambda = N * p,
             log.log = F)
}

if (N <= 1000) {
  dir.create("networks", showWarnings = F)
  write.graph(g, file.path("networks", paste(file.name, ".net", sep = "")), format = "pajek")
}