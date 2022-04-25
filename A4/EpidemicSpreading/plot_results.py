import os

import seaborn as sns
import matplotlib.pyplot as plt
from matplotlib.ticker import AutoMinorLocator

OUTPUT_DIR = "output"
COLORS = sns.color_palette('bright')
plots_path = os.path.join(OUTPUT_DIR, "figures")
if not os.path.exists(plots_path):
    os.mkdir(plots_path)

results_path = os.path.join(OUTPUT_DIR, "results")
for net in os.listdir(results_path):
    net_path = os.path.join(results_path, net)
    fig, ax = plt.subplots()
    for i, folder in enumerate(sorted(os.listdir(net_path), key=lambda k: float(k.split("-")[-1]))):
        mu = folder.split("-")[1]
        with open(os.path.join(net_path, folder, "avgRho.txt"), "r") as f:
            avgRho = [float(line.strip("\n")) for line in f.readlines()]
        with open(os.path.join(net_path, folder, "beta.txt"), "r") as f:
            beta = [float(line.strip("\n")) for line in f.readlines()]

        ax.plot(beta, avgRho, label=f'$\\mu$ = {mu}', color=COLORS[i])

    net_params = net.split("-")
    if net_params[0] == "BA":
        plt.title(f"${net_params[0]}$ $N={net_params[1]}$ $<k>={net_params[-1]}$")
    elif net_params[0] == "ER":
        plt.title(f"${net_params[0]}$ $N={net_params[1]}$ $<k>={net_params[-1]}$")
    elif net_params[0] == "SF":
        plt.title(f"${net_params[0]}$ $N={net_params[1]}$ $<k>={net_params[-1]}$")
    else:
        plt.title(f"{net_params[0]}")

    plt.legend(loc=0)
    plt.xlabel(r"$\beta$")
    plt.ylabel(r"$\rho$")
    ax.xaxis.set_minor_locator(AutoMinorLocator())
    plt.savefig(os.path.join(plots_path, net + ".png"))
    # plt.show()
    plt.close()
