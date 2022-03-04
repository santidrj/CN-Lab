using Pkg

Pkg.add("LightGraphs")
Pkg.add(name = "GraphIO", version = "0.5.0")
Pkg.add("PrettyTables")
Pkg.add("CSV")
Pkg.add("DataFrames")

using LightGraphs
using GraphIO
using PrettyTables
using Statistics
using CSV
using DataFrames
include("utils.jl")


header = (["Network", "#nodes", "#edges", "Max degree", "Min degree", "Avg. degree", "Avg. cluster coefficient", "Assortativity", "Avg. path length", "Diameter"])
table = []

first = true
for (root, dirs, files) in walkdir("A1-networks")
    for file in files
        g = loadgraph(joinpath(root, file), NETFormat())
        f(x) = gdistances(g, x)
        path_lengths = reduce(hcat, f.(vertices(g)))'
        row = [get_file_name(file) nv(g) ne(g) Δ(g) δ(g) round((ne(g) / nv(g)), digits=4) round(mean(local_clustering_coefficient(g)), digits=4) round(assortativity(g), digits=4) round(mean(path_lengths), digits=4) diameter(g)]

        if first
            global table = row
            global first = false
        else
            global table = [table; row]
        end
    end
end


open("results/networks_descriptors_latex.txt", "w") do f
    pretty_table(f, table; backend = Val(:latex), header = header)
end

CSV.write("results/networks_descriptors.csv", DataFrame(table, :auto), header = header);