# chip8-zig 🎮

A CHIP-8 emulator written in [Zig](https://ziglang.org/), using [Raylib](https://www.raylib.com/) for rendering, audio, and input.

![Zig](https://img.shields.io/badge/Zig-0.13+-F7A41D?style=flat&logo=zig&logoColor=white)
![Raylib](https://img.shields.io/badge/Raylib-5.x-white?style=flat)
![License](https://img.shields.io/badge/license-MIT-blue?style=flat)

---

## Features

- Full CHIP-8 instruction set (35 opcodes)
- 64×32 pixel display, scaled to 10× (640×320)
- Sound timer with `.wav` beep playback
- Delay and sound timers running at 60 Hz
- COSMAC VIP-compatible keyboard mapping (hex keypad → QWERTY)
- Built-in font sprites for digits `0`–`F`
- **Debugger UI** with:
  - Register viewer (V0–VF, PC, DT, ST)
  - Live keyboard state display
  - Memory / opcode viewer around current PC
  - Step forward / backward through instructions
  - Pause / resume execution

---

## Project Structure

```
.
├── src/
│   ├── main.zig          # Window, game loop, debug UI
│   ├── engine.zig        # CPU, memory, display, keyboard, timers
│   ├── instructions.zig  # All 35 CHIP-8 opcode implementations
│   ├── utils.zig         # Opcode field extraction, ROM/font loading
│   └── sprites.csv       # Reference font sprite data
├── roms/                 # Place your .ch8 ROM files here
└── beep.wav              # Sound file for the sound timer
```

---

## Getting Started

### Prerequisites

- [Zig](https://ziglang.org/download/) 0.13 or newer
- [Raylib](https://github.com/raysan5/raylib) (linked via the Zig build system)

### Build & Run

```bash
zig build run
```

By default the emulator loads `roms/pumpkindressup.ch8`. To load a different ROM, change the path in `src/main.zig`:

```zig
const source_code = try loadSourceCode("roms/your_rom.ch8");
```

---

## Keyboard Mapping

The original CHIP-8 hexadecimal keypad is mapped to a standard QWERTY keyboard as follows:

| CHIP-8 | Keyboard |   | CHIP-8 | Keyboard |
|--------|----------|---|--------|----------|
| `1`    | `1`      |   | `2`    | `2`      |
| `3`    | `3`      |   | `C`    | `4`      |
| `4`    | `Q`      |   | `5`    | `W`      |
| `6`    | `E`      |   | `D`    | `R`      |
| `7`    | `A`      |   | `8`    | `S`      |
| `9`    | `D`      |   | `E`    | `F`      |
| `A`    | `Z`      |   | `0`    | `X`      |
| `B`    | `C`      |   | `F`    | `V`      |

---

## Debugger

The emulator ships with a live debugger panel rendered alongside the game screen.

| Control | Action |
|---------|--------|
| **Stop / Start** button | Pause or resume execution |
| **`<<`** button | Step one instruction backward (while paused) |
| **`>>`** button | Step one instruction forward (while paused) |

While running, the panel shows:
- All 16 general-purpose registers (V0–VF)
- Program Counter (PC), Delay Timer (DT), Sound Timer (ST)
- The `WaitForKey` state
- Live key states for all 16 CHIP-8 keys
- Opcodes in memory around the current PC (with `=>` marker)
