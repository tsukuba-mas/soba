import matplotlib.pyplot as plt
import util
import argparse

def draw(tick: int, dir: str, ophist: list[list[float]], eps: float):
    ops = ophist[tick]
    plt.xlim([0.0, 1.0])
    plt.hist(ops, bins=int(1 / eps), range=[0.0, 1.0])
    plt.xlabel("Opinion")
    plt.ylabel("Number of agents")
    plt.savefig(f"{dir}/ophist-{tick}.pdf")
    plt.clf()

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", "--dir")
    parser.add_argument("-t", "--tick", action='append', type=int)
    parser.add_argument("-e", "--eps", type=float, default=0.1)
    args = parser.parse_args()

    OPHIST = util.readOphist(args.dir)
    for tick in args.tick:
        draw(tick, args.dir, OPHIST, args.eps)