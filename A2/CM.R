library(igraph)
library(fgpt)
library(dplyr)
library(poweRlaw)

N <- 100
k <- 4              # parameter in Poisson distribution
alpha <- 3.5          # parameter power-law distributions
xmin <- 1
P <- "poisson"

# Fix seed in order to make the results of N >= 1000 reproducible
# set.seed(10)

sample_dist <- function(dist_name) {
  if (dist_name == "poisson") {
    return(rpois(N, k))
  }
  if (dist_name == "power-law") {
    return(rpldis(N, xmin, alpha))
  }
}

selection.prob <- function(x) {
  return(1 - length(V(x)) / N)
}

repeat {
  degrees <- sample_dist(P)
  if (sum(degrees) %% 2 == 0) {
    break
  }
}

final.slots <- data.frame()
free.slots <- data.frame(degrees)
free.slots$node <- 1:nrow(free.slots)
aux.degrees <- degrees
stall.iter <- 0

repeat {
  slots <- NULL
  for (i in 1:N) {
    if (degrees[i] > 0) {
      slots <- c(slots, rep(i, degrees[i]))
    }
  }
  slots <- fyshuffle(slots)
  
  node_1 <- slots[seq(1, sum(degrees), 2)]
  node_2 <- slots[seq(2, sum(degrees), 2)]
  
  # Remove multi-edges and self-loops
  slots <- rbind(data.frame(node_1, node_2), final.slots) %>%
    filter(node_1 != node_2) %>%
    group_by(grp = paste(pmax(node_1, node_2), pmin(node_1, node_2), sep = "_")) %>%
    slice(1) %>%
    ungroup() %>%
    select(-grp)
  
  
  # Count the number of stubs that will not be free any more
  selected.slots <-
    full_join(count(slots, node_1),
              count(slots, node_2),
              by = c("node_1" = "node_2"))
  selected.slots$count <-
    rowSums(selected.slots[, c(2, 3)], na.rm = T)
  free.slots <-
    left_join(free.slots, selected.slots[c('node_1', 'count')], by = c("node" = "node_1"))
  free.slots[is.na(free.slots)] <- 0
  
  # Get the remaining free stubs for each node
  old.degrees <- degrees
  degrees <- free.slots$degrees - free.slots$count
  free.slots <- subset(free.slots, select = -c(count))
  
  if (all(old.degrees == degrees)) {
    stall.iter <- stall.iter + 1
  }
  
  # If there are no more free stubs we exit the loop else,
  # if there are more free stubs than nodes we undo the changes and start again
  if (sum(degrees != 0) <= 0) {
    final.slots <- slots
    print("Exit loop")
    break
  } else if ((sum(degrees) / 2 >= sum(degrees != 0)) ||
             stall.iter > 10) {
    print("Undo last changes and try again")
    degrees <- aux.degrees
    final.slots <- data.frame()
    free.slots <- data.frame(degrees)
    free.slots$node <- 1:nrow(free.slots)
    stall.iter <- 0
  } else {
    print("Remaining slots for each node")
    print(degrees)
    sprintf("Total remaining slots %d", sum(degrees))
    sprintf("Stall iterations %d", stall.iter)
    final.slots <- slots
  }
  
}

g <- make_empty_graph(directed = F) + vertices(1:N)
edges_list <-
  mapply(
    c,
    final.slots$node_1,
    final.slots$node_2,
    USE.NAMES = F,
    SIMPLIFY = F
  ) %>%
  unlist()
g <- g + edges(edges_list)

# To avoid disconnected components in the network we randomly select pairs of
# disconnected components and add a new edge between them until the network
# is fully connected.
components <- decompose(g)
while (length(components) > 1) {
  prob <- lapply(components, selection.prob)
  comp <- sample(components, 2, replace = F, prob = prob)
  vertices1 <- V(comp[[1]])
  vertices2 <- V(comp[[2]])
  if (length(vertices1) > 1) {
    v1 <- sample(V(comp[[1]]), 1, replace = F)
  } else {
    v1 <- vertices1
  }
  
  if (length(vertices2) > 1) {
    v2 <- sample(V(comp[[2]]), 1, replace = F)
  } else {
    v2 <- vertices2
  }
  g <- g + edge(v1$name, v2$name)
  components <- decompose(g)
}

stopifnot(mean(degree(g)) <= 20)

if (P == "poisson") {
  fn <- paste(P, "-", N, "-", k, sep = "")
} else if (P == "power-law") {
  fn <- paste(P, "-", N, "-", alpha, sep = "")
}

source("utils.R")
file.name <- paste("CM-", fn, sep = "")
if (N < 1000) {
  plot.graph(g, file.name)
} else {
  plot.hists(g, file.name, lambda = k, log.log = (P == "power-law"), xmin = xmin, alpha = alpha)
  if (P == "power-law") {
    pdf.log.bins <- make.pdf.bins(degree(g))
    pdf.log.bins$pdf[pdf.log.bins$pdf != 0] <-
      log10(pdf.log.bins$pdf[pdf.log.bins$pdf != 0])
    lr <- lm(pdf.log.bins$pdf ~ pdf.log.bins$bins)
    pdf.alpha <- 1 - lr$coefficient[2]
    s1 <- sprintf("Alpha computed manually using the PDF: %f", pdf.alpha)
    
    log.bins <- make.ccdf.bins(degree(g))
    log.bins$ccdf[log.bins$ccdf != 0] <-
      log10(log.bins$ccdf[log.bins$ccdf != 0])
    lr <- lm(log.bins$ccdf ~ log.bins$bins)
    alpha <- 1 - lr$coefficient[2]
    s2 <- sprintf("Alpha computed manually using the CCDF: %f", alpha)
    
    
    s3 <-
      sprintf("Alpha using igraph: %f", power.law.fit(degree(g))$alpha)
    
  s4 <-
    sprintf("Alpha using MLE: %f", MLE.alpha(degree(g)))
  
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
  write(s4,
        file.path("results", paste(file.name, ".txt", sep = "")),
        append = T,
        sep = "\n")
  }
}
