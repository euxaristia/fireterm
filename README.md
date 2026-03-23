# fireterm

ASCII animated fireplace for your terminal, written in pure Swift 6.2.

![fireterm](https://github.com/user-attachments/assets/placeholder)

## Features

- Heat-propagation fire simulation with turbulence and edge falloff
- ANSI true-color (24-bit) rendering: black → red → orange → yellow → white
- 30 FPS with double-buffered `write()` for flicker-free output
- Centered display with log and brick hearth decorations
- Clean terminal restore on exit

## Install

```sh
git clone https://github.com/euxaristia/fireterm.git
cd fireterm
swift build -c release
```

The binary will be at `.build/release/fireterm`.

## Usage

```sh
swift run fireterm
# or after building:
.build/release/fireterm
```

Press any key to exit.

## Requirements

- Swift 6.2+
- A terminal with true-color support (most modern terminals)

## License

Public domain. See [UNLICENSE](UNLICENSE).
