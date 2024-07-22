import networkx as nx
import csv
import matplotlib.pyplot as plt
import numpy as np
import argparse
import util
parser = argparse.ArgumentParser()
parser.add_argument("-d", "--dir")
parser.add_argument("-t", "--tick", action='append', type=int)
parser.add_argument("-e", "--eps", type=float, default=0.05)
args = parser.parse_args()

DIR = args.dir
OPHIST = util.readOphist(DIR)
GRAPHS = util.readGraph(DIR)

AGENTS = len(OPHIST[0]) - 1
EPS = args.eps

def classify():
    group = {}
    LAST_OPS = OPHIST[-1]
    for i, op in enumerate(LAST_OPS):
        notyet = True
        for g in group:
            if notyet and abs(g - op) <= 2 * EPS:
                group[g].append(i)
                notyet = False
        if notyet:
            group[op] = [i]
    
    centers = list(group.keys())
    centers.sort()
    v2k = { v: k for k in group for v in group[k] }
    v2g = {v: centers.index(v2k[v]) for v in v2k}
    return v2g

def mValue(tick: int) -> float:
    ops = [o for o in OPHIST[tick]]
    bins = list(np.histogram(ops, bins=int(1 / EPS), range=(0.0 - EPS, 1.0 + EPS))[0])
    maxCount = max(bins)
    m = 0
    for i in range(1, len(bins)):
        m += abs(bins[i] - bins[i-1])
    return m / maxCount

def draw(tick: int):
    G = nx.DiGraph()
    plt.figure(figsize=(15, 15))
    group = classify()
    G.add_nodes_from([
        (i, {
            "color": f"#{int((1.0 - OPHIST[tick][i+1]) * 255):02x}00{int(OPHIST[tick][i+1] * 255):02x}",
            "subset": group[i],
            })
        for i in range(AGENTS)
    ])
    EDGES = [(u, v) for (t, u, v) in GRAPHS if t == tick]
   
    for (u, v) in EDGES:
        G.add_edge(u, v, weight=abs(OPHIST[tick][u+1] - OPHIST[tick][v+1]))
    nx.draw_networkx(G, 
                     pos=nx.multipartite_layout(G), 
                     node_color=[v["color"] for v in G.nodes.values()])
    plt.title(f"tick = {tick}, m-value = {mValue(tick)}")
    plt.savefig(f"graph-{tick}.png")

for tick in args.tick:
    draw(tick)