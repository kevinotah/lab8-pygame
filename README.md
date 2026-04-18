# Pygame Random Moving Squares

A small Pygame project that draws 100 moving squares with random sizes, colors, starting positions, and directions. The squares use time-based movement, bounce off the window edges, periodically change direction, flee from larger nearby squares, and eventually expire and get reborn as new squares.

## Features

- 100 animated squares
- Random size, color, position, and direction for each square
- Time-based motion using `dt` so movement stays consistent across frame rates
- Edge bouncing using reflected movement angles
- Direction changes at random intervals
- A fledgling flee mechanic for smaller squares near bigger ones
- Lifespan and rebirth behavior for older squares
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

The `Square` class stores one square's position, size, color, direction, speed, and lifespan. The `update()` method moves the square each frame using `dt`, optionally adjusts its direction, applies flee behavior using the list of all squares, and bounces it off the edges. The main loop creates the squares once, updates them every frame, draws the surviving squares, and replaces expired ones with fresh squares.

Time-based motion is the current big improvement over frame-based motion: movement is scaled by elapsed time instead of by raw frame count, which makes the animation behave more consistently if the frame rate changes.

## Notes

- `NUM_SQUARES` controls how many squares appear.
- `danger_distance` controls how close a larger square must be before a smaller one reacts.
- `MAX_SPEED`, `MIN_SIZE`, and `MAX_SIZE` control the feel of the animation.
- `lifespan` and `certain_variable` together determine when a square is removed and replaced.
- The current code mutates the `squares` list while iterating over it, which is something to revisit if you want the rebirth logic to be more robust.
