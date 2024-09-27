# belop-echo-chamber

Simulator for the emergence of echo chamber through opinions-beliefs interactions.
For the detail of the model, see the corresponding paper.

## Requirements
Nim 2.0.0 or later and gcc.
Dependent packages listed in `.nimble` file will be installed automatically if necessary when you compile this project.

Running this program on Linux is recommended.

## How to use
You can compile the simulator by:

```bash
$ nimble build
```

Appending the option `-d:release` yields faster binary.

By executing the command above, you can get the binary `belop_echo_chamber`.
This is the simulator.
Then, launch it with passing the path to the input TOML file by:

```bash
$ ./belop_echo_chamber path/to/input/file.toml
```

The output from the simulator will be saved under the directory which is specified in the input file.

## Accepted format of the TOML file
All of the entries are mandatory.

1. `seed` (in integer): seed to initialize random number generator.
2. `agents` (in positive integer): the number of agents.
3. `follow` (in positive integer): the number of following relations (i.e., edges in the graph agents form). Note that the integer assigned to this should be equal to or less than $N(N-1)$ where $N$ is the number of agents.
4. `tick` (in positive integer): the number of iterations.
5. `filter` (in string, either `all`, `obounded`, `bbounded`, `both`): filtering strategy.
6. `updating` (in array of string, each elements should be either `od`, `br`, `of`, `ba`): updating strategy.
7. `rewriting` (in string, either `random`, `oprecommendation`, `belrecommendation` or `bothrecommendation`): rewriting strategy.
8. `verbose` (in boolean): if `true` additional information will be saved; otherwise it will not.
9. `mu` (in float between 0 and 1): the parameter $\mu$
10. `alpha` (in float between 0 and 1): the parameter $\alpha$
11. `unfollow` (in float between 0 and 1): the probability to try to unfollow someone
12. `activation` (in float between 0 and 1): the probability to be active, i.e., do some actions in the iteration.
13. `values` (in array of float, the length of it should be 8, each of elements should be between 0 and 1): cultural values (see the table below).
14. `epsilon` (in float between 0 and 1): the threshold for opinions.
15. `delta` (in integer between 0 and 8): the threshould for beliefs.
16. `topic` (in string with eight characters, each of the should be either `0` or `1`): topic (see the table below). `1` means true and `0` means false.

### Index of cultural values and topics
In the $i$-th element of cultural values and $i$-th character of logical formulae (including topics and the outputs) correspond to the interpretation showed below:

|p|q|r|index|
|:--:|:--:|:--:|:--:|
|T|T|T|0|
|T|T|F|1|
|T|F|T|2|
|T|F|F|3|
|F|T|T|4|
|F|T|F|5|
|F|F|T|6|
|F|F|F|7|

(**Note that the index is 0-origin.**)

For example: let $I$ be the interpretation which assigns $p$ and $q$ to T and $r$ to F.
If cultural values $V$ are defined as follows, $V(I)=0.1$ since the index corresponds to $I$ is 1 and the element with the index 1 in the array is $0.1$.

```toml
values = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 1.0]
```
Similarly, if the topic $\phi$ is defined as follows, $I\not\models\phi$ because the character with the index 1 is `0`, which means false:

```toml
topic = "10101010"
```

## Output
Let $N$ be the number of agents, $E$ be the set of edges, and $T$ be the number of iterations.
The main output is three files in csv format.

- `ophist.csv` and `belhist.csv` are the csv file with $(N+1)\times (T+1)$ values recording changing history of opinion and belief, respectively. The first column represents ticks (`0` means just after initialization) and other columns corresponding to each of the agents (i.e., $i$-th column shows the information about agent with id $i-1$ where $1\leq i\leq N+1$).
- `grhist.csv` is the csv file with $(|E|+1)\times (T+2)$ values recording changing history of graph agents form. Basically the format of this file is the same with `ophist.csv` and `belhist.csv`, but this file contains two lines starting with `0,` at the beginning of the file. The first column shows that where each of edges starts (i.e., the node $u$ where $(u,v)\in E$). Other columns show that where each of edges ends (i.e., the node $v$ where $(u,v)\in E$) at the tick. For example, the graph $G=(V,E)$ where $V=\{1,2,3\}$ and $E=\{(1,2),(1,3),(2,3)\}$ is represented as follows:

```csv
0,1,1,2
0,2,3,3
```

## Author
Hiro KATAOKA (University of Tsukuba)

## License
MIT