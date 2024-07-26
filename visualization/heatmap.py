import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import util
import clustering
import argparse
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

def saveHeatmap(agent2cluster: dict[int, int], filepath: str):
    clusterNum = len(set(agent2cluster.values()))
    graphAtTick = [(u, v) for (t, u, v) in GRAPH if t == tick]
    d = {f"from-{uid}": {f"to-{vid}": 0 for vid in range(clusterNum)} for uid in range(clusterNum)}
    for (u, v) in graphAtTick:
        uid = f"from-{agent2cluster[u]}"
        vid = f"to-{agent2cluster[v]}"
        d[uid][vid] += 1
    df = pd.DataFrame(d)
    sns.heatmap(df, annot=True, square=True, fmt='d', vmin=0, vmax=len(graphAtTick))
    plt.savefig(filepath)
    plt.clf()

for tick in args.tick:
    clusteringTick = max(args.tick) if args.last else tick
    if args.opinion:
        ops = clustering.agent2OpinionCluster(OPHIST[clusteringTick], args.eps)
        saveHeatmap(ops, f"{DIR}/opheat-{tick}.pdf")
    if args.belief:
        bels = clustering.agent2BeliefCluster(BELHIST[clusteringTick])
        saveHeatmap(ops, f"{DIR}/belheat-{tick}.pdf")