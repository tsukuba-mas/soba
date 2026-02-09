#!/bin/bash

## This test checks whether agents listen to their neighbors before rewiring.

../soba --seed 50 --dir "results" --nbAgent 4 \
    --tick 1 --atoms 2 --update "oddg,of" \
    --rewrite "random" \
    --pUnfollow 1 --pActive 0.5 --epsilon 0.1  \
    --delta 4 \
    --values """`cat jsons/val-1.json`""" \
    --topics "1100" \
    --opinions """`cat jsons/opinions2.json`""" \
    --beliefs """`cat jsons/beliefs2.json`""" \
    --network """`cat jsons/network2.json`""" \
    --nbEdges 2 --verbose  --reevaluateCatBeforeRewiring

RES=`tail -1 results/grhist.csv`

# Agent 2 does not rewire
if [[ $RES = '1,1,0,3,2' ]]; then
exit 1
fi

# rm -rf results