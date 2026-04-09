# Pygame Random Moving Squares

A small Pygame project that draws 100 moving squares with random sizes, colors, starting positions, and directions. The squares bounce off the window edges, slowly change direction over time, and use a basic flee helper to move away from larger nearby squares.

## Features

- 100 animated squares
- Random size, color, position, and direction for each square
- Edge bouncing using reflected movement angles
- Direction changes at random intervals
- A fledgling flee mechanic for smaller squares near bigger ones
- FPS counter drawn on screen

## Requirements

- Python 3.12+
- Pygame 2.6+

## Setup

1. Create and activate a virtual environment.
  ```bash
  py -3.12 -m venv .venv
  .\.venv\Scripts\Activate.ps1
  ```

2. Install dependencies.
  ```bash
  pip install -r requirements.txt
  ```

## Run

```bash
python main.py
```

## How It Works

The `Square` class stores one square's position, size, color, direction, and speed. The `update()` method moves the square each frame, optionally adjusts its direction, applies flee behavior using the list of all squares, and bounces it off the edges. The main loop creates the squares once, updates them every frame, draws them, and keeps the animation at 60 FPS.

## Notes

- `NUM_SQUARES` controls how many squares appear.
- `danger_distance` controls how close a larger square must be before a smaller one reacts.
- `MAX_SPEED`, `MIN_SIZE`, and `MAX_SIZE` control the feel of the animation.
