library(igraph)
library(fgpt)
library(dplyr)

N <- 50
k <- 5              # necessary for Poisson distribution
P <- "poisson"

sample_dist <- function(dist_name) {
  if (dist_name == "poisson") {
    return(rpois(N, k))
  }
  if (dist_name == "power-law") {
    # TODO: return sampling from a power-law distribution
    return()
  }
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
    # degrees <- free.slots$degrees
    print(sum(degrees))
    final.slots <- slots
    print("Exit loop")
    break
  } else if ((sum(degrees) / 2 >= sum(degrees != 0)) || stall.iter > 10) {
    # Reset variables
    degrees <- aux.degrees
    final.slots <- data.frame()
    free.slots <- data.frame(degrees)
    free.slots$node <- 1:nrow(free.slots)
    stall.iter <- 0
  } else {
    # degrees <- free.slots$degrees
    print(sum(degrees))
    print(degrees)
    print(stall.iter)
    final.slots <- slots
  }
  
}

# TODO: remove multiedges and self-loops
# The approach below is too slow.
# Instead of shuffling the whole colum when we
# find multiedges or self-loops, we should swap
# conflictive, individual values by other ones in the column and recheck

# repeat {
#     slots <- data.frame(node_2 = apply(slots, 1, min), node_1 = apply(slots, 1, max))   # so we can detect multiedges of type 1 2, 2 1
#     print("hello")
#     multiedges <- slots %>%
#         duplicated() %>%
#         any()
#     self_loops <- any(slots$node_1 == slots$node_2)
#     if (multiedges | self_loops) {
#         slots$node_1 <- sample(slots$node_1)
#         } else {
#             break
#         }
# }

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

stopifnot(mean(degree(g)) <= 20)

plots.path = "figures"

png(
  file = file.path(plots.path, paste("CM-", N, "-", k, ".png", sep = "")),
  width = 10,
  height = 10,
  units = "cm",
  res = 1200,
  pointsize = 4
)
plot(g, layout = layout_with_kk, vertex.size=5, vertex.label = NA)
dev.off()

png(file = file.path(
  plots.path,
  paste("Degree-distribution-CM-", N, "-", k, ".png", sep = "")
))
plot(
  degree.distribution(g, cumulative = T),
  type = 'h',
  # log = 'y',
  lwd = 20,
  lend = 1,
  col = 'gray',
  main = "PDF",
  xlab = "Degree k",
  ylab = "P(k)",
)
dev.off()
