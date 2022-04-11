#!/usr/bin/bash

echo "Running"
files="A3-networks/**/*.clu"
algs=("louvain")
tmpfile="temporari.csv"
for alg in $algs; do
    for f in $files; do
        echo "Processing $f file..."
        filename=$(basename $f .clu)
        net=${filename%-*}
        partition=`find nets/ -name ${net}*`
        # echo $filename
        # echo $net
        # echo "Partition $partition"
        if [[ "rb125" == "$net" ]]; then
            number=${filename#*-}
            outfile="results/${net}-${number}_${alg}.csv"
        else
            outfile="results/${net}_${alg}.csv"
        fi

        ./Compare_partitions $partition $f $tmpfile t
        tr '\t' ',' < $tmpfile > $outfile
    done
done
rm $tmpfile