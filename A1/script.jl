using Pkg

Pkg.add("LightGraphs")
Pkg.add(name = "GraphIO", version = "0.5.0")
Pkg.add("PrettyTables")

using LightGraphs, GraphIO, Printf, PrettyTables
using Statistics

function get_file_name(filename)
    return filename[begin:findlast(isequal('.'), filename)-1]
end

header = (["Network", "#nodes", "#edges", "Max degree", "Min degree", "Avg. degree", "Avg. cluster coefficient", "Avg. path length"])
table = transpose(Vector{Float64}(undef, length(header)))

for (root, dirs, files) in walkdir("A1-networks")
    for file in files
        g = loadgraph(joinpath(root, file), NETFormat())
        f(x) = gdistances(g, x)
        path_lengths = reduce(hcat, f.(vertices(g)))
        row = [get_file_name(file) nv(g) ne(g) Δ(g) δ(g) (ne(g) / nv(g)) mean(local_clustering_coefficient(g)) mean(path_lengths)]
        global table = [table; row]
    end
end

pretty_table(table; backend = Val(:latex), header = header)