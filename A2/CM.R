library(igraph)
library(fgpt)

N <- 10
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

slots <- NULL
for (i in 1:N) {
    slots <- c(slots, rep(i, degrees[i]))
}
slots <- fyshuffle(slots)

node_1 <- slots[seq(1, sum(degrees), 2)]
node_2 <- slots[seq(2, sum(degrees), 2)]
slots <- data.frame(node_1, node_2)

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

# g <- make_empty_graph(directed = F) + vertices(1:N)
# edges_list <- mapply(c, slots$node_1, slots$node_2, USE.NAMES = F, SIMPLIFY = F) %>%
#     unlist()
# g <- g + edges(edges_list)

# plot(g)