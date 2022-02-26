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

function get_file_name(filename)
    return filename[begin:findlast(isequal('.'), filename)-1]
end

header = (["Network", "#nodes", "#edges", "Max degree", "Min degree", "Avg. degree", "Avg. cluster coefficient", "Assortativity", "Avg. path length", "Diameter"])
table = []

first = true
for (root, dirs, files) in walkdir("A1-networks")
    for file in files
        g = loadgraph(joinpath(root, file), NETFormat())
        f(x) = gdistances(g, x)
        path_lengths = reduce(hcat, f.(vertices(g)))
        row = [get_file_name(file) nv(g) ne(g) Δ(g) δ(g) (ne(g) / nv(g)) mean(local_clustering_coefficient(g)) assortativity(g) mean(path_lengths) maximum(path_lengths)]
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