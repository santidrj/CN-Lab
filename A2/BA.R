library(igraph)

# Barabási & Albert model

N <- 50
m <- 2

if (N < 5) {
  g <- make_empty_graph(directed = F) + vertices(1:N) + path(1:N, 1)
} else {
  g <- make_empty_graph(directed = F) + vertices(1:5) + path(1:5, 1)
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

plots.path = "figures"

png(
  file = file.path(plots.path, paste("BA-", N, "-", m, ".png", sep = "")),
  width = 10,
  height = 10,
  units = "cm",
  res = 1200,
  pointsize = 4
)
plot(g, layout = layout_nicely, vertex.size=5)
dev.off()

png(file = file.path(
  plots.path,
  paste("Degree-distribution-BA-", N, "-", m, ".png", sep = "")
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