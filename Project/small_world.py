import random
import time

import networkx as nx
import numpy as np
import os
import pickle
import matplotlib.pyplot as plt
import pandas as pd
from networkx import NetworkXNoPath
from pprint import pprint

seed = None
if seed:
    random.seed(seed)


def subset_net(net, lines):
    sub_net = nx.DiGraph(((u, v, e) for u, v, e in net.edges(data=True)
                          if any(map(lambda l: l in e["lines"], lines))))
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
                subset = list(set(subset + random.sample(group, min(len(group), n_lines - len(subset)))))
            max_iter -= 1
        if len(subset) >= n_lines:
            break
    return subset


def generate_subnets(net, connections, n_subnets, n_reps, min_lines=10, max_lines=100):
    mean_diameter = []
    mean_N = []
    for j in range(n_reps):
        print(f"Subset of sub-nets #{j}")
        diameter = []
        N = []
        step = (max_lines - min_lines) // n_subnets
        n_lines = min_lines
        # i = 0
        for i in range(n_subnets):
            # i += 1
            # print(i)
            while True:
                print(f"Computing subset of {n_lines} lines...")
                lines = subset_lines(connections, n_lines)
                # print("Computing subnet...")
                sub_net = subset_net(net, lines)
                if seed or nx.number_weakly_connected_components(sub_net) == 1:
                    break
            # print("Computing mean path...")
            diameter.append(nx.diameter(sub_net.to_undirected()))
            N.append(sub_net.number_of_nodes())
            n_lines += step
        mean_diameter.append(diameter)
        mean_N.append(N)
    # print("Done with subnets.")
    mean_diameter = np.mean(mean_diameter, axis=0)
    mean_N = np.mean(mean_N, axis=0)
    # print("Computing mean path of the whole network...")
    np.append(mean_diameter, nx.average_shortest_path_length(net))
    np.append(mean_N, net.number_of_nodes())
    return mean_N, mean_diameter


def plot_diameter_N(net, connections, out_folder="", load=False, n_reps=100):
    if load and os.path.exists(os.path.join(out_folder, "diameter_N.pkl")):
        f = open(os.path.join(out_folder, "diameter_N.pkl"), "rb")
        diameter_N = pickle.load(f)
        N, diameter = list(diameter_N.keys()), list(diameter_N.values())
    else:
        if seed:
            n_reps = 1
        N, diameter = generate_subnets(net, connections, 20, min_lines=20, n_reps=n_reps)
        f = open(os.path.join(out_folder, "diameter_N.pkl"), "wb")
        pickle.dump(dict(zip(N, diameter)), f)
        f.close()
    fit = np.polyfit(np.log10(N), diameter, 1)
    fig = plt.figure()
    plt.plot(N, diameter, "ko-")
    plt.plot(N, fit[0] * np.log10(N) + fit[1], "k-")
    plt.xscale("log")
    plt.xlabel(r"$N$", fontsize=15)
    plt.ylabel(r"$D(N)$", fontsize=15)
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)
    plt.savefig(os.path.join(out_folder, "diameter_N.png"))
    plt.show()


def shortest_routes(net, lines):
    # Obtain the shortest path using Dijkstra's algorithm
    # paths = dict(nx.all_pairs_dijkstra_path(G, weight="weight"))
    transhipment_dict = {}
    path_length_dict = {}
    # i = 0
    for source in net.nodes:
        # i += 1
        # print(f"Node {i}/{len(net.nodes)}")
        for target in net.nodes:
            if target == source:
                continue
            try:
                for path in nx.all_shortest_paths(net, source, target, None, "dijkstra"):
                    previous_lines = lines[(path[0], path[1], 0)]
                    current_stop = path[1]
                    transhipments_count = 0
                    for next_stop in path[2:]:
                        bus_lines = lines[(current_stop, next_stop, 0)]
                        if np.all(bus_lines != previous_lines):
                            transhipments_count += 1
                            previous_lines = bus_lines
                        current_stop = next_stop
                    transhipment_dict[(source, target)] = transhipment_dict.get((source, target), [])
                    (transhipment_dict[(source, target)]).append(transhipments_count)
                    # print(f"Shortest path: {len(path)}")
                    # print(f"Number of transhipments: {transhipments_count}")
                try:
                    path_length_dict[(source, target)] = len(path)
                except NameError:
                    path_length_dict[(source, target)] = np.inf
                # print(transhipment_dict[(source, target)])
            except NetworkXNoPath as e:
                print(e)
    # pprint(transhipment_dict)
    return transhipment_dict, path_length_dict


def plot_shortest_routes(net, lines, out_folder="", load=False):
    if load \
            and os.path.exists(os.path.join(out_folder, "transhipment_dict.pkl")) \
            and os.path.exists(os.path.join(out_folder, "path_length_dict.pkl")):
        f = open(os.path.join(out_folder, "transhipment_dict.pkl"), "rb")
        transhipment_dict = pickle.load(f)
        f.close()
        f = open(os.path.join(out_folder, "path_length_dict.pkl"), "rb")
        path_length_dict = pickle.load(f)
        f.close()
    else:
        transhipment_dict, path_length_dict = shortest_routes(net, lines)
        f = open(os.path.join(out_folder, "transhipment_dict.pkl"), "wb")
        pickle.dump(transhipment_dict, f)
        f.close()
        f = open(os.path.join(out_folder, "path_length_dict.pkl"), "wb")
        pickle.dump(path_length_dict, f)
        f.close()
    fig = plt.figure()
    unique_lengths, counts_lengths = np.unique(list(path_length_dict.values()), return_counts=True)
    plt.plot(unique_lengths, counts_lengths / sum(counts_lengths), "ko-", ms=5)
    plt.xlabel(r"$L$", fontsize=15)
    plt.ylabel(r"$P(L)$", fontsize=15)
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=10)
    plt.savefig(os.path.join(out_folder, "path_lengths.png"))
    plt.show()

    fig = plt.figure()
    trans_dict_simple = {k: min(transhipment_dict[k]) for k in transhipment_dict.keys()}
    unique_trans, counts_trans = np.unique(list(trans_dict_simple.values()), return_counts=True)
    plt.plot(unique_trans, counts_trans / sum(counts_trans), "ko-", ms=5)
    plt.xlabel(r"$n_t$", fontsize=15)
    plt.ylabel(r"$P(n_t)$", fontsize=15)
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)
    plt.savefig(os.path.join(out_folder, "transhipments.png"))
    plt.show()


def plot_hists(net, bins=20, out_folder=""):
    node_degrees = [k[-1] for k in nx.degree(net)]

    fig = plt.figure()
    plt.hist(node_degrees,
             bins=bins,
             density=True,
             color="grey",
             edgecolor="white")
    plt.xlabel("k", fontsize=15)
    plt.ylabel("P(k)", fontsize=15)
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)
    plt.title("CCDF")
    plt.savefig(os.path.join(out_folder, "PDF.png"))
    plt.show()

    fig = plt.figure()
    plt.hist(node_degrees,
             bins=bins,
             cumulative=-1,
             density=True,
             color="grey",
             edgecolor="white")
    plt.xlabel("k", fontsize=15)
    plt.ylabel("P(k)", fontsize=15)
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)
    plt.title("CCDF")
    plt.savefig(os.path.join(out_folder, "CCDF.png"))
    plt.show()

    fig = plt.figure()
    log_k = np.linspace(np.log10(min(node_degrees)), np.log10(max(node_degrees)), bins)
    n, _, _ = plt.hist(node_degrees,
                       10 ** log_k,
                       log=True,
                       density=True,
                       label="empirical",
                       color="grey",
                       edgecolor="white")
    fit = np.polyfit((log_k[1:] + log_k[:-1]) / 2, n, 1)
    alpha, C = 1 - fit[0], fit[1]
    plt.plot(10 ** log_k, C * (10 ** log_k) ** (-alpha), "k-")
    plt.xscale("log")
    plt.title("PDF")
    plt.xlabel("k", fontsize=15)
    plt.ylabel("P(k)", fontsize=15)
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)
    plt.savefig(os.path.join(out_folder, "PDF_log.png"))
    plt.show()

    fig = plt.figure()
    n, _, _ = plt.hist(node_degrees,
                       10 ** log_k,
                       cumulative=-1,
                       log=True,
                       density=True,
                       label="empirical",
                       color="grey",
                       edgecolor="white")
    fit = np.polyfit((log_k[1:] + log_k[:-1]) / 2, n, 1)
    alpha, C = 1 - fit[0], fit[1]
    plt.plot(10 ** log_k, C * (10 ** log_k) ** (-alpha), "k-")
    plt.gca().set_xscale("log")
    plt.title("CCDF")
    plt.xlabel("k", fontsize=15)
    plt.ylabel("P(k)", fontsize=15)
    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)
    plt.savefig(os.path.join(out_folder, "CCDF_log.png"))
    plt.show()


def small_word_stats(net, out_folder=""):
    net = nx.Graph(net.to_undirected())
    rand_net = nx.random_reference(net, connectivity=True)
    df = pd.DataFrame(index=[0], columns=["L_actual", "L_random", "C_actual", "C_random", "sigma"], dtype=float)
    df["L_actual"] = nx.average_shortest_path_length(net)
    df["L_random"] = nx.average_shortest_path_length(rand_net)
    df["C_actual"] = nx.average_clustering(net)
    df["C_random"] = nx.average_clustering(rand_net)
    df["sigma"] = (df["C_actual"] / df["C_random"]) / (df["L_actual"] / df["L_random"])
    df.to_csv(os.path.join(out_folder, "small_world_stats"))
