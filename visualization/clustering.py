from scipy.cluster.hierarchy import linkage
from scipy.spatial.distance import pdist
from statistics import mean
import argparse
import util

class Cluster():
    def __init__(self, id, members, left=None, right=None):
        self.id = id
        self.left = left
        self.right = right
        self.members = members
        self.isConverged = False
    
    def __str__(self) -> str:
        return f"Cluster({self.id}, {self.left}, {self.right}, {self.members})"
    
    def converged(self):
        self.isConverged = True

def performHierarchicalClustering(data: list[float]) -> dict[int, Cluster]:
    d = [[x] for x in data]
    clusters = linkage(pdist(d, 'euclidean'), 'ward')
    result = {i: Cluster(id=i, members=[data[i]]) for i in range(len(data))}
    for iter, (g1, g2, _, _) in enumerate(clusters):
        g1 = int(g1)
        g2 = int(g2)
        gNew = iter + len(data)
        result[gNew] = Cluster(id=gNew, members=result[g1].members+result[g2].members, left=g1, right=g2)
    return result

def getClusterId(data: list[float], eps: float) -> dict[float, int]:
    clusters = performHierarchicalClustering(data)
    keys = list(reversed(sorted(clusters.keys())))
    for key in keys:
        maxElem = max(clusters[key].members)
        minElem = min(clusters[key].members)
        if abs(maxElem - minElem) <= eps:
            clusters[key].converged()
    
    allAgents = set(data)
    groups = []
    for c in list(reversed(list(filter(lambda x: x.isConverged, clusters.values())))):
        if set(c.members) <= allAgents:
            allAgents = allAgents - set(c.members)
            groups.append(c)
    
    groups.sort(key=lambda x: mean(x.members))
    result = {}
    for id, g in enumerate(groups):
        for m in g.members:
            result[m] = id
    return result

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", "--dir")
    parser.add_argument("-t", "--tick", action='append', type=int)
    parser.add_argument("-e", "--eps", type=float, default=0.01)
    args = parser.parse_args()

    OPHIST = util.readOphist(args.dir)
    for tick in args.tick:
        print(getClusterId(OPHIST[tick], args.eps))