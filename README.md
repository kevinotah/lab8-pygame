# Pygame Random Moving Squares

A simple Pygame application that displays 10 colorful squares moving randomly across the screen with realistic bounce physics.

## Features

- **10 animated squares** with random colors
- **Smooth random movement** with direction changes every 0.5–1.5 seconds
- **Realistic bounce physics** when squares hit screen edges
- **60 FPS rendering** for smooth animation

## Requirements

- Python 3.7+
- Pygame 2.0+

## Installation

1. Clone or download this repository.

2. Create and activate a virtual environment:
   ```bash
   python -m venv .venv
   .\.venv\Scripts\Activate  # On macOS/Linux: source .venv/bin/activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Running the Application

```bash
python main.py
```

The window will display 10 moving squares. Close the window to exit.

## How It Works

### The `Square` Class

Each square has:
- **Position** (`x`, `y`): where the square is drawn
- **Color**: random RGB values
- **Direction**: an angle (in radians) that controls movement
- **Direction timer**: triggers a new random direction every 30–90 frames

### Movement & Physics

- Motion is calculated using trigonometry: 
  - `vx = MAX_SPEED * cos(angle)`
  - `vy = MAX_SPEED * sin(angle)`
- When a square hits a wall:
  - Horizontal bounce: `angle = π - angle`
  - Vertical bounce: `angle = -angle`

### Game Loop

1. **Update**: Move all squares and handle bounces
2. **Render**: Draw white background and all squares
3. **Frame rate**: Lock to 60 FPS

## Customization

Edit `main.py` to tweak:
- `SCREEN_WIDTH` / `SCREEN_HEIGHT`: window size
- `NUM_SQUARES`: number of moving squares
- `SQUARE_SIZE`: side length of each square
- `MAX_SPEED`: movement speed
- `direction_change_interval`: how often squares change direction
