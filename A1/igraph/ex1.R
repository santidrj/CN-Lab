library(igraph)
library(dplyr)
library(xtable)

list.files("A1-networks", recursive = TRUE)

header <- c(
  "Network",
  "#nodes",
  "#edges",
  "Max degree",
  "Min degree",
  "Avg. degree",
  "Avg. cluster coefficient",
  "Assortativity",
  "Avg. path length",
  "Diameter"
)
t <- data.frame(matrix(nrow = 0, ncol = length(header)))
colnames(t) <- header

for (f in list.files("A1-networks", recursive = TRUE, full.names = TRUE)) {
  g <- read.graph(f, format = "pajek")
  number_nodes <- gorder(g)
  number_links <- gsize(g)
  degree <- degree(g)
  max_degree <- max(degree)
  min_degree <- min(degree)
  avg_degree <- mean(degree)
  avg_cluster_coef <- transitivity(g, type = "average")
  assortativity <- assortativity.degree(g, directed = FALSE)
  avg_path_length <- average.path.length(g, directed = FALSE)
  diameter <- diameter(g, directed = FALSE)
  t[nrow(t) + 1, ] <-
    c(
      tools::file_path_sans_ext(basename(f)),
      number_nodes,
      number_links,
      max_degree,
      min_degree,
      avg_degree,
      avg_cluster_coef,
      assortativity,
      avg_cluster_coef,
      diameter
    )
  print("Row added")
}

t <- t %>%
  replace(is.na(.), 0) %>%
  mutate(across(where(is.numeric), round, digits = 4)) %>%
  mutate(across(where(is.numeric), as.character))

print(
  xtable(t),
  type = "latex",
  file = file.path("results", "networks_descriptors_latex_r.txt"),
  include.rownames = FALSE
)

