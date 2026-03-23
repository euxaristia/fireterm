# fireterm

ASCII animated fireplace for your terminal, written in Rust.

![fireterm](https://github.com/user-attachments/assets/placeholder)

## Features

- Heat-propagation fire simulation with turbulence and edge falloff
- ANSI true-color (24-bit) rendering: black → red → orange → yellow → white
- 30 FPS with buffered `write()` for flicker-free output
- Centered display with log and brick hearth decorations
- Clean terminal restore on exit

## Install

```sh
git clone https://github.com/euxaristia/fireterm.git
cd fireterm
cargo build --release
```

The binary will be at `target/release/fireterm`.

## Usage

```sh
cargo run --release
# or after building:
target/release/fireterm
```

Press any key to exit.

## Requirements

- Rust 2024 edition (1.85+)
- A terminal with true-color support (most modern terminals)
- Linux or macOS

## License

Public domain. See [UNLICENSE](UNLICENSE).
