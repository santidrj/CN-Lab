using Plots: display, _add_plot_title!
using Pkg

Pkg.add("Plots")

using Plots
include("utils.jl")

networks = ["ER5000k8.net", "SF_1000_g2.7.net", "ws1000.net", "airports_UW.net", "PGP.net"]
#TODO: maybe set appropiate bin sizes for each network
bins = []

for (root, dirs, files) in walkdir("A1-networks")
    for file in files
        if file in networks
            name = get_file_name(file)
            g = loadgraph(joinpath(root, file), NETFormat())
            degrees = degree(g)

            # Linear histograms
            p1 = histogram(degrees, bins=20, title ="PDF", legend=false, normalize=true)
            # TODO: generate CCDF linear histogram
            p2 = histogram(title="CCDF")
            p = plot(p1, p2)
            xlabel!("degree")
            ylabel!("probability")
            ### Add a global title
            y = ones(3) 
            title = scatter(y, marker=0,markeralpha=0, annotations=(2, y[2], Plots.text(name)),axis=false, grid=false, leg=false,size=(200,100), ticks=false)
            plot(title, p, layout=Plots.grid(2,1,heights=[0.01,0.9]))
            ###
            savefig(joinpath("results", "histograms", name*".png"))

            # Log-log histograms
            p1 = histogram(log10.(degrees), bins=20, title ="PDF", legend=false, normalize=true)
            # TODO: generate CCDF log-log histogram
            p2 = histogram(title="CCDF")
            p = plot(p1, p2)
            xlabel!("log10(degree)")
            ylabel!("probability")
            ### Add a global title
            y = ones(3) 
            title = scatter(y, marker=0,markeralpha=0, annotations=(2, y[2], Plots.text(name)),axis=false, grid=false, leg=false,size=(200,100), ticks=false)
            plot(title, p, layout=Plots.grid(2,1,heights=[0.01,0.9]))
            ###
            savefig(joinpath("results", "histograms", name*"_log.png"))

        end
    end
end