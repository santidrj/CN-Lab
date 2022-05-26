import random
import networkx as nx
import math
import matplotlib.pyplot as plt

random.seed(10)

def subset_net(net, lines, n_lines=10):
    # sub_lines = random.sample(lines, n_lines)
    # sub_net = nx.DiGraph(((u, v, e) for u, v, e in net.edges(data=True)
    #                       if any(map(lambda v: v in e['lines'], sub_lines))))
    sub_net = nx.DiGraph(((u, v, e) for u, v, e in net.edges(data=True)
                          if any(map(lambda v: v in e['lines'], lines))))
    return sub_net


def subset_lines(connections, n_lines):
    while True:
        subset = []
        max_iter = 100
        group = list(connections.keys())
        while len(subset) < n_lines and max_iter > 0:
            line = random.choice(group)
            if connections[line]:
                group = connections[line] + [line]
                subset = list(set(subset + random.sample(group, min(len(group), n_lines-len(subset)))))
            max_iter -= 1
        if len(subset) >= n_lines:
            break
    return subset


def mean_path_subnets(net, connections, n_subnets, min_lines=10, max_lines=100):
    mean_path = []
    N = []
    step = (max_lines-min_lines) // n_subnets
    n_lines = min_lines
    i = 0
    for i in range(n_subnets):
        i += 1
        print(i)
        print(f"Computing subset of {n_lines} lines...")
        lines = subset_lines(connections, n_lines)
        print("Computing subnet...")
        sub_net = subset_net(net, lines)
        components = nx.number_weakly_connected_components(sub_net)
        print("Computing mean path...")
        mean_path.append(nx.average_shortest_path_length(sub_net))
        N.append(sub_net.number_of_nodes())
        n_lines += step
    print("Done with subnets.")
    print("Computing mean path of the whole network...")
    mean_path.append(nx.average_shortest_path_length(net))
    N.append(net.number_of_nodes())
    return N, mean_path


