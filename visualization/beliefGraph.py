import networkx as nx
import matplotlib.pyplot as plt
import numpy as np
import argparse
import util
import clustering

def draw(tick: int, clusterTick: int, belhist: list[list[str]], graph: list[list[int]], dir: str):
    G = nx.DiGraph()
    plt.figure(figsize=(15, 15))
    group = clustering.agent2BeliefCluster(belhist[clusterTick])
    colors = [int(c) for c in np.linspace(0, 255, len(set(group.values())))]
    for a in range(len(belhist[0])):
        clusterId = group[a]
        G.add_node(
            a, 
            color=f"#{colors[clusterId]:02x}00{255 - colors[clusterId]:02x}",
            subset=clusterId
        )
    EDGES = [(u, v) for (t, u, v) in graph if t == tick]
   
    for (u, v) in EDGES:
        G.add_edge(u, v)
    nx.draw_networkx(G, 
                     pos=nx.multipartite_layout(G), 
                     node_color=[v["color"] for v in G.nodes.values()],
                     font_color="white")
    plt.title(f"tick = {tick}")
    plt.savefig(f"{dir}/belgraph-{tick}.pdf")
    plt.clf()

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", "--dir")
    parser.add_argument("-t", "--tick", action='append', type=int)
    parser.add_argument("-l", "--last", action='store_true')
    args = parser.parse_args()

    DIR = args.dir
    BELHIST = util.readBelhist(DIR)
    GRAPHS = util.readGraph(DIR)

    for tick in args.tick:
        groupedAt = max(args.tick) if args.last else tick
        draw(tick, groupedAt, BELHIST, GRAPHS, DIR)
        print(tick)