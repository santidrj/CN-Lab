library(igraph)
library(poweRlaw)

MLE.alpha <- function(k) {
  min.k <- min(k)
  n <- length(k)
  aux <- log(k / (min.k - 1 / 2))
  return(1 + n / sum(aux))
}

WS.dist <- function(degrees, K, p) {
  
  K2 <- K / 2

  if (min(degrees) < K2) {
    print("ERROR: Minimum degree must be equal or larger than mean degree divided by two")
    return(NULL)
  }
  arg.sum <- function(k, n) {
    term1 <- choose(K2, n)
    term2 <- (1 - p) ^ n
    term3 <- p ^ (K2 - n)
    term4num <- (p * K2) ^ (k - K2 - n)
    term4den <- factorial(k - K2 - n)
    term5 <- exp(-p * K2)
    return(term1 * term2 * term3 * (term4num / term4den) * term5)
  }

  P <- NULL
  for (k in degrees) {
    f.k.K <- min(k - K2, K2)
    Pk <- 0
    for (n in 0:f.k.K) {
      Pk <- Pk + arg.sum(k, n)
    }
    P <- append(P, Pk)
  }

  return(P)
}

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

plot.binomial <- function(n, p, n.bins) {
  if (n.bins < 10)
    n.bins <- 10
  else if (n.bins > 30)
    n.bins <- 30
  
  success <- 0:n.bins
  
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

plot.poisson <- function(lambda, n.bins) {
  if (n.bins < 10)
    n.bins <- 10
  else if (n.bins > 30)
    n.bins <- 30
  
  x <- rpois(1000, lambda)
  
  x <- rpois(1000, 0.5 * 100)
  dp <- function(x, lmd = lambda) dpois(x, lambda = lmd)
  
  plots.path = file.path("figures", "histograms_r")
  png(file = file.path(plots.path, paste("Poisson_", lambda, ".png", sep = "")))
  curve(dp, from = 0, to = 20,
       main= paste('Poisson Distribution (lamda=', lambda, ')'),
       ylab='Probability',
       xlab ='The degree k',
       lwd=2)
  dev.off()
}

plot.power.law <- function(xmin, alpha) {
  x = xmin:100
  plots.path = file.path("figures", "histograms_r")
  # plot.loglog.hist(dpldis(x, xmin, alpha), plots.path, paste("Power-law_", alpha, sep = ""))
  png(file = file.path(plots.path, paste("Power-law_", alpha, ".png", sep = "")))
  plot(x, dpldis(x,xmin, alpha),
       type='l',
       main= paste('Power-law Distribution (alpha=', alpha, ')'),
       ylab='Probability',
       xlab ='The degree k',
       log = 'xy',
       )
  dev.off()
}

make.pdf.bins <- function(x, min.bins = 10, max.bins = 30) {
  unique.values <- length(unique(x))
  if (unique.values < min.bins)
    n.bins <- 10
  else if (unique.values > max.bins)
    n.bins <- 30
  else
    n.bins <- unique.values
  
  log.x <- log(x, 10)
  min.x <- min(x)
  max.x <- max(x)
  step <- (log(max.x + 1, 10) - log(min.x, 10)) / (n.bins - 1)
  bins <- seq(log(min.x, 10), log(max.x + 1, 10), step)
  bin.count <- vector(length = n.bins)
  
  counted <- 0
  for (i in 1:(n.bins)) {
    count <- sum(log.x >= bins[i] & log.x < bins[i + 1])
    bin.count[i] <- count
    counted <- counted + count
  }
  bin.count[n.bins] <- length(x) - counted
  prob.log.x <- bin.count / sum(bin.count)
  
  return(list(bins = bins, pdf = prob.log.x))
}

make.ccdf.bins <- function(x, min.bins = 10, max.bins = 30) {
  pdf.bins <- make.pdf.bins(x, min.bins, max.bins)
  return(list(bins = pdf.bins$bins, ccdf = rev(cumsum(rev(pdf.bins$pdf)))))
}

plot.loglog.hist <- function(k, plots.path, net.name, xmin = 1, alpha = 3) {
  log.bins <- make.pdf.bins(k)
  bins <- log.bins$bins
  prob.log.k <- log.bins$pdf
  
  aux.seq = seq(-1000, 1000, 2000)

  png(file = file.path(plots.path, paste(net.name, "_PDF_log.png",
                                         sep = "")))

  ylim <- c(1e-6, 1)
  yticks <- 10 ^ seq(-5L, 1L, 1L)
  x <- xmin:100
  dist <- dpldis(x,xmin, alpha)
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
  par(new = T)
  plot(log(x), dist, log='y', type = 'l', ylim=ylim, axes = F, ylab = "", xlab = "")
  axis(1)
  axis(1, at = aux.seq)
  axis(2,
       at = yticks,
       labels = parse(text = paste("10^", as.integer(log10(
         yticks
       )), sep = "")))

  dev.off()
  
  png(file = file.path(plots.path, paste(net.name, "_CCDF_log.png", sep = "")))
  ylim <- c(1e-6, 1)
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
  par(new = T)
  plot(log(x), dist, log = "y", type = "l", ylim = ylim, axes = F, ylab = "", xlab = "")
  axis(1)
  axis(1, at = aux.seq)
  axis(2,
       at = yticks,
       labels = parse(text = paste("10^", as.integer(log10(
         yticks
       )), sep = "")))
  
  dev.off()
}

plot.loglog.hist2 <- function(k, plots.path, net.name, n.bins, xmin = 1, alpha = 3) {

  log.k = seq(from = log10(min(k)), to = log10(max(k)), length.out = n.bins)
  hist <- hist(k, breaks = 10^log.k)
  hist$counts <- hist$counts / sum(hist$counts)
  
  aux.seq = seq(-1000, 1000, 2000)

  png(file = file.path(plots.path, paste(net.name, "_PDF_log.png",
                                         sep = "")))

  ylim <- c(1e-6, 1)
  yticks <- 10 ^ seq(-5L, 1L, 1L)
  dist <- dpldis(10^log.k, xmin, alpha)
  
plot(
    log.k[1:n.bins - 1],
    hist$counts,
    log = 'y',
    type = 'h',
    lwd = 10,
    lend = 2,
    col = 'gray',
    main = "PDF",
    ylab = "P(k)",
    xlab = "log10(k)",
    axes = F,
    #ylim = c(0, max(hist$counts) + 0.05),
    ylim = ylim
  )
  par(new = T)
  plot(log.k, dist, log="y", type = "l", ylim = ylim, axes = F, ylab = "", xlab = "")
  axis(1)
  axis(1, at = aux.seq)
  axis(2,
       at = yticks,
       labels = parse(text = paste("10^", as.integer(log10(
         yticks
       )), sep = "")))

  dev.off()
  
  png(file = file.path(plots.path, paste(net.name, "_CCDF_log.png", sep = "")))
  ylim <- c(1e-6, 1)
  yticks <- 10 ^ seq(-5L, 1L, 1L)
  plot(
    log.k[1:n.bins - 1],
    rev(cumsum(rev(hist$counts))),
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
  par(new = T)
  plot(log.k, dist, log = "y", type = "l", ylim = ylim, axes = F, ylab = "", xlab = "")
  axis(1)
  axis(1, at = aux.seq)
  axis(2,
       at = yticks,
       labels = parse(text = paste("10^", as.integer(log10(
         yticks
       )), sep = "")))
  
  dev.off()
}

plot.hists <- function(g, net.name, lambda = NA, log.log = TRUE, xmin = 1, alpha = 3,  ws.dist = FALSE, K = NA, p = NA) {
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
    axes = F,
    ylim = c(0, max(hist$counts) + 0.05),
  )
  
  if (!is.na(lambda) && !log.log) {
    lines(dpois(0:1000, lambda), col = "blue", yaxt = "n", xaxt = "n")
  }
  if (ws.dist) {
    x <- min(k):max(k)
    lines(x, WS.dist(x, K, p), col = "blue", yaxt = "n", xaxt = "n")
  }
  
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
  
  if (log.log)  {
    plot.loglog.hist2(k, plots.path, net.name,  n.bins, xmin, alpha)
    #plot.loglog.hist(k, plots.path, net.name, C, alpha)
  }
}