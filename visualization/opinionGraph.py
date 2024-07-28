import networkx as nx
import matplotlib.pyplot as plt
import numpy as np
import argparse
import util
import clustering

def mValue(tick: int, ophist: list[list[float]], eps: float) -> float:
    ops = [o for o in ophist[tick]]
    bins = list(np.histogram(ops, bins=int(1 / eps), range=(0.0, 1.0))[0])
    maxCount = max(bins)
    m = abs(bins[0]) + abs(bins[-1])
    for i in range(1, len(bins)):
        m += abs(bins[i] - bins[i-1])
    return m / maxCount

def getColors(opinion: float) -> str:
    r = int(255 * opinion)
    b = int(255 * (1.0 - opinion))
    return f"#{r:02x}00{b:02x}"

def draw(tick: int, clusterTick: int, ophist: list[list[float]], eps: float, graphs: list[list[int]], dir: str):
    G = nx.DiGraph()
    plt.figure(figsize=(15, 15))
    group = clustering.agent2OpinionCluster(ophist[clusterTick], eps)
    for a in range(len(ophist[0])):
        clusterId = group[a]
        G.add_node(
            a, 
            color=getColors(ophist[tick][a]),
            subset=clusterId
        )
    EDGES = [(u, v) for (t, u, v) in graphs if t == tick]
   
    for (u, v) in EDGES:
        G.add_edge(u, v)
    nx.draw_networkx(G, 
                     pos=nx.multipartite_layout(G), 
                     node_color=[v["color"] for v in G.nodes.values()],
                     font_color="white")
    plt.title(f"tick = {tick}, m-value = {mValue(tick, ophist, eps)}")
    plt.savefig(f"{dir}/opgraph-{tick}.pdf")

if __name__ == '__main__':
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
    for tick in args.tick:
        groupedAt = max(args.tick) if args.last else tick
        draw(tick, groupedAt, OPHIST, EPS, GRAPHS, DIR)
        print(tick)