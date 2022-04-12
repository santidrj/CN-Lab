library(tools)
library(vecsets)
library(aricode)
library(igraph)

# jaccard <- function(a, b) {
#   intersection = length(vintersect(a, b))
#   union = length(a) + length(b) - intersection
#   return (intersection / union)
# }

dir.create("figures", showWarnings = F)
dir.create("nets", showWarnings = F)
dir.create("results", showWarnings = F)

algorithms <- c("louvain", "infomap")

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
    net.name <- file_path_sans_ext(file.name)
    cat("Network: ", net.name, "\n")

    g <- read.graph(f, format = "pajek")

    if (all(c("x", "y") %in% vertex_attr_names(g))) {
      cat("The network has coordinates\n")
    }

    # ref.cluster <- paste(file_path_sans_ext(f), "clu", sep = ".")
    ref.cluster <- get.reference(f)

    if (file.exists(ref.cluster)) {
      ref <- scan(ref.cluster,
        what = integer(),
        skip = 1,
        quiet = T
      )
      ref.modularity <- round(modularity(g, ref + 1), digits = 3)

      cat(sprintf("Reference modularity: %.3f\n", ref.modularity))

      # ji <- jaccard(g.membership, ref)
      # nmi <-
      #   NMI(as.vector(g.membership), as.vector(ref), variant = "sum")
      # nvi <- NVI(as.vector(g.membership), as.vector(ref))
      # if (ji == 1) {
      #   nmi <- if (!is.na(nmi))
      #     nmi
      #   else
      #     1
      #   nvi <- if (!is.na(nvi))
      #     nvi
      #   else
      #     1
      # }
      # s2 <- sprintf("Jaccard index: %f", ji)
      # s3 <- sprintf("Normalized Mutual of Information: %f", nmi)
      # s4 <- sprintf("Normalized Variation of Information: %f", nvi)
      # cat(paste(s2, s3, s4, sep = "\n"))
      # cat("\n")
    } else {
      ref.modularity <- "-"
      cat("Reference modularity: -\n")
    }

    df <- data.frame(matrix(nrow = 0, ncol = 3))
    colnames(df) <- c("Partition", "Modularity", "Reference Modularity")
    write.table(df,
      file = file.path("results", paste(net.name, "_modularity", ".csv", sep = "")),
      sep = ",",
      quote = F,
      row.names = F
    )

    for (algorithm in algorithms) {
      if (algorithm == "louvain") {
        lc <- cluster_louvain(g)
      }
      if (algorithm == "infomap") {
        lc <- cluster_infomap(g)
      }
      g.modularity <- round(modularity(lc), digits = 3)
      cat(sprintf("%s modularity: %.3f\n", toTitleCase(algorithm), g.modularity))
      g.membership <- membership(lc)
      
      out.file <-
        paste(net.name, "_", algorithm, sep = "")
      
      png(file.path("figures", paste(out.file, ".png", sep = "")))
      if (all(c("x", "y") %in% vertex_attr_names(g))) {
        #cat("The network has coordinates\n")
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
 
      df <- data.frame(toTitleCase(algorithm), g.modularity, ref.modularity)
      write.table(df,
        file.path("results", paste(net.name, "_modularity", ".csv", sep = "")),
        quote = F,
        row.names = F,
        col.names = F,
        sep = ",",
        append = T
      )
    }
  cat("\n")
  }
}
