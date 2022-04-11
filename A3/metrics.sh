#!/usr/bin/bash

files="A3-networks/**/*.clu"
algs=("louvain")
tmpfile="temporari.csv"
for f in $files; do
    echo "Processing $f ..."
    filename=$(basename $f .clu)
    net=${filename%-*}
    partition=`find nets/ -name ${net}*`
    first=true
    for alg in $algs; do
        if [ "rb125" = "$net" ]; then
            number=${filename#*-}
            outfile="results/${net}-${number}_${alg}.csv"
        else
            outfile="results/${net}_${alg}.csv"
        fi

        ./Compare_partitions $partition $f $tmpfile t
        # tr '\t' ',' < $tmpfile | awk -F',' '{print $11 $16 $26}'> $outfile
        if [ "$first" = true ]; then
            cut -f 1,11,16,26 $tmpfile | tr '\t' ',' > $outfile
            first=false
        else
            tail -n 1 $tmpfile | cut -f 1,11,16,26 | tr '\t' ',' >> $outfile
        fi
    done
done
rm $tmpfile