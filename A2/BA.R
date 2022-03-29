library(igraph)

# Barabási & Albert model

N <- 1000
m <- 5

if (N < 5) {
  g <- make_full_graph(N, directed = F)
} else {
  g <- make_full_graph(5, directed = F)
  for (i in 6:(N - 5)) {
    k <- degree(g)
    v <- V(g)
    selection <- sample(v, m, replace = F, prob = k / sum(k))
    g <- g + vertex(i)
    for (s in selection) {
      g <- g + edge(i, s)
    }
  }
}

stopifnot(mean(degree(g)) <= 20)

source("utils.R")
if (N < 1000) {
  plot.graph(g, paste("BA-", N, "-", m, sep = ""))
} else {
  plot.power.law(1, 3)
  plot.hists(g, paste("BA-", N, "-", m, sep = ""))
  log.bins <- make.ccdf.bins(degree(g))
  log.bins$ccdf[log.bins$ccdf != 0] <- log10(log.bins$ccdf[log.bins$ccdf != 0])
  lr <- lm(log.bins$ccdf ~ log.bins$bins)
  alpha <- 1 - lr$coefficient[2]
  print(sprintf("Alpha computed manually using the CCDF: %f", alpha))
  print(sprintf("Alpha using igraph: %f", power.law.fit(degree(g))$alpha))
}
