import matplotlib.pyplot as plt
import util
import pandas as pd
import argparse

def draw(ophist: list[list[float]], dir: str):
    pd.DataFrame(ophist).plot(legend=None)
    plt.xlim([0, len(ophist) - 1])
    plt.xlabel("Tick")
    plt.ylabel("Opinion")
    plt.savefig(f"{dir}/ophist.pdf")
    plt.clf()

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", "--dir")
    args = parser.parse_args()

    OPHIST = util.readOphist(args.dir)
    draw(OPHIST, args.dir)