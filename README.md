# SOBA: Simulator for Opinions-Beliefs interactions between Agents

![Status of CI](https://github.com/tsukuba-mas/soba//actions/workflows/run-test.yml/badge.svg)

This is the simulator of agent-based models which focus on opinions-beliefs interactions through values.

## Requirements
[Nim](https://nim-lang.org/) 2.0.0 or later and gcc.
Dependent packages listed in `.nimble` file will be installed automatically if necessary when you compile this project.

Running this program on Linux is recommended.

## How to use
First of all, clone this repository:

```bash
$ git clone --recurse-submodules https://github.com/tsukuba-mas/soba.git
```

**Do not forget to add the option `--recurse-submodules` to clone sub modules the simulator depends on.**

You can compile the simulator by:

```bash
$ nimble build
```

Compiling the option `-d:release` yields faster binary (recommended in general).
It is recommended to embed the Git hash.
This can be obtained by executing `gethash.sh` and passing the output by:

```bash
$ nimble build -d:gitHash=`bash gethash.sh`
```

If something has been modified from the HEAD of Git, the sign `+` is appended at the end.

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

If you have passed the Git hash when compiling, it appears at the end of the prolog.
If nothing has been passed, `unknown` is shown.

The output from the simulator will be saved under the directory which is specified in the option `--dir` (or `-d`).

## Accepted options
See [corresponding documentation](./docs/options.md).

## Output
See [corresponding documentation](./docs/output.md).

## Author
Hiro KATAOKA (University of Tsukuba)

## License
MIT
