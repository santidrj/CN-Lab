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

algorithm <- "louvain"

get.reference <- function(file) {
  file.name <- file_path_sans_ext(basename(file))
  name <- switch(file.name, 
                 "dolphins" = "dolphins-real.clu",
                 "football" = "football-conferences.clu",
                 "zachary_unwh" = "zachary_unwh-real.clu",
                paste(file.name, "clu", sep = ".")
                 )
  return(file.path(dirname(file), name))
}

for (f in list.files(file.path("A3-networks"),
                     recursive = TRUE,
                     full.names = TRUE)) {
  file.name <- basename(f)
  if (file_ext(file.name) == "net") {
    cat("Network: ", file_path_sans_ext(file.name), "\n")
    g <- read.graph(f, format = "pajek")
    lc <- cluster_louvain(g)
    g.modularity <- modularity(lc)
    s1 <- sprintf("Modularity: %f", g.modularity)
    g.membership <- membership(lc)
    
    out.file <-
      paste(file_path_sans_ext(file.name), "_", algorithm, sep = "")
    
    png(file.path("figures", paste(out.file, ".png", sep = "")))
    if (all(c("x", "y") %in% vertex_attr_names(g))) {
      cat("The network has coordinates\n")
      g$layout <- cbind(V(g)$x, V(g)$y)
      plot(lc,
           g,
           vertex.size = 5,
           edge.arrow.size = .2)
    } else {
      plot(
        lc,
        g,
        layout = layout_with_kk,
        vertex.size = 5,
        edge.arrow.size = .2
      )
    }
    dev.off()
    
    df <- data.frame(x = as.numeric(g.membership))
    name <- paste("*Vertices", length(V(g)))
    colnames(df) <- c(name)
    write.table(df,
                file.path("nets", paste(out.file, ".clu", sep = "")),
                quote = F,
                row.names = F)
    
    # ref.cluster <- paste(file_path_sans_ext(f), "clu", sep = ".")
    ref.cluster <- get.reference(f)
    
    cat(sprintf("Modularity: %f\n", g.modularity))
    
    if (file.exists(ref.cluster)) {
      ref <- scan(ref.cluster,
                  what = integer(),
                  skip = 1,
                  quiet = T)
      ref.modularity <- modularity(g, ref+1)
      cat(sprintf("Reference modularity: %f\n", ref.modularity))
      ji <- jaccard(g.membership, ref)
      nmi <-
        NMI(as.vector(g.membership), as.vector(ref), variant = "sum")
      nvi <- NVI(as.vector(g.membership), as.vector(ref))
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
      cat(paste(s2, s3, s4, sep = "\n"))
      cat("\n")
      
      # TODO: Save measures to a latex table
      # TODO: Save modularity comparison to a latex table
    }
    cat("\n")
  }
}
