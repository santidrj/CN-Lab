import os

import matplotlib.pyplot as plt
import numpy as np

degrees_path = "degrees"
plots_path = os.path.join("figures", "histograms_r")


def dist_constant(x_min, alpha):
    return (alpha - 1) * x_min ** (alpha - 1)


def plot_loglog_hist(k, net_name, alpha=3, C=1):
    fig = plt.figure()
    log_k = np.linspace(np.log10(min(node_degrees)), np.log10(max(node_degrees)), 20)

    plt.hist(k, 10**log_k, log=True, density=True, label='empirical', color='lightgrey', edgecolor='white')
    plt.plot(10**log_k, C * (10**log_k) ** (-alpha), '-b')
    plt.gca().set_xscale("log")
    plt.title("PDF")
    plt.xlabel("k")
    plt.ylabel("P(k)")
    plt.savefig(os.path.join(plots_path, net_name + "_PDF_log.png"))

    fig = plt.figure()
    plt.hist(
        k, 10**log_k, cumulative=-1, log=True, density=True, label='empirical', color='lightgrey', edgecolor='white'
    )
    plt.gca().set_xscale("log")
    plt.title("CCDF")
    plt.xlabel("k")
    plt.ylabel("P(k)")
    plt.savefig(os.path.join(plots_path, net_name + "_CCDF_log.png"))


for root, dirs, files in os.walk(degrees_path):
    for name in files:
        with open(os.path.join(root, name), 'rb') as f:
            node_degrees = np.loadtxt(f)

        name_split = name.split(".")[0].split("-")

        if name_split[0] == "BA":
            C = dist_constant(int(name_split[-1]), 3)
            plot_loglog_hist(node_degrees, name.split(".")[0], C=C)

        if name_split[0] == "CM":
            alpha = int(name_split[-1])
            plot_loglog_hist(node_degrees, name.split(".")[0], alpha=alpha)
