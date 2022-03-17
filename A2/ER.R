library(igraph)
library(dplyr)

# Erdős-Rényi model

N <- 50
K <- 100

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

sprintf("Average degree of G: %d", mean(degree(g)))
stopifnot(mean(degree(g)) <= 20)

plots.path = "figures"

png(
  file = file.path(plots.path, paste("ER-", N, "-", K, ".png", sep = "")),
  width = 10,
  height = 10,
  units = "cm",
  res = 1200,
  pointsize = 4
)
plot(g, layout = layout_nicely, vertex.size=5, vertex.label = NA)
dev.off()

png(file = file.path(
  plots.path,
  paste("Degree-distribution-ER-", N, "-", K, ".png", sep = "")
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