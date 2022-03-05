library(igraph)
library(tibble)
library(dplyr)
library(xtable)

airports <-
  c(
    "PAR",
    "LON",
    "FRA",
    "AMS",
    "MOW",
    "NYC",
    "ATL",
    "BCN",
    "WAW",
    "CHC",
    "DJE",
    "ADA",
    "AGU",
    "TBO",
    "ZVA"
  )
g <-
  read_graph(file.path("..", "A1-networks", "real", "airports_UW.net"), format = "pajek")
g2 <- delete_edge_attr(g, "weight")

d <- degree(g2, V(g2)[airports])
s <- strength(g, V(g)[airports])
cc <- transitivity(g2, type = "local", vids = V(g2)[airports])
dists <- distances(g2, V(g2)[airports])
apl <-  rowMeans(dists)
mpl <-  apply(dists, 1, max)
e <- eigen_centrality(g2)$vector[airports]
b <- betweenness(g2, V(g2)[airports], normalized = TRUE)
pr <- page.rank(g2, vids = V(g2)[airports], directed = FALSE)$vector

t <-
  data.frame(
    "Degree" = d,
    "Stength" = s,
    "Clustering coefficient" = cc,
    "Average path length" = apl,
    "Maximum path length" = mpl,
    "Betweenness" = b,
    "Eigenvector centrality" = e,
    "PageRank" = pr
  )

t <- rownames_to_column(t, "Airport")
t <- t %>%
  replace(is.na(.), 0) %>%
  mutate(across(where(is.numeric), round, digits = 8)) %>%
  mutate(across(where(is.numeric), as.character))
print(
  xtable(t),
  type = "latex",
  file = file.path("results", "airports_descriptors_latex_r.txt"),
  include.rownames = FALSE
)
