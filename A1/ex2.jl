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

airports = Dict("PAR" => 2269, "LON" => 1713, "FRA" => 926, "AMS" => 116, "MOW" => 1954, "NYC" => 2161, "ATL" => 174, "BCN" => 240, "WAW" => 3234, "CHC" => 527, "DJE" => 726, "ADA" => 34, "AGU" => 63, "TBO" => 2877, "ZVA" => 3614)
nodes = collect(values(airports))
header = (["Airport", "Degree", "Strength", "Clustering coefficient", "Avgerage path length", "Maximum path length", "Betweeness", "Eigenvector centrality", "PageRank"])
table = []

g = loadgraph(joinpath("A1-networks/real/airports_UW.net"), NETFormat())

f(x) = gdistances(g, x)
degrees = degree(g, nodes)
# TODO: Add strength
strength = Vector{Float64}(undef, length(nodes))
cluster_coef = round.(local_clustering_coefficient(g, nodes), digits=8)
path_lengths = reduce(hcat, f.(nodes))'
average_path_lengths = round.(mean(path_lengths, dims = 2), digits=8)
max_path_lengths = maximum(path_lengths, dims = 2)
betweeness = round.(betweenness_centrality(g)[nodes], digits=8)
eigenvector = round.(eigenvector_centrality(g)[nodes], digits=8)
page_rank = round.(pagerank(g)[nodes], digits=8)

tab = hcat(collect(keys(airports)), degrees, strength, cluster_coef, average_path_lengths, max_path_lengths, betweeness, eigenvector, page_rank)

open("results/airports_descriptors_latex.txt", "w") do f
    pretty_table(f, tab; backend = Val(:latex), header = header)
end

CSV.write("results/airports_descriptors.csv", DataFrame(tab, :auto), header = header);
