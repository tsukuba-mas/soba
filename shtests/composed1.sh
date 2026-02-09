#!/bin/bash

## This test checks whether agents listen to their neighbors
## befor each of the composed functions (OD, OF, and OD) are executed.

../soba --seed 42 --dir "results" --nbAgent 2 \
    --tick 1 --atoms 2 --update "oddg,of,oddg" \
    --rewrite "none" \
    --pUnfollow 1 --pActive 1 --epsilon 1  \
    --delta 4 \
    --values """`cat jsons/val-1.json`""" \
    --topics "1100" \
    --opinions """`cat jsons/opinions.json`""" \
    --beliefs """`cat jsons/beliefs.json`""" \
    --network """`cat jsons/network.json`""" \
    --nbEdges 2 --verbose

RES=`tail -1 results/ophist0.csv | cut -c-9`

if [[ $RES != '1,0.79166' ]]; then
exit 1
fi

rm -rf results