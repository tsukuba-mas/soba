# SOBA: Simulator for Opinions-Beliefs interactions between Agents

![Status of CI](https://github.com/tsukuba-mas/soba//actions/workflows/run-test.yml/badge.svg)

This is the simulator of agent-based models which focus on opinions-beliefs interactions through values.

## Requirements
You will need:

- [Nim](https://nim-lang.org/) 2.0.0 or later;
- gcc;
- Git.

Dependent packages listed in `.nimble` file will be installed automatically if necessary when you compile this project.

Running this program on Linux is recommended.

## How to use
First of all, clone this repository:

```bash
$ git clone https://github.com/tsukuba-mas/soba.git
```

After you have cloned, you can compile the simulator.
**It is recommended to compile it by:**

```bash
$ nimble build -d:release -d:gitHash=`bash gethash.sh`
```

The option `-d:release` yields faster binaries than debugging build.
The option ``-d:gitHash=`bash gethash.sh` `` embeds the commit hash of the software to the binary (the sign `+` is appended at the end of hash if something has been modified).
Of course, you can add/remove options to the command above if you want.

By executing the command above, you can get the binary `soba`.
This is the simulator.
Then, launch it with some options:

```bash
$ ./soba --option1 foo --option2 bar etc.
```

You can see all of the accepted options and their descriptions by:

```bash
$ ./soba --help
```

The output from the simulator will be saved under the directory which is specified in the option `--dir` (or `-d`).

## Accepted options
See [corresponding documentation](./docs/options.md).

## Output
See [corresponding documentation](./docs/output.md).

## Author
Hiro KATAOKA (University of Tsukuba)

## License
MIT
