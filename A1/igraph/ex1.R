library(igraph)
library(dplyr)
library(xtable)

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

for (f in list.files(file.path("..", "A1-networks"), recursive = TRUE, full.names = TRUE)) {
  g <- read.graph(f, format = "pajek")
  g <- delete_edge_attr(g, "weight")
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
    list(
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
}

t <- t %>%
  replace(is.na(.), 0) %>%
  mutate(across(where(is.numeric), round, digits = 4))
  
write.csv(t, file = file.path("..", "results", "networks_descriptors_r.csv"), row.names = F)

t <- t %>%
  mutate(across(where(is.numeric), as.character))

print(
  xtable(t),
  type = "latex",
  file = file.path("..", "results", "networks_descriptors_latex_r.txt"),
  include.rownames = FALSE
)


