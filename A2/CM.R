library(igraph)
library(fgpt)
library(dplyr)
library(poweRlaw)

N <- 50
k <- 5              # parameter in Poisson distribution
alpha <- 3          # parameter power-law distributions
P <- "power-law"

sample_dist <- function(dist_name) {
  if (dist_name == "poisson") {
    return(rpois(N, k))
  }
  if (dist_name == "power-law") {
    return(rpldis(N, xmin = 1, alpha))
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
  v1 <- sample(V(comp[[1]]), 1, replace = F)
  v2 <- sample(V(comp[[2]]), 1, replace = F)
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
if (N < 1000) {
  plot.graph(g, paste("CM-", fn, sep = ""))
} else {
  plot.hists(g, paste("CM-", fn, sep = ""))
}
