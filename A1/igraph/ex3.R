library(igraph)


# networks <- c("ER5000k8.net")
networks <- c("ER5000k8.net", "SF_1000_g2.7.net", "ws1000.net", "airports_UW.net", "PGP.net")


for (f in list.files(file.path("..", "A1-networks"), recursive = TRUE, full.names = TRUE)) {
  if (basename(f) %in% networks) {
    g <- read.graph(f, format = "pajek")
    degree.dist <- degree.distribution(g)
    n.bins <- if (length(degree.dist) <= 30) length(degree.dist) else 30
    k <- degree(g)
    min.k <- min(k)
    max.k <- max(k)
    log.k <- log(k)
    step <- (log(max.k + 1) - log(min.k)) / (n.bins - 1)
    bins <- seq(log(min.k), log(max.k + 1), step)
    bin.count <- vector(length = n.bins)
    counted <- 0
    for (i in 1:(n.bins)) {
      count <- sum(log.k >= bins[i] & log.k < bins[i + 1])
      bin.count[i] <- count
      counted <- counted + count
    }
    bin.count[n.bins] <- length(k) - counted
    
    hist(k, breaks = n.bins, probability = T, main = "Linear PDF")
    
    # create x-axis labels
    bar.names <- round(bins, digits = 2)
    # create positions for tick marks, one more than number of bars
    at_tick <- seq_len(n.bins + 1)
    # plot without axes
    barplot(bin.count, space = 0, names.arg = bar.names, main = "log-log PDF", axes = F)
    # add y-axis
    axis(side = 2, pos = -0.2)
    # add x-axis with offset positions, with ticks, but without labels.
    axis(side = 1, at = at_tick - 1, labels = FALSE)
    
    barplot(degree.dist, space = 0, main = "log-log PDF using igraph", axes = F)
    at_tick <- seq(0, length(degree.dist) + 1, by = length(degree.dist)/10)
    axis(side = 2, pos = -1)
    axis(side = 1, at = at_tick - 1, labels = at_tick)
  }
}
