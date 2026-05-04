# Pygame Random Moving Squares

A small Pygame project that draws 50 moving squares with random sizes, colors, starting positions, and directions. The squares use time-based movement, bounce off the window edges, periodically change direction, flee from larger nearby squares, chase smaller nearby squares, and eventually expire and get reborn as new squares.

## Features

- 50 animated squares
- Random size, color, position, and direction for each square
- Time-based motion using `dt` so movement stays consistent across frame rates
- Edge bouncing using reflected movement angles
- Direction changes at random intervals
- Flee behavior for smaller squares near bigger ones
- Chase behavior for bigger squares near smaller ones
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

The `Square` class stores one square's position, size, color, direction, speed, lifespan, and age. The `update()` method moves the square each frame using `dt`, optionally adjusts its direction, applies both flee and chase behavior using the list of all squares, and bounces it off the edges. The main loop creates the squares once, updates and draws them every frame, and replaces expired squares with fresh ones.

Time-based motion is the current big improvement over frame-based motion: movement is scaled by elapsed time instead of by raw frame count, which makes the animation behave more consistently if the frame rate changes.

## Notes

- `NUM_SQUARES` controls how many squares appear.
- `DANGER_DISTANCE` controls how close squares must be before flee/chase behavior applies.
- `MAX_SPEED`, `MIN_SIZE`, and `MAX_SIZE` control the feel of the animation.
- Each square uses `age` and `lifespan` to determine when it should be replaced.
- `RANDOM_COLOUR` is generated once at startup and used as a fixed background color during runtime.
