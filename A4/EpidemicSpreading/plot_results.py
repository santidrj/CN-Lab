import os
from pathlib import Path
import numpy as np

import seaborn as sns
import matplotlib.pyplot as plt
from matplotlib.ticker import AutoMinorLocator

OUTPUT_DIR = "output"
COLORS = sns.color_palette('bright')
plots_path = os.path.join(OUTPUT_DIR, "figures")
if not os.path.exists(plots_path):
    os.mkdir(plots_path)

results_path = os.path.join(OUTPUT_DIR, "results")


def set_plot_title(net_params, axis):
    if net_params[0] == "BA":
        axis.set_title(
            f"${net_params[0]}$ $N={net_params[1]}$ $m_0={net_params[2]}$ $m={net_params[3]}$ $<k>={net_params[-1]}$"
        )
    elif net_params[0] == "ER":
        axis.set_title(f"${net_params[0]}$ $N={net_params[1]}$ $p={net_params[2]}$ $<k>={net_params[-1]}$")
    elif net_params[0] == "SF":
        axis.set_title(f"${net_params[0]}$ $N={net_params[1]}$ $\\gamma={net_params[-1]}$")
    elif net_params[0] == "inf":
        axis.set_title(f"{net_params[0]}-{net_params[1]}")
    else:
        axis.set_title(f"{net_params[0]}")


for net in os.listdir(results_path):
    net_path = os.path.join(results_path, net)
    fig, ax = plt.subplots()
    for i, folder in enumerate(sorted(os.listdir(net_path), key=lambda k: float(k.split("-")[-1]))):
        mu = folder.split("-")[1]
        avgRho = np.loadtxt(os.path.join(net_path, folder, "avgRho.txt"))
        beta = np.loadtxt(os.path.join(net_path, folder, "beta.txt"))

        simulations = [str(f) for f in Path(os.path.join(net_path, folder)).glob("avgSim*")]
        simulations = sorted(simulations, key=lambda x: os.path.splitext(os.path.basename(x))[0].split("-")[-1])
        fig2, ax2 = plt.subplots()
        for j in range(len(simulations) // 6, len(simulations), len(simulations) // 6):
            sim = simulations[j]
            b = os.path.splitext(os.path.basename(sim))[0].split("-")[-1]
            rho = np.loadtxt(sim)
            ax2.plot(rho[:200], label=f'$\\beta={b}$')
        set_plot_title(net.split("-"), ax2)
        title = ax2.get_title()
        ax2.set_title(title + f", $SIS(\\mu={mu}, \\rho_{{0}}=0.2)$")
        ax2.legend(loc=0)
        ax2.set_xlabel(r"$t$")
        ax2.set_ylabel(r"$\rho$")
        fig2.savefig(os.path.join(plots_path, net + f"-avgSim-{mu}.png"))
        plt.close(fig2)

        ax.plot(beta, avgRho, label=f'$\\mu$ = {mu}', color=COLORS[i])

        if os.path.exists(os.path.join(net_path, folder, "mmcaRho.txt")):
            mmcaRho = np.loadtxt(os.path.join(net_path, folder, "mmcaRho.txt"))
            ax.plot(beta, mmcaRho, label=f'$\\mu$ = {mu}, MMCA', color=COLORS[i], linestyle='--')

    set_plot_title(net.split("-"), ax)

    ax.legend(loc=0)
    ax.set_xlabel(r"$\beta$")
    ax.set_ylabel(r"$\rho$")
    ax.xaxis.set_minor_locator(AutoMinorLocator())
    fig.savefig(os.path.join(plots_path, net + ".png"))
    # plt.show()
    plt.close(fig)
