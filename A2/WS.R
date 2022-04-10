library(igraph)

# Watts-Strogatz model

N <- 1000
k <- 6
p <- 0.5

# Fix seed in order to make the results of N >= 1000 reproducible
set.seed(20)

stopifnot((k %% 2) == 0)
stopifnot(k <= 20)
stopifnot(k < N)

g <- make_empty_graph(directed = F) + vertices(1:N)
for (i in 1:N) {
  for (j in 1:N) {
    aux <- abs(i - j) %% (N - 1 - (k / 2))
    if (0 < aux & aux <= (k / 2)) {
      g <- g + edge(i, j)
    }
  }
}

g <- simplify(g)

if (p > 0) {
  for (i in 1:N) {
    for (j in (i + 1):(i + (k / 2))) {
      if (j == N) {
        curr_edge <- paste(i, "|", j, sep = "")
      } else {
        curr_edge <- paste(i, "|", j %% N, sep = "")
      }
      g <- delete.edges(g, curr_edge)
      repeat {
        selection <- sample(1:N, 1, replace = F, prob = rep(p, N))
        if (!g[i, selection] & selection != i) {
          g <- g + edge(i, selection)
          break
        }
      }
    }
  }
}

stopifnot(mean(degree(g)) <= 20)

source("utils.R")
file.name <- paste("WS-", N, "-", k, "-", p, sep = "")
if (N < 1000) {
  plot.graph(g, file.name)
} else {
  plot.hists(
    g,
    file.name,
    log.log = FALSE,
    ws.dist = TRUE,
    K = k,
    p = p
  )
}

if (N <= 1000) {
  dir.create("networks", showWarnings = F)
  write.graph(g, file.path("networks", paste(file.name, ".net", sep = "")), format = "pajek")
}
