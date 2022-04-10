library(tools)
library(vecsets)
library(aricode)
library(igraph)

jaccard <- function(a, b) {
  intersection = length(vintersect(a, b))
  union = length(a) + length(b) - intersection
  return (intersection / union)
}

dir.create("figures", showWarnings = F)
dir.create("nets", showWarnings = F)

for (f in list.files(file.path("A3-networks", "toy"),
                     recursive = TRUE,
                     full.names = TRUE)) {
  file.name <- basename(f)
  if (file_ext(file.name) == "net") {
    g <- read.graph(f, format = "pajek")
    lc <- cluster_louvain(g)
    mod <- modularity(lc)
    s1 <- sprintf("Modularity: %f", mod)
    m <- membership(lc)
    g$layout <- cbind(V(g)$x, V(g)$y)
    
    png(file.path("figures", paste(
      file_path_sans_ext(file.name), ".png", sep = ""
    )))
    plot(lc, g, vertex.size = 5,  edge.arrow.size = .2)
    dev.off()
    
    df <- data.frame(x = as.numeric(m))
    name <- paste("*Vertices", length(V(g)))
    colnames(df) <- c(name)
    write.table(df,
                file.path("nets", paste(
                  file_path_sans_ext(file.name), ".clu", sep = ""
                )),
                quote = F,
                row.names = F)
    
    ref.cluster <- paste(file_path_sans_ext(f), "clu", sep = ".")
    
    if (file.exists(ref.cluster)) {
      ref <- scan(ref.cluster,
                  what = integer(),
                  skip = 1,
                  quiet = T)
      # TODO: Compute modularity of the reference
      ji <- jaccard(m, ref)
      nmi <- NMI(as.vector(m), as.vector(ref), variant = "sum")
      nvi <- NVI(as.vector(m), as.vector(ref))
      if (ji == 1) {
        nmi <- if (!is.na(nmi))
          nmi
        else
          1
        nvi <- if (!is.na(nvi))
          nvi
        else
          1
      }
      s2 <- sprintf("Jaccard index: %f", ji)
      s3 <- sprintf("Normalized Mutual of Information: %f", nmi)
      s4 <- sprintf("Normalized Variation of Information: %f", nvi)
      cat(paste(s2, s3, s4, "\n", sep = "\n"))
      
      # TODO: Save measures to a latex table
      # TODO: Save modularity comparison to a latex table
    }
  }
}
