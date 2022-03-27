library(igraph)

# Barabási & Albert model

N <- 10000
m <- 5

# Fix seed in order to make the results reproducible
set.seed(20)

if (N < 5) {
  g <- make_empty_graph(directed = F) + vertices(1:N) + path(1:N, 1)
} else {
  g <- make_empty_graph(directed = F) + vertices(1:5) + path(1:5, 1)
  for (i in 6:(N - 5)) {
    k <- degree(g)
    v <- V(g)
    selection <- sample(v, m, replace = F, prob = k / sum(k))
    g <- g + vertex(i)
    for (s in selection) {
      g <- g + edge(i, s)
    }
  }
}

stopifnot(mean(degree(g)) <= 20)

source("utils.R")
file.name <- paste("BA-", N, "-", m, sep = "")
if (N < 1000) {
  plot.graph(g, file.name)
} else {
  plot.hists(g, file.name)
  
  pdf.log.bins <- make.pdf.bins(degree(g))
  pdf.log.bins$pdf[pdf.log.bins$pdf != 0] <-
    log10(pdf.log.bins$pdf[pdf.log.bins$pdf != 0])
  lr <- lm(pdf.log.bins$pdf ~ pdf.log.bins$bins)
  pdf.alpha <- 1 - lr$coefficient[2]
  s1 <-
    sprintf("Alpha computed manually using the PDF: %f", pdf.alpha)
  
  log.bins <- make.ccdf.bins(degree(g))
  log.bins$ccdf[log.bins$ccdf != 0] <-
    log10(log.bins$ccdf[log.bins$ccdf != 0])
  lr <- lm(log.bins$ccdf ~ log.bins$bins)
  alpha <- 1 - lr$coefficient[2]
  s2 <-
    sprintf("Alpha computed manually using the CCDF: %f", alpha)
  
  
  s3 <-
    sprintf("Alpha using igraph: %f", power.law.fit(degree(g))$alpha)
  
  dir.create("results", showWarnings = F)
  writeLines(s1, file.path("results", paste(file.name, ".txt", sep = "")))
  write(s2,
        file.path("results", paste(file.name, ".txt", sep = "")),
        append = T,
        sep = "\n")
  write(s3,
        file.path("results", paste(file.name, ".txt", sep = "")),
        append = T,
        sep = "\n")
}
