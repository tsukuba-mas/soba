# Output Files
Let $N$ be the number of agents, $E$ be the set of edges, and $T$ be the number of iterations.
The main output is three files in csv format.

- `ophist.csv` and `belhist.csv` are the csv file with $(N+1)\times (T+1)$ values recording changing history of opinion and belief, respectively. The first column represents ticks (`0` means just after initialization) and other columns corresponding to each of the agents (i.e., $i$-th column shows the information about agent with id $i-1$ where $1\leq i\leq N+1$).
- `grhist.csv` is the csv file with $(|E|+1)\times (T+2)$ values recording changing history of graph agents form. Basically the format of this file is the same with `ophist.csv` and `belhist.csv`, but this file contains two lines starting with `0,` at the beginning of the file. The first column shows that where each of edges starts (i.e., the node $u$ where $(u,v)\in E$). Other columns show that where each of edges ends (i.e., the node $v$ where $(u,v)\in E$) at the tick. For example, the graph $G=(V,E)$ where $V=\{1,2,3\}$ and $E=\{(1,2),(1,3),(2,3)\}$ is represented as follows:

```csv
0,1,1,2
0,2,3,3
```