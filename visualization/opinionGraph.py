import networkx as nx
import csv
import matplotlib.pyplot as plt
import numpy as np
import argparse
import util
import clustering
parser = argparse.ArgumentParser()
parser.add_argument("-d", "--dir")
parser.add_argument("-t", "--tick", action='append', type=int)
parser.add_argument("-e", "--eps", type=float, default=0.1)
parser.add_argument("-l", "--last", action='store_true')
args = parser.parse_args()

DIR = args.dir
OPHIST = util.readOphist(DIR)
GRAPHS = util.readGraph(DIR)

AGENTS = len(OPHIST[0])
EPS = args.eps

def mValue(tick: int) -> float:
    ops = [o for o in OPHIST[tick]]
    bins = list(np.histogram(ops, bins=int(1 / EPS), range=(0.0 - EPS, 1.0 + EPS))[0])
    maxCount = max(bins)
    m = abs(bins[0]) + abs(bins[-1])
    for i in range(1, len(bins)):
        m += abs(bins[i] - bins[i-1])
    return m / maxCount

def getColors(opinion: float) -> str:
    r = int(255 * opinion)
    b = int(255 * (1.0 - opinion))
    return f"#{r:02x}00{b:02x}"

def draw(tick: int, clusterTick: int):
    G = nx.DiGraph()
    plt.figure(figsize=(15, 15))
    group = clustering.agent2OpinionCluster(OPHIST[clusterTick], EPS)
    for a in range(AGENTS):
        clusterId = group[a]
        G.add_node(
            a, 
            color=getColors(OPHIST[tick][a]),
            subset=clusterId
        )
    EDGES = [(u, v) for (t, u, v) in GRAPHS if t == tick]
   
    for (u, v) in EDGES:
        G.add_edge(u, v)
    nx.draw_networkx(G, 
                     pos=nx.multipartite_layout(G), 
                     node_color=[v["color"] for v in G.nodes.values()],
                     font_color="white")
    plt.title(f"tick = {tick}, m-value = {mValue(tick)}")
    plt.savefig(f"{DIR}/opgraph-{tick}.pdf")

for tick in args.tick:
    groupedAt = max(args.tick) if args.last else tick
    draw(tick, groupedAt)
    print(tick)