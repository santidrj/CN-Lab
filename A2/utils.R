library(igraph)
library(poweRlaw)

plot.graph <- function(g, net.name) {
  plots.path = file.path("figures")
  png(
    file = file.path(plots.path, paste(net.name, ".png", sep = "")),
    width = 10,
    height = 10,
    units = "cm",
    res = 1200,
    pointsize = 4
  )
  plot(g,
       layout = layout_with_kk,
       vertex.size = 5,
       vertex.label = NA)
  dev.off()
}

plot.binomial <- function(n, p) {
  success <- 0:20
  
  plots.path = file.path("figures", "histograms_r")
  png(file = file.path(plots.path, paste("Binomial_", N,"_", p, ".png", sep = "")))
  plot(success,dbinom(success,size=n,prob=n),
       type='h',
       main= paste('Binomial Distribution (n=', n,' p=', p, ')'),
       ylab='Probability',
       xlab ='The degree k',
       lwd=3)
  dev.off()
}

plot.poisson <- function(lambda) {
  success <- 0:20
  
  plots.path = file.path("figures", "histograms_r")
  png(file = file.path(plots.path, paste("Poisson_", lambda, ".png", sep = "")))
  plot(success,dpois(success,lambda),
       type='h',
       main= paste('Poisson Distribution (lamda=', lambda, ')'),
       ylab='Probability',
       xlab ='The degree k',
       lwd=3)
  dev.off()
}

plot.power.law <- function(xmin, alpha) {
  x = xmin:100
  plots.path = file.path("figures", "histograms_r")
  png(file = file.path(plots.path, paste("Power-law_", alpha, ".png", sep = "")))
  plot(x,dpldis(x,xmin, alpha),
       type='l',
       main= paste('Power-law Distribution (alpha=', alpha, ')'),
       ylab='Probability',
       xlab ='The degree k',
       log = 'xy')
  dev.off()
}

plot.hists <- function(g, net.name, log_log = TRUE) {
  k <- degree(g)
  unique.degrees <- length(unique(unname(k)))
  if (unique.degrees < 10)
    n.bins <- 10
  else if (unique.degrees > 30)
    n.bins <- 30
  else
    n.bins <- unique.degrees
  
  plots.path = file.path("figures", "histograms_r")
  dir.create(plots.path, showWarnings = F)
  
  aux.seq = seq(-1000, 1000, 2000)
  
  png(file = file.path(plots.path, paste(net.name, "_PDF.png", sep = "")))
  hist <- hist(k, breaks = n.bins)
  hist$counts <- hist$counts / sum(hist$counts)
  
  plot(
    hist,
    main = "PDF",
    ylab = "P(k)",
    xlab = "k",
    col = "gray",
    border = "white",
    axes = F
  )
  axis(1)
  axis(1, at = aux.seq)
  axis(2)
  axis(2, at = aux.seq)
  
  dev.off()
  
  png(file = file.path(plots.path, paste(net.name, "_CCDF.png", sep =
                                           "")))
  cum.hist <- hist(k, breaks = n.bins, plot = FALSE)
  cum.hist$counts <- cum.hist$counts / sum(cum.hist$counts)
  cum.hist$counts <- rev(cumsum(rev(cum.hist$counts)))
  plot(
    cum.hist,
    main = "CCDF",
    ylab = "P(k)",
    xlab = "k",
    col = "gray",
    border = "white",
    axes = F
  )
  axis(1)
  axis(1, at = aux.seq)
  axis(2)
  axis(2, at = aux.seq)
  dev.off()
  
  if (log_log) {
    log.k <- log(k, 10)
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
    
    
    
    
    
    png(file = file.path(plots.path, paste(net.name, "_PDF_log.png",
                                           sep = "")))
    ylim <- c(1e-4, 1)
    yticks <- 10 ^ seq(-5L, 1L, 1L)
    plot(
      bins,
      prob.log.k,
      log = 'y',
      type = 'h',
      lwd = 10,
      lend = 2,
      col = 'gray',
      main = "PDF",
      axes = F,
      ylab = "P(K)",
      xlab = "log(k)",
      ylim = ylim
    )
    axis(1)
    axis(1, at = aux.seq)
    axis(2,
         at = yticks,
         labels = parse(text = paste("10^", as.integer(log10(
           yticks
         )), sep = "")))
    dev.off()
    
    
    png(file = file.path(plots.path, paste(net.name, "_CCDF_log.png", sep =
                                             "")))
    ylim <- c(1e-4, 1)
    yticks <- 10 ^ seq(-5L, 1L, 1L)
    plot(
      bins,
      rev(cumsum(rev(prob.log.k))),
      log = 'y',
      type = 'h',
      lwd = 10,
      lend = 2,
      col = 'gray',
      main = "CCDF",
      ylab = "P(k)",
      xlab = "log10(k)",
      axes = F,
      ylim = ylim
    )
    axis(1)
    axis(1, at = aux.seq)
    axis(2,
         at = yticks,
         labels = parse(text = paste("10^", as.integer(log10(
           yticks
         )), sep = "")))
    dev.off()
  }
}