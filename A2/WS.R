library(igraph)

# Watts-Strogatz model

# DELETE DELETE
# algorithm based on:
# https://en.wikipedia.org/wiki/Watts%E2%80%93Strogatz_model#Algorithm
# DELETE DELETE

N <- 10
k <- 4
p <- 0.5

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

stopifnot(mean(degree(g)) <= 20)

plots.path = "figures"

png(
  file = file.path(plots.path, paste("WS-", N, "-", k, "-", p, ".png", sep = "")),
  width = 10,
  height = 10,
  units = "cm",
  res = 1200,
  pointsize = 4
)
plot(g, layout = layout_with_kk, vertex.size=5, vertex.label = NA)
dev.off()

png(file = file.path(
  plots.path,
  paste("Degree-distribution-WS-", N, "-", k, "-", p, ".png", sep = "")
))
plot(
  degree.distribution(g, cumulative = T),
  type = 'h',
  # log = 'y',
  lwd = 20,
  lend = 1,
  col = 'gray',
  main = "PDF",
  xlab = "Degree k",
  ylab = "P(k)",
)
dev.off()