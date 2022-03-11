library(igraph)


# networks <- c("ER5000k8.net")
networks <-
  c("ER5000k8.net",
    "SF_1000_g2.7.net",
    "ws1000.net",
    "airports_UW.net",
    "PGP.net")


for (f in list.files(file.path("..", "A1-networks"),
                     recursive = TRUE,
                     full.names = TRUE)) {
  if (basename(f) %in% networks) {
    g <- read.graph(f, format = "pajek")
    k <- degree(g)
    log.k <- log(k, 10)
    
    unique.degrees <- length(unique(unname(k)))
    if (unique.degrees < 10)
      n.bins <- 10
    else if (unique.degrees > 30)
      n.bins <- 30
    else
      n.bins <- unique.degrees
    
    min.k <- min(k)
    max.k <- max(k)
    step <- (log(max.k + 1, 10) - log(min.k, 10)) / (n.bins - 1)
    bins <- seq(log(min.k, 10), log(max.k + 1, 10), step)
    bin.count <- vector(length = n.bins)
    counted <- 0
    for (i in 1:(n.bins)) {
      count <- sum(log.k >= bins[i] & log.k < bins[i + 1])
      bin.count[i] <- count
      counted <- counted + count
    }
    bin.count[n.bins] <- length(k) - counted
    prob.log.k <- bin.count / sum(bin.count)
    
    
    net.name = tools::file_path_sans_ext(basename(f))
    plots.path = file.path("..", "results", "histograms_r")
    
    png(file = file.path(plots.path, paste(net.name, "_PDF.png", sep = "")))
    hist <- hist(k, breaks = n.bins)
    hist$counts <- hist$counts / sum(hist$counts)
    #---
    # Check the sum of probability and density
    # print("----------------------------")
    # print(net.name)
    # print(paste("probability sum:", sum(hist$counts)))
    # print(paste("density sum:", sum(hist$density)))
    #---
    plot(hist,
         main = "PDF",
         ylab = "probability",
         xlab = "degree")
    dev.off()
    
    png(file = file.path(plots.path, paste(net.name, "_PDF_log.png", sep =
                                             "")))
    plot(
      prob.log.k,
      log = 'y',
      type = 'h',
      lwd = 10,
      lend = 2,
      col = 'gray',
      main = "PDF",
      axes = F,
      ylab = "log(P(K))",
      xlab = "log(K)"
    )
    axis(1, at = seq(1, length(bin.count), by = 1), labels = bins)
    axis(2)
    dev.off()
    
    png(file = file.path(plots.path, paste(net.name, "_CCDF.png", sep =
                                             "")))
    cum.hist <- hist(k, breaks = n.bins, plot = FALSE)
    cum.hist$counts <- cum.hist$counts / sum(cum.hist$counts)
    cum.hist$counts <- rev(cumsum(rev(cum.hist$counts)))
    plot(cum.hist,
         main = "CCDF",
         ylab = "probability",
         xlab = "degree")
    dev.off()
    
    png(file = file.path(plots.path, paste(net.name, "_CCDF_log.png", sep =
                                             "")))
    plot(
      rev(cumsum(prob.log.k)),
      log = 'y',
      type = 'h',
      lwd = 10,
      lend = 2,
      col = 'gray',
      main = "CCDF",
      ylab = "log(P(K))",
      xlab = "log(K)",
      axes = F
    )
    axis(1, at = seq(1, length(bin.count), by = 1), labels = bins)
    axis(2)
    dev.off()
    
    # png(file = file.path(plots.path, paste(net.name, "_PDF_log.png", sep =
    #                                          "")))
    # hist <- hist(log.k, breaks = n.bins)
    # hist$counts[hist$counts > 0] <-
    #   abs(log(hist$counts[hist$counts > 0] / sum(hist$counts)))
    #---
    # Check the sum of probability and density
    # print("----------------------------")
    # print(net.name)
    # print(paste("probability sum:", sum(hist$counts)))
    # print(paste("density sum:", sum(hist$density)))
    #---
    # plot(hist,
    #      main = "PDF",
    #      ylab = "probability",
    #      xlab = "log10(degree)")
    # dev.off()
    
    # png(file = file.path(plots.path, paste(net.name, "_CCDF_log.png", sep =
    #                                          "")))
    # cum.hist <- hist(log.k, breaks = n.bins, plot = FALSE)
    # cum.hist$counts <- cum.hist$counts / sum(cum.hist$counts)
    # cum.hist$counts <- rev(cumsum(rev(cum.hist$counts)))
    # plot(cum.hist,
    #      main = "CCDF",
    #      ylab = "probability",
    #      xlab = "log10(degree)")
    # dev.off()
    
  }
}
