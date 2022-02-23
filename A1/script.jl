using LightGraphs, GraphIO, Printf, PrettyTables

function GetFileName(filename)
    return filename[begin:findlast(isequal('.'), filename)-1]
end

header = (["Network", "#nodes", "#edges", "Max degree", "Min degree", "Avg. degree"])
table = transpose(Vector{Float64}(undef, 6))

for (root, dirs, files) in walkdir("A1-networks")
    for file in files
        g = loadgraph(joinpath(root, file), NETFormat())
        row = [GetFileName(file) nv(g) ne(g) Δ(g) δ(g) (ne(g) / nv(g))]
        global table = [table; row]
    end
end

pretty_table(table; backend = Val(:latex), header = header)