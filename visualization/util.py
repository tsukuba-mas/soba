import csv

def readOphist(dir: str) -> list[list[float]]:
    with open(f'{dir}/ophist.csv') as f:
        reader = csv.reader(f)
        return [list(map(float, r))[1:] for r in reader]

def readBelhist(dir: str) -> list[list[str]]:
    with open(f'{dir}/belhist.csv') as f:
        reader = csv.reader(f)
        return [r[1:] for r in reader]

def readGraph(dir: str) -> list[list[int]]:
    with open(f'{dir}/graph.csv') as f:
        reader = csv.reader(f)
        return [list(map(int, r)) for r in reader]