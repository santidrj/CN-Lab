#!/bin/bash

files="A3-networks/**/*.clu"
tmpfile="temporari.csv"
first=true
for f in $files; do
    echo "Processing $f ..."
    filename=$(basename $f .clu)
    net=${filename%-*}
    first=true
    for partition in $(find nets/ -name ${net}* -print0 | xargs -r0); do
        if [ "rb125" = "$net" ]; then
            number=${filename#*-}
            f2=$(basename $partition .clu)
            alg=${f2#*_}
            f2=${f2%_*}
            if [[ $alg == "girvan-newman" && $number != ${f2#*-} ]]; then
                continue
            fi
            outfile="results/${net}-${number}.csv"
        else
            outfile="results/${net}.csv"
        fi

        ./Compare_partitions $partition $f $tmpfile t
        if [ "$first" = true ]; then
            cut -f 1,11,16,26 $tmpfile | tr '\t' ',' > $outfile
            first=false
        else
            tail -n 1 $tmpfile | cut -f 1,11,16,26 | tr '\t' ',' >> $outfile
        fi
    done
    echo ""
done
rm $tmpfile