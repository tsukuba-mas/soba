# belop-echo-chamber

This is the simulator of agent-based models which focus on opinions-beliefs alignments through values.

## Requirements
[Nim](https://nim-lang.org/) 2.0.0 or later and gcc.
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
Then, launch it with some options:

```bash
$ ./belop_echo_chamber --option1 foo --option2 bar etc.
```

You can see all of the accepted options and their descriptions by:

```bash
$ ./belop_echo_chamber --help
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