# Accepted Options
## Note
Some options have default values.
However, **it is strongly recommended to specify all parameters via command line and not to use the default values**.
This is useful to understand the conditions of your experiments and reproduce the results.

## Preliminaries
To make the description simpler, following notations and words are used in the following section:

- $A$ is the (finite) set of agents
- $E(\subseteq A\times A)$ is the set of directed edge
- $N_a=\{b\in A;(a, b)\in E\}$
- $T$ is the set of topics
- rational number format refers `x/y` where `x` is integer and `y` is positive integer.
- "$x$ to $y$ JSON" means the JSON where the keys are $x$ and values are $y$.

## Description of the Options
### `--seed` (integer, default: 42)
Seed of the random number generator.

### `--dir` (or `-d`; string, default: `results/tmp`)
The directory where outputs will be saved.

### `--nbAgent` (or `-n`; positive integer, default: 100)
The number of agents, i.e., $|A|$.

### `--tick` (positive integer, default: 100)
The number of iterations.

### `--atoms` (positive integer, default: 3)
The number of atomic propositions.
Strongly recommended specifying this option to check everything (e.g., beliefs) are defined correctly.

### `--update` (see below, default: `oddw`)
Updating strategy.
Following procedures are defined:

- `oddg`: opinion dynamics, DeGroot model
- `oddw`: opinion dynamics, DW model
- `br`: belief revision, belief revision games
- `of`: opinion formation
- `barc`: belief alignment, choosing randomly from the candidates
- `bavm`: belief alignment, choosing deterministically with respect to values
- `ofbarc`: perform `of` and `barc` in this order until opinions and beliefs reach stability

If agents follow more than one procedure, pass the sequence of the symbols above as a string.
Each of the symbols (e.g., `oddg` or `oddw`) should be concatenated with `,`.
The symbols should appear in the order that they should be performed.
For example, `oddg, br` means "`br` is performed after `oddg` is executed".

### `--rewrite` (see the list below, default: `none`)
Rewriting strategy.

- `none`: agents never update their sets of neighbors.
- `random`: agents try to choose one discordant agent from their neighbors and one agent from agents who are not neighbors. If both are possible, neighbors are updated.
- `swapMaxMin`: agents exclude the furthest discordant neighbor and include the closest agent if this helps them to reduce the distances between agents and their neighbors.

### `--prehoc` (string, in the format of `--update`)
Prehoc procedures performed before the 1st iteration.

### `--verbose`
Executing the simulator in verbose mode.
It will output extra information in this mode.

### `--mu` (float between 0 and 1, default: 0.5)
The ratio to mix opinions in `oddw`.

### `--alpha` (float between 0 and 1, default: 0.5)
The ratio to mix opinions in `of`.

### `--pUnfollow` (float between 0 and 1, default: 0.5)
The probability to update $N_a$ following to the rewriting strategy.

### `--pActive` (float between 0 and 1, default: 0.5)
The probability to act in each tick, that is:
```
activatedAgents = []
for agent in agents:
   if random() <= p:
       activatedAgents.add(agent)
```
in pseudocode.
**This is only useful if `--nbActivatedAgents` is unspecified.**

### `--nbActivatedAgents` (positive integer)
The number of activated agents in each iteration.
If `n` is passed to this option, the number is always equal to `n`.

### `--epsilon` (float, default: 0.5)
**If `each` (the default value) is specified for `--acceptanceDescision`**, this sets the threshould for opinions (i.e., bounded confidence).
This is used to filter messages from other agents.
If you do not want to filter them based on opinions, specify the value equal to or larger than $\max\mathcal O$ where $\mathcal O$ is the opinion space.

**If `unified` is specified for the option**, this sets the threshold for the unified measure.

### `--delta` (non-negative integer, default: 4)
The threshould for beliefs.
This is used to filter messages from other agents.
If you do not want to filter them based on beliefs, specify the value equal to or larger than $|\mathcal M(\top)|$ where $\mathcal M(B)$ is the set of models of $B$.

### `--network` (ID to $N_a$ JSON)
The initial network agents form.
The key of JSON is the ID of agents (**0-origin**), the value corresponding to the key $a$ is $N_a$.
`-1` can be used as a key to represent the "wild card", i.e., the default configuration for all agents.
If 0-origin ID and `-1` appear at the same time, the configuration corresponds to the former key is used.

If nothing is specified, network is initialized as a random graph of $|A|$ nodes and $|E|$ edges.
$|E|$ can be configured with the option `--edges`.

**Example 1**:
```json
{
    "0": [1],
    "1": [0, 2],
    "2": [1]
}
```
refers the network $(A,E)$ where $A=\{0,1,2\}$ and $E=\{(0,1),(1,0),(1,2),(2,1)\}$.

**Example 2**:
```json
{
    "-1": [2],
    "2": [0]
}
```
refers the network $(A,E)$ where $A=\{0,1,2\}$ and $E=\{(0, 2), (1,2), (2,0)\}$.

### `--edges` (positive integer, default: 400)
The number of edges of a random graph which is generated when no initial graph is specified.

### `--values` (ID to sequence of rational number format JSON)
Cultural values which map an interpretation to a float number in $[0,1]$.
Values should be specified in JSON: the key is the ID of an agent (or `-1` as a wildcard, see `--network`) and the value is a sequence of float of JSON.
The length of the sequence in the values should be $|\mathcal M(\top)|$.
The order of numbers is defined as follows: let $p_1,\ldots,p_n$ be $n$ atomic propositions.
Then, the index of the values toward an interpretation $I$ should be at the $idx(I)$-th element where 
$$
idx(I)=\sum_{i=1}^n 2^{n-i}(1-I(p_i))
$$
and $I(p)=1$ iff $I\models p$ and $I(p)=0$ otherwise.

If nothing is specified, all agents share the same values initialized randomly.

For example, if there are two atomic propositions $p_1$ and $p_2$,

```json
{"-1": ["0/3", "1/3", "2/3", "3/3"]}
```

is interpreted as:

- if $I(p_1)=I(p_2)=1$, then $V(I)=0.0$ (index is 0)
- if $I(p_1)=1$ and $I(p_2)=0$, then $V(I)=1/3$ (index is 1)
- if $I(p_1)=0$ and $I(p_2)=1$, then $V(I)=2/3$ (index is 2)
- if $I(p_1)=I(p_2)=0$, then $V(I)=1.0$ (index is 3)

### `--beliefs` (ID to beliefs JSON)
Initial beliefs.
They should be specified in JSON: the key is the ID of an agent (or `-1` as a wildcard, see `--network`) and the value is the initial beliefs corresponding agent has.
Beliefs should be encoded as a string over `0` and `1` with the length of $|\mathcal M(\top)|$.
The $idx(I)$-th character of the string corresponding to $B$ is $I(B)$.

If nothing is specified, beliefs are initialized randomly.

For example, if there are two atomic propositions $p_1$ and $p_2$,

```json
{"-1": "1001"}
```

means that all  agents share the same initial beliefs $(p_1\land p_2)\lor (\lnot p_1\land\lnot p_2)$.

### `--opinions` (id to sequence of rational number format JSON)
Initial opinions.
They should be specified in JSON: the key is the id of an agent (or `-1` as a wildcard, see `--network`) and the value is the sequence of float of length $|T|$.
The $i$-th element of the value corresponds to the initial opinion toward $i$-th topic.

If nothing is specified, opinions are initialized randomly.

For example, if topics (see `--topics`) are specified as

```
--topics "1000,0001"
```

and the initial opinions are specified as

```json
{"-1": ["1/4", "3/4"]}
```

this means that all agents share the same initial opinions $0.25$ toward the topic `1000` and $0.75$ toward `0001`.

### `--topics` (see below)
The set of topics.
Each of the topics should be encoded as a string over `0` and `1` (see `--beliefs`).
If there are more than one topic, they should be concatnated by `,`.

If nothing is specified, topics are initialized randomly.

For example, 

```
--topics "1000,0001"
```

means that there are two topics `1000` and `0001`.

### `--precise` (positive integers, default: 10)
Set the significant digits.
**Be careful of setting too many numbers!**
Due to the computational reasons, simulator may output wrong results.
In most of the cases, the default value is enough.

### `--maximalOpinionChange` (positive float, default: 0.00001)
The threshold for opinions used to repeat performing process until stability.
**If `ofbarc` is not included in the updating strategies, this does not affect the results.**

Note: if you want to configure the threshold for opinions used during the interactions, use `--epsilon`.

### `--networkInitAlgo` (string, `random` or `randomLowerMOD`, default: `random`)
The algorithm to initialize the network.

#### `random`
The algorithm in pseudocode is as follows:

```
for each a in agents do
    b <- one agent in agents such that a != b
    add directed edge (a, b)
done
while true then
    if #current edges == #desired edges then
        break
    end if

    a <- one agent in agents
    b <- one agent in agents such that a != b
    e <- directed edge (a, b)
    if e does not exist then
        add e
    end if
end while
```

#### `randomLowerMOD`
The algorithm in pseudocode is as follows:

```
while true then
    if #current edges == #desired edges then
        break
    end if

    a <- one agent in agents
    b <- one agent in agents such that a != b
    e <- directed edge (a, b)
    if e does not exist then
        add e
    end if
end while

while there exists agent a s.t. with no neighbors then
    b <- one agent s.t. #neighbors is maximal
    remove b's one neighbor
    add agent c s.t. a != c to a's neighbor
end while
```

### `--opDistWeight` (numbers between 0 and 1, default: 0.5)
The ratio of the distance between two agents' opinions on the distance between the agents.
More precisely, this option set the parameter $\beta$ in the definition of the distance between two agents $d_A(a,a')$:

$$
d_A(a,a') = \beta d_O(O_a,O_{a'}) + (1-\beta) \frac{d_B(B_a,B_{a'})}{|\mathcal{M}(\top)|}.
$$

### `--acceptanceDescision` (see below, default: `each`)
The algorithm to decide whether other agents are considered as concordant.
Possible options are as follows:

- `each`: if opinions (resp. beliefs) are close enough, others are concordant.
- `unified`: if $d_A(a,a')\leq\varepsilon$, others are concordant.

