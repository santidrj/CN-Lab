library(igraph)


# networks <- c("ER5000k8.net")
networks <- c("ER5000k8.net", "SF_1000_g2.7.net", "ws1000.net", "airports_UW.net", "PGP.net")


for (f in list.files(file.path("..", "A1-networks"), recursive = TRUE, full.names = TRUE)) {
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
    
    power<-power.law.fit(k)
    print(power$KS.p)

    net.name = tools::file_path_sans_ext(basename(f))
    plots.path = file.path("..", "results", "histograms_r")

    png(file=file.path(plots.path, paste(net.name, "_PDF.png", sep="")))
    hist <- hist(k, breaks = n.bins)
    hist$counts <- hist$counts/sum(hist$counts)
    #---
    # Check the sum of probability and density
    # print("----------------------------")
    # print(net.name)
    # print(paste("probability sum:", sum(hist$counts)))
    # print(paste("density sum:", sum(hist$density)))
    #---
    plot(hist, main = "PDF", ylab="probability", xlab="degree")
    dev.off()

    png(file=file.path(plots.path, paste(net.name, "_CCDF.png", sep="")))
    cum.hist <- hist(k, breaks = n.bins, plot=FALSE)
    cum.hist$counts <- cum.hist$counts / sum(cum.hist$counts)
    cum.hist$counts <- rev(cumsum(rev(cum.hist$counts)))
    plot(cum.hist, main = "CCDF", ylab = "pobability", xlab = "degree")
    lines(1:20,10*(1:20)^((-power$alpha)+1))
    dev.off()


    png(file=file.path(plots.path, paste(net.name, "_PDF_log.png", sep="")))
    hist <- hist(log.k, breaks = n.bins)
    hist$counts <- hist$counts/sum(hist$counts)
    #---
    # Check the sum of probability and density
    # print("----------------------------")
    # print(net.name)
    # print(paste("probability sum:", sum(hist$counts)))
    # print(paste("density sum:", sum(hist$density)))
    #---
    plot(hist, main = "PDF", ylab="probability", xlab="log10(degree)")
    dev.off()

    png(file=file.path(plots.path, paste(net.name, "_CCDF_log.png", sep="")))
    cum.hist <- hist(log.k, breaks = n.bins, plot=FALSE)
    cum.hist$counts <- cum.hist$counts / sum(cum.hist$counts)
    cum.hist$counts <- rev(cumsum(rev(cum.hist$counts)))
    plot(cum.hist, main = "CCDF", ylab = "pobability", xlab = "log10(degree)")
    lines(1:20,10*(1:20)^((-power$alpha)+1))
    dev.off()

  }
}
