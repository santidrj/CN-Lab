library(tools)
library(igraph)

dir.create("figures", showWarnings = FALSE)

for (net in list.files(
  "A3-networks",
  pattern = "*.net",
  recursive = T,
  full.names = T
)) {
  net.name <- file_path_sans_ext(basename(net))
  p <- sprintf("^%s.*", gsub("\\+", "\\\\+", net.name))
  g <- read.graph(net, format = "pajek")
  for (clustering in list.files("nets", pattern = p, full.names = T)) {
    m <- scan(
      file.path(clustering),
      what = integer(),
      skip = 1,
      quiet = T
    ) %>% as_membership
    
    community <- make_clusters(g, m)
    
    out.file <- file_path_sans_ext(basename(clustering))
    
    png(file.path("figures", paste(out.file, ".png", sep = "")))
    if (all(c("x", "y") %in% vertex_attr_names(g))) {
      g$layout <- cbind(V(g)$x, V(g)$y)
      plot(
        community,
        g,
        vertex.label = NA,
        vertex.size = 5,
        edge.label = NA,
        edge.width = .01,
      )
    } else {
      plot(
        community,
        g,
        layout = layout_with_kk,
        vertex.label = NA,
        vertex.size = 5,
        edge.label = NA,
        edge.arrow.size = .1,
      )
    }
    dev.off()
  }
}
