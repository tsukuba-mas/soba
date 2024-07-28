import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import util
import clustering
import argparse

def getClusterToMembers(agent2cluster: dict[int, int]) -> dict[int, int]:
    result = {}
    for c in agent2cluster.values():
        if c in result:
            result[c] += 1
        else:
            result[c] = 1
    return result

def saveHeatmap(tick: int, agent2cluster: dict[int, int], filepath: str, graph: list[list[int]]):
    clusterNum = len(set(agent2cluster.values()))
    graphAtTick = [(u, v) for (t, u, v) in graph if t == tick]
    d = {f"from-{uid}": {f"to-{vid}": 0 for vid in range(clusterNum)} for uid in range(clusterNum)}
    for (u, v) in graphAtTick:
        uid = f"from-{agent2cluster[u]}"
        vid = f"to-{agent2cluster[v]}"
        d[uid][vid] += 1

    clusterToMembers = getClusterToMembers(agent2cluster)
    dd = {f"from-{uid}": {f"to-{vid}": 0 for vid in range(clusterNum)} for uid in range(clusterNum)}
    annotation = {f"from-{uid}": {f"to-{vid}": "" for vid in range(clusterNum)} for uid in range(clusterNum)}
    for u in range(clusterNum):
        for v in range(clusterNum):
            uid = f"from-{u}"
            vid = f"to-{v}"
            pairs = clusterToMembers[u] * clusterToMembers[v] if u != v else clusterToMembers[u] * (clusterToMembers[u] - 1)
            dd[uid][vid] = d[uid][vid] / pairs * 100 if pairs > 0 else 0
            annotation[uid][vid] = f"{d[uid][vid]}\n{dd[uid][vid]:.1f}"
    df = pd.DataFrame(dd)
    sns.heatmap(df, annot=pd.DataFrame(annotation), fmt="", square=True, vmin=0, vmax=25)
    plt.savefig(filepath)
    plt.clf()

def drawOpinionClusterHeatmap(
    tick: int, 
    clusteringTick: int, 
    ophist: list[list[float]], 
    eps: float, 
    graph: list[list[int]], 
    dir: str
):
    ops = clustering.agent2OpinionCluster(ophist[clusteringTick], eps)
    saveHeatmap(tick, ops, f"{dir}/opheat-{tick}.pdf", graph)

def drawBeliefClusterHeatmap(
    tick: int, 
    clusteringTick: int, 
    belhist: list[list[str]], 
    eps: float, 
    graph: list[list[int]], 
    dir: str
):
    bels = clustering.agent2BeliefCluster(belhist[clusteringTick])
    saveHeatmap(tick, bels, f"{dir}/opheat-{tick}.pdf", graph)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", "--dir")
    parser.add_argument("-t", "--tick", action='append', type=int)
    parser.add_argument("-e", "--eps", type=float, default=0.1)
    parser.add_argument("-o", "--opinion", action='store_true')
    parser.add_argument("-b", "--belief", action='store_true')
    parser.add_argument("-l", "--last", action='store_true')
    args = parser.parse_args()
    assert(args.opinion or args.belief)

    DIR = args.dir
    BELHIST = util.readBelhist(DIR)
    OPHIST = util.readOphist(DIR)
    GRAPH = util.readGraph(DIR)
    EPS = args.eps

    for tick in args.tick:
        clusteringTick = max(args.tick) if args.last else tick
        if args.opinion:
            drawOpinionClusterHeatmap(tick, clusteringTick, OPHIST, EPS, GRAPH, DIR)
        if args.belief:
            drawBeliefClusterHeatmap(tick, clusteringTick, BELHIST, EPS, GRAPH, DIR)