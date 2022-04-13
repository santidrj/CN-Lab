library(tools)
library(vecsets)
library(aricode)
library(igraph)

dir.create("figures", showWarnings = F)
dir.create("nets", showWarnings = F)
dir.create("results", showWarnings = F)

algorithms <- c("louvain", "infomap")

get.reference <- function(file) {
  file.name <- file_path_sans_ext(basename(file))
  name <- switch(
    file.name,
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
    
    
    aux.df <- data.frame(matrix(nrow = 0, ncol = 2))
    colnames(aux.df) <- c("File", "Modularity")
    pat <- sprintf("^%s.*\\.clu$", net.name)
    ref.modularity <- "-"
    modularity.file <- net.name
    for (ref.cluster in list.files(dirname(f), pattern = pat)) {
      if (grepl("rb125", net.name, fixed = T)) {
        modularity.file <- file_path_sans_ext(ref.cluster)
      }
      
      ref <- scan(
        file.path(dirname(f), ref.cluster),
        what = integer(),
        skip = 1,
        quiet = T
      )
      ref.modularity <- round(modularity(g, ref + 1), digits = 3)
      aux.df[nrow(aux.df) + 1, ] <-
        c(modularity.file, ref.modularity)
      df <- data.frame(matrix(nrow = 0, ncol = 3))
      colnames(df) <-
        c("Partition", "Modularity", "Reference Modularity")
      write.table(
        df,
        file = file.path(
          "results",
          paste(modularity.file, "_modularity", ".csv", sep = "")
        ),
        sep = ",",
        quote = F,
        row.names = F
      )
    }
    
    if (is.character(ref.modularity)) {
      aux.df[nrow(aux.df) + 1, ] <- c(net.name, "-")
    }
    
    
    for (algorithm in algorithms) {
      if (algorithm == "louvain") {
        lc <- cluster_louvain(g)
      }
      if (algorithm == "infomap") {
        lc <- cluster_infomap(g)
      }
      g.modularity <- round(modularity(lc), digits = 3)
      cat(sprintf(
        "%s modularity: %.3f\n",
        toTitleCase(algorithm),
        g.modularity
      ))
      g.membership <- membership(lc)
      
      out.file <-
        paste(net.name, "_", algorithm, sep = "")
      
      png(file.path("figures", paste(out.file, ".png", sep = "")))
      if (all(c("x", "y") %in% vertex_attr_names(g))) {
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
      
      for (row in 1:nrow(aux.df)) {
        out <- aux.df[row, "File"]
        ref.modularity <- aux.df[row, "Modularity"]
        
        df <-
          data.frame(toTitleCase(algorithm), g.modularity, ref.modularity)
        write.table(
          df,
          file.path("results", paste(out, "_modularity", ".csv", sep = "")),
          quote = F,
          row.names = F,
          col.names = F,
          sep = ",",
          append = T
        )
      }
    }
    cat("\n")
  }
}
