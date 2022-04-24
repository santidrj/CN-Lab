library(tools)
library(igraph)

dir.create("partitions", showWarnings = F)
dir.create("results", showWarnings = F)

algorithms <- c("louvain", "infomap")

for (f in list.files(
  file.path("A3-networks"),
  pattern = "*.net",
  recursive = TRUE,
  full.names = TRUE
)) {
  file.name <- basename(f)
  net.name <- file_path_sans_ext(file.name)
  cat("Network: ", net.name, "\n")
  
  g <- read.graph(f, format = "pajek")
  
  old.modularity <- data.frame(matrix(nrow = 0, ncol = 3))
  colnames(old.modularity) <-
    c("Partition", "Modularity", "Reference Modularity")
  
  aux.df <- data.frame(matrix(nrow = 0, ncol = 3))
  colnames(aux.df) <- c("File", "Ref Modularity", "Girvan Modularity")
  
  pat <- sprintf("^%s.*\\.clu$", gsub("\\+", "\\\\+", net.name))
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
    ref.modularity <- round(modularity(g, ref + 1), digits = 4)
    out.table <- file.path("results",
                           paste(modularity.file, "_modularity", ".csv", sep = ""))
    
    df <- data.frame(matrix(nrow = 0, ncol = 3))
    colnames(df) <-
      c("Partition", "Modularity", "Reference Modularity")
    girvan.m <- NA
    if (file.exists(out.table)) {
      old.modularity <- read.csv(out.table)
      if (any(old.modularity$Partition == "Girvan-Newman")) {
        # df[nrow(df) + 1, ] <-
        #   old.modularity[old.modularity$Partition == "Girvan-Newman", ]
        girvan.m <- old.modularity[old.modularity$Partition == "Girvan-Newman",]$Modularity
      }
    }
    aux.df[nrow(aux.df) + 1,] <-
      c(modularity.file, ref.modularity, girvan.m)
    
    write.table(
      df,
      file = out.table,
      sep = ",",
      quote = F,
      row.names = F
    )
  }
  
  if (is.character(ref.modularity)) {
    out.table <- file.path("results",
                           paste(modularity.file, "_modularity", ".csv", sep = ""))
    df <- data.frame(matrix(nrow = 0, ncol = 3))
    colnames(df) <-
      c("Partition", "Modularity", "Reference Modularity")
    
    girvan.m <- NA
    if (file.exists(out.table)) {
      old.modularity <- read.csv(out.table)
      if (any(old.modularity$Partition == "Girvan-Newman")) {
        # df[nrow(df) + 1, ] <-
        #   old.modularity[old.modularity$Partition == "Girvan-Newman", ]
        girvan.m <- old.modularity[old.modularity$Partition == "Girvan-Newman",]$Modularity
      }
    }
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
    aux.df[nrow(aux.df) + 1,] <- c(net.name, "-", girvan.m)
  }
  
  
  # Community detection
  count <- 1
  for (algorithm in algorithms) {
    if (algorithm == "louvain") {
      lc <- cluster_louvain(g)
    }
    if (algorithm == "infomap") {
      lc <- cluster_infomap(g)
    }
    g.modularity <- round(modularity(lc), digits = 4)
    cat(sprintf(
      "%s modularity: %.4f\n",
      toTitleCase(algorithm),
      g.modularity
    ))
    g.membership <- membership(lc)
    
    # Save communities
    out.file <-
      paste(net.name, "_", algorithm, sep = "")
    
    df <- data.frame(x = as.numeric(g.membership))
    name <- paste("*Vertices", length(V(g)))
    colnames(df) <- c(name)
    write.table(df,
                file.path("partitions", paste(out.file, ".clu", sep = "")),
                quote = F,
                row.names = F)
    
    # Save modularity
    for (row in 1:nrow(aux.df)) {
      out <- aux.df[row, "File"]
      ref.modularity <- aux.df[row, "Ref Modularity"]
      girvan.m <- aux.df[row, "Girvan Modularity"]
      
      cat("Reference modularity:", ref.modularity, "\n")
      df <-
        data.frame(toTitleCase(algorithm), g.modularity, ref.modularity)
      
      #Write Girvan-Newman at the end of the table
      if (!is.na(girvan.m) && count == length(algorithms)) {
        df[nrow(df) + 1,] <- c("Girvan-Newman", girvan.m, ref.modularity)
      }
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
    count <- count + 1
  }
  cat("\n")
}
