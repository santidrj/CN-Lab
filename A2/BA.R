library(igraph)

# Barabási & Albert model

N <- 100
m <- 1

if (N < 5) {
  g <- make_empty_graph(directed = F) + vertices(1:N) + path(1:N, 1)
} else {
  g <- make_empty_graph(directed = F) + vertices(1:5) + path(1:5, 1)
  for (i in 6:(N-5)) {
    k <- degree(g)
    v <- V(g)
    g <- g + vertex(i) + edge(i, sample(v, m, replace = F, prob = k/sum(k)))
  }
}

plot(g)
