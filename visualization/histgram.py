import matplotlib.pyplot as plt
import util
import argparse
parser = argparse.ArgumentParser()
parser.add_argument("-d", "--dir")
parser.add_argument("-t", "--tick", action='append', type=int)
parser.add_argument("-e", "--eps", type=float, default=0.1)
args = parser.parse_args()

OPHIST = util.readOphist(args.dir)

def draw(tick: int, filepath: str):
    ops = OPHIST[tick]
    plt.xlim([0.0, 1.0])
    plt.hist(ops, bins=int(1 / args.eps), range=[0.0, 1.0])
    plt.xlabel("Opinion")
    plt.ylabel("Number of agents")
    plt.savefig(filepath)
    plt.clf()

for tick in args.tick:
    draw(tick, f"{args.dir}/ophist-{tick}.pdf")