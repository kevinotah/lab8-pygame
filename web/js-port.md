# JavaScript/HTML5 Canvas Port Plan: Smooth Squares Pygame Simulation

**Target File**: `web/index.html` (self-contained, Vanilla JS)  
**Plan Created**: May 5, 2026  
**Source Project**: `main.py` (Pygame simulation)  
**Strategy**: Strict 1-to-1 structural mapping, no refactoring

---

## 1. Executive Summary

### Project Overview
The **Smooth Squares** simulation is a real-time particle system where:
- **50 animated squares** (of varying sizes) move across a canvas
- Squares exhibit **emergent AI behavior**:
  - Smaller squares **flee** from larger neighbors
  - Larger squares **chase** smaller neighbors
  - Both behaviors operate within a `DANGER_DISTANCE` radius
- Squares **grow** when colliding with smaller squares
- Squares have a **lifespan** and are **reborn** at their current size when expired
- The simulation runs at **60 FPS** with **time-based physics** (`dt` = delta time per frame)

### Porting Scope
This plan provides a **direct translation** from Pygame to HTML5 Canvas using Vanilla JavaScript:
- ✅ All classes, methods, and properties mapped identically
- ✅ All constants and global state preserved
- ✅ All physics logic (flee, chase, collision, growth) replicated
- ✅ Timing synchronized via `requestAnimationFrame()` with timestamp-based `dt`
- ✅ Visual output (colors, positions, sizes, debug text) rendered on Canvas
- ✅ No refactoring, bug fixes, or feature additions
- ✅ Single self-contained `index.html` file for deployment

---

## 2. Architecture Mapping

### Python Classes → JavaScript Classes

| Python Class | JavaScript Class | Purpose |
|--------------|------------------|---------|
| `Square` | `Square` | Represents a single animated square entity with position, size, color, behavior, and lifespan |
| (None) | `Game` | (Pseudo-class) Encapsulates the main game loop, canvas setup, and simulation state |

### Python Functions → JavaScript Functions

| Python Function | JavaScript Function | Purpose |
|-----------------|---------------------|---------|
| `make_random_colour()` | `makeRandomColour()` | Generate a random RGB color as a tuple/array |
| `main()` | (Integrated into `Game` class) | Set up canvas, initialize squares, run game loop |
| (Module level) | `initGame()` | Entry point called on page load |

### Python Modules & Imports

| Pygame Module | JavaScript Equivalent |
|---------------|----------------------|
| `pygame` | HTML5 Canvas API + CanvasRenderingContext2D |
| `random` | `Math.random()` + utility functions |
| `math` | `Math` object (for `cos`, `sin`, `sqrt`, `pi`) |
| `typing` | JSDoc type annotations |

### Global State Structure

```
// Python (module level)
SCREEN_WIDTH: int = 800
SCREEN_HEIGHT: int = 600
FPS: int = 60
... (other constants)
font: pygame.font.Font = ...
RANDOM_COLOUR: Tuple[int, int, int] = ...

// JavaScript (module level)
const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 600;
const FPS = 60;
... (other constants)
const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');
const RANDOM_COLOUR = makeRandomColour();
```

---

## 3. Data Structure & Type Mapping

### Primitive Types

| Python | JavaScript | Notes |
|--------|----------|-------|
| `int` | `number` | All numeric values are `number` in JS |
| `float` | `number` | Same as `int` in JS |
| `str` | `string` | Text values |
| `bool` | `boolean` | `True` / `False` → `true` / `false` |
| `List[T]` | `Array<T>` | Dynamic arrays |
| `Tuple[int, int, int]` | `Array<number>` | Fixed-size RGB color tuple → array |
| `Dict` | `Object` | Key-value pairs |

### Complex Type Mappings

#### Python Tuple (RGB Color)
```python
# Python
color: Tuple[int, int, int] = (255, 128, 64)

# JavaScript
const color = [255, 128, 64];
// or
const color = { r: 255, g: 128, b: 64 };
// Converted to CSS string when drawing:
const colorStr = `rgb(${color[0]}, ${color[1]}, ${color[2]})`;
```

#### Python List of Objects
```python
# Python
squares: List[Square] = [Square(25), Square(10), ...]

# JavaScript
const squares = [new Square(25), new Square(10), ...];
```

### Type Hints in JavaScript (JSDoc)

```javascript
/**
 * Update the square's position and behavior.
 * @param {Square[]} allSquares - List of all squares in the simulation
 * @param {number} dt - Delta time in seconds since last frame
 * @returns {void}
 */
update(allSquares, dt) { ... }
```

---

## 4. Simulation Loop & Timing Strategy

### Python Timing Model
```python
clock = pygame.time.Clock()
while running:
    dt = clock.tick(FPS) / 1000.0  # milliseconds to seconds
    # ... update and draw ...
    pygame.display.flip()
```

### JavaScript Timing Model (requestAnimationFrame)
```javascript
let lastTime = performance.now();
let running = true;

function gameLoop(currentTime) {
  const dt = (currentTime - lastTime) / 1000.0;  // milliseconds to seconds
  lastTime = currentTime;
  
  // ... update and draw ...
  
  if (running) {
    requestAnimationFrame(gameLoop);
  }
}

requestAnimationFrame(gameLoop);
```

### Key Timing Differences
- **Python**: `clock.tick(FPS)` caps the frame rate and returns milliseconds elapsed
- **JavaScript**: `requestAnimationFrame()` is called whenever the browser is ready to draw (typically 60 FPS), and we calculate `dt` manually using timestamps
- **Delta Time**: Both use `dt` in seconds to scale movement, ensuring physics consistency across frame rates
- **Assumption**: Browser will attempt to run at ~60 FPS (native refresh rate). If browser runs slower, `dt` will be larger, and squares will move accordingly.

### Pseudocode: Main Game Loop
```javascript
const gameState = {
  running: true,
  squares: [],
  lastFrameTime: 0
};

function gameLoop(currentTime) {
  // 1. Calculate delta time
  const dt = (currentTime - gameState.lastFrameTime) / 1000.0;
  gameState.lastFrameTime = currentTime;
  
  // 2. Handle input (quit event)
  // (In JS, this is typically a button or page close)
  
  // 3. Update all squares
  for (let square of gameState.squares) {
    square.update(gameState.squares, dt);
  }
  
  // 4. Clear canvas and draw background
  ctx.fillStyle = colorToString(RANDOM_COLOUR);
  ctx.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
  
  // 5. Draw all squares
  for (let square of gameState.squares) {
    square.draw(ctx);
  }
  
  // 6. Rebuild squares list (remove expired, add reborn)
  const newSquares = [];
  for (let square of gameState.squares) {
    square.age += dt;
    if (square.age < square.lifespan) {
      newSquares.push(square);
    } else {
      newSquares.push(new Square(Math.round(square.size)));
    }
  }
  gameState.squares = newSquares;
  
  // 7. Draw debug text
  drawDebugText(gameState.squares.length);
  
  // 8. Schedule next frame
  if (gameState.running) {
    requestAnimationFrame(gameLoop);
  }
}

// Start the loop
requestAnimationFrame(gameLoop);
```

---

## 5. Graphics Rendering Strategy

### Canvas Context Setup
```javascript
// Python: pygame.display.set_mode((width, height))
const canvas = document.getElementById('gameCanvas');
canvas.width = SCREEN_WIDTH;
canvas.height = SCREEN_HEIGHT;
const ctx = canvas.getContext('2d');
```

### Pygame Draw Calls → Canvas API

| Pygame | Canvas Equivalent |
|--------|-------------------|
| `pygame.draw.rect(surf, color, (x, y, w, h))` | `ctx.fillStyle = colorStr; ctx.fillRect(x, y, w, h)` |
| `surface.fill(color)` | `ctx.fillStyle = colorStr; ctx.fillRect(0, 0, width, height)` |
| `pygame.display.flip()` | (Implicit in `requestAnimationFrame()`) |
| `font.render(text, True, color)` | `ctx.fillStyle = colorStr; ctx.fillText(text, x, y)` |
| `surface.blit(text_surface, (x, y))` | (Implicit in `ctx.fillText()`) |

### Color Conversion

#### Python → JavaScript
```python
# Python: RGB tuple
color = (255, 128, 64)

# JavaScript: CSS color string
const color = [255, 128, 64];
const colorStr = `rgb(${color[0]}, ${color[1]}, ${color[2]})`;
// Or hex: `#${color[0].toString(16)}${color[1].toString(16)}${color[2].toString(16)}`
```

#### Helper Function
```javascript
/**
 * Convert RGB array/tuple to CSS color string.
 * @param {number[]} rgbTuple - [r, g, b] values (0-255)
 * @returns {string} CSS rgb() format string
 */
function colorToString(rgbTuple) {
  return `rgb(${rgbTuple[0]}, ${rgbTuple[1]}, ${rgbTuple[2]})`;
}
```

### Coordinate System
- **Python/Pygame**: Origin (0, 0) at top-left; x increases right, y increases down
- **JavaScript/Canvas**: Origin (0, 0) at top-left; x increases right, y increases down
- **Conclusion**: Coordinate systems are identical. No transformation needed.

### Rendering Pipeline (Per Frame)
1. Clear canvas (fill background)
2. Draw all squares (filled rectangles)
3. Draw debug text (FPS, square count)
4. **No explicit flip**: Canvas is automatically updated by the browser

### Font Rendering
```javascript
// Python
font = pygame.font.Font(None, 30)
text_surface = font.render("FPS: 60.000", True, (0, 0, 0))
screen.blit(text_surface, (50, 20))

// JavaScript
ctx.font = '30px Arial';
ctx.fillStyle = 'rgb(0, 0, 0)';
ctx.fillText('FPS: 60.000', 50, 20);
```

---

## 6. Class-by-Class Porting Guide

### Class: `Square`

#### Constructor: `__init__(self, size: int) -> None` → `constructor(size)`

**Python**:
```python
def __init__(self, size: int) -> None:
    self.size = size
    self.x = random.randint(0, SCREEN_WIDTH - self.size)
    self.y = random.randint(0, SCREEN_HEIGHT - self.size)
    self.color = (random.randint(50, 255), ..., ...)
    self.angle = random.uniform(0, 2 * math.pi)
    self.direction_timer = 0.0
    self.direction_change_interval = random.uniform(0.8, 2.0)
    size_ratio = (self.size - MIN_SIZE) / (MAX_SIZE - MIN_SIZE)
    self.speed = MAX_SPEED * (1 - size_ratio)
    self.lifespan = random.randint(30, 180)
    self.age = 0.0
```

**JavaScript**:
```javascript
constructor(size) {
  this.size = size;
  this.x = Math.floor(Math.random() * (SCREEN_WIDTH - this.size));
  this.y = Math.floor(Math.random() * (SCREEN_HEIGHT - this.size));
  this.color = [
    Math.floor(Math.random() * 206) + 50,  // random 50-255
    Math.floor(Math.random() * 206) + 50,
    Math.floor(Math.random() * 206) + 50
  ];
  this.angle = Math.random() * 2 * Math.PI;
  this.directionTimer = 0.0;
  this.directionChangeInterval = Math.random() * 1.2 + 0.8;  // uniform(0.8, 2.0)
  const sizeRatio = (this.size - MIN_SIZE) / (MAX_SIZE - MIN_SIZE);
  this.speed = MAX_SPEED * (1 - sizeRatio);
  this.lifespan = Math.floor(Math.random() * 151) + 30;  // random 30-180
  this.age = 0.0;
}
```

**Porting Notes**:
- `self` → `this`
- `random.randint(a, b)` → `Math.floor(Math.random() * (b - a + 1)) + a`
- `random.uniform(a, b)` → `Math.random() * (b - a) + a`
- `math.pi` → `Math.PI`
- Python tuple for color → JavaScript array

#### Method: `update(self, all_squares: List['Square'], dt: float) -> None`

**Python Structure**:
1. Update direction timer and angle
2. Calculate base velocity from angle and speed
3. Compute flee and chase vectors
4. Apply behavioral forces to velocity
5. Update position with scaled velocity
6. Handle boundary wrapping
7. Check collisions with all other squares
8. Growth when colliding and size > other.size

**JavaScript**:
```javascript
update(allSquares, dt) {
  // 1. Direction change logic
  this.directionTimer += dt;
  if (this.directionTimer >= this.directionChangeInterval) {
    this.angle += (Math.random() * 2 - 1) * 0.8;  // random(-1, 1) * 0.8
    this.directionTimer = 0;
    this.directionChangeInterval = Math.random() * 1.2 + 0.8;
  }
  
  // 2. Base motion
  let vx = Math.cos(this.angle) * this.speed;
  let vy = Math.sin(this.angle) * this.speed;
  
  // 3. Flee and chase behaviors
  const [fleeDx, fleeDy] = this.computeFleeVector(allSquares);
  const [chaseDx, chaseDy] = this.computeChaseVector(allSquares);
  
  // 4. Apply forces
  vx += fleeDx * 120;
  vy += fleeDy * 120;
  vx -= chaseDx * 120;
  vy -= chaseDy * 120;
  
  // 5. Update position
  this.x += vx * dt;
  this.y += vy * dt;
  
  // 6. Boundary wrapping
  if (this.x < 0) {
    this.x = SCREEN_WIDTH - this.size;
  } else if (this.x > SCREEN_WIDTH - this.size) {
    this.x = 0;
  }
  
  if (this.y < 0) {
    this.y = SCREEN_HEIGHT - this.size;
  } else if (this.y > SCREEN_HEIGHT - this.size) {
    this.y = 0;
  }
  
  // 7. Collision and growth
  for (let square of allSquares) {
    if (square === this) continue;
    if (this.checkCollision(square) && this.size > square.size && this.size < MAX_GROWTH_SIZE) {
      square.lifespan = 0;  // Mark for rebirth
      this.size *= 1 + (square.size / MAX_SIZE);
    }
  }
}
```

**Porting Notes**:
- `random.uniform(-1.0, 1.0)` → `Math.random() * 2 - 1`
- Return tuple unpacking `a, b = func()` → destructuring `const [a, b] = func()`
- `self.x` → `this.x`
- Condition `is self` → `=== this`

#### Method: `compute_flee_vector(self, all_squares: List['Square']) -> Tuple[float, float]`

**Python**:
```python
def compute_flee_vector(self, all_squares: List['Square']) -> Tuple[float, float]:
    flee_dx: float = 0.0
    flee_dy: float = 0.0
    for other in all_squares:
        if other is self:
            continue
        dx: float = self.x - other.x
        dy: float = self.y - other.y
        dist: float = math.sqrt(dx*dx + dy*dy)
        if other.size > self.size and 0 < dist < DANGER_DISTANCE:
            strength: float = (1 - dist / DANGER_DISTANCE)
            flee_dx += (dx / dist) * strength
            flee_dy += (dy / dist) * strength
    return flee_dx, flee_dy
```

**JavaScript**:
```javascript
computeFleeVector(allSquares) {
  let fleeDx = 0.0;
  let fleeDy = 0.0;
  
  for (let other of allSquares) {
    if (other === this) continue;
    
    const dx = this.x - other.x;
    const dy = this.y - other.y;
    const dist = Math.sqrt(dx * dx + dy * dy);
    
    if (other.size > this.size && 0 < dist && dist < DANGER_DISTANCE) {
      const strength = 1 - (dist / DANGER_DISTANCE);
      fleeDx += (dx / dist) * strength;
      fleeDy += (dy / dist) * strength;
    }
  }
  
  return [fleeDx, fleeDy];
}
```

**Porting Notes**:
- Method names converted to `camelCase`
- Python tuple return → JavaScript array return

#### Method: `compute_chase_vector(self, all_squares: List['Square']) -> Tuple[float, float]`

**Python**:
```python
def compute_chase_vector(self, all_squares: List['Square']) -> Tuple[float, float]:
    chase_dx: float = 0.0
    chase_dy: float = 0.0
    for other in all_squares:
        if other is self:
            continue
        dx: float = self.x - other.x
        dy: float = self.y - other.y
        dist: float = math.sqrt(dx*dx + dy*dy)
        if other.size < self.size and 0 < dist < DANGER_DISTANCE:
            strength: float = (1 - dist / DANGER_DISTANCE)
            chase_dx += (dx / dist) * strength
            chase_dy += (dy / dist) * strength
    return chase_dx, chase_dy
```

**JavaScript**:
```javascript
computeChaseVector(allSquares) {
  let chaseDx = 0.0;
  let chaseDy = 0.0;
  
  for (let other of allSquares) {
    if (other === this) continue;
    
    const dx = this.x - other.x;
    const dy = this.y - other.y;
    const dist = Math.sqrt(dx * dx + dy * dy);
    
    if (other.size < this.size && 0 < dist && dist < DANGER_DISTANCE) {
      const strength = 1 - (dist / DANGER_DISTANCE);
      chaseDx += (dx / dist) * strength;
      chaseDy += (dy / dist) * strength;
    }
  }
  
  return [chaseDx, chaseDy];
}
```

**Porting Notes**:
- Identical structure to `computeFleeVector()` except the condition is `other.size < this.size`

#### Method: `draw(self, screen: pygame.Surface) -> None`

**Python**:
```python
def draw(self, screen: pygame.Surface) -> None:
    pygame.draw.rect(screen, self.color, (self.x, self.y, self.size, self.size))
```

**JavaScript**:
```javascript
draw(ctx) {
  // Equivalent to pygame.draw.rect(screen, color, (x, y, w, h))
  ctx.fillStyle = colorToString(this.color);
  ctx.fillRect(this.x, this.y, this.size, this.size);
}
```

**Porting Notes**:
- Method signature: `screen` → `ctx` (Canvas context)
- `pygame.draw.rect()` → `ctx.fillStyle` + `ctx.fillRect()`
- `self.color` must be converted to CSS string

#### Method: `_check_collision(self, other) -> bool`

**Python**:
```python
def _check_collision(self, other) -> bool:
    self_rect = pygame.Rect(self.x, self.y, self.size, self.size)
    other_rect = pygame.Rect(other.x, other.y, other.size, other.size)
    collision: bool = self_rect.colliderect(other_rect)
    return collision
```

**JavaScript**:
```javascript
checkCollision(other) {
  // Equivalent to pygame.Rect.colliderect()
  // Two rectangles collide if they overlap on both axes
  const selfRight = this.x + this.size;
  const selfBottom = this.y + this.size;
  const otherRight = other.x + other.size;
  const otherBottom = other.y + other.size;
  
  return this.x < otherRight && selfRight > other.x &&
         this.y < otherBottom && selfBottom > other.y;
}
```

**Porting Notes**:
- `_check_collision()` → `checkCollision()` (underscore convention → camelCase)
- `pygame.Rect.colliderect()` → Manual AABB (axis-aligned bounding box) collision test

---

## 7. Function-by-Function Porting Guide

### Function: `make_random_colour() -> Tuple[int, int, int]`

**Python**:
```python
def make_random_colour() -> Tuple[int, int, int]:
    return (
        random.randint(0, 255),
        random.randint(0, 255),
        random.randint(0, 255)
    )
```

**JavaScript**:
```javascript
/**
 * Generate a random RGB color as an array.
 * @returns {number[]} Array [r, g, b] with values 0-255
 */
function makeRandomColour() {
  return [
    Math.floor(Math.random() * 256),
    Math.floor(Math.random() * 256),
    Math.floor(Math.random() * 256)
  ];
}
```

**Porting Notes**:
- Function name converted to `camelCase`
- Return Python tuple → JavaScript array

### Function: `main() -> None` (Refactored as Game Loop)

**Python**:
```python
def main() -> None:
    screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
    pygame.display.set_caption("Smooth Squares")
    clock = pygame.time.Clock()
    
    squares = []
    for _ in range(5): squares.append(Square(25))
    for _ in range(10): squares.append(Square(10))
    for _ in range(30): squares.append(Square(4))
    
    running = True
    while running:
        dt = clock.tick(FPS) / 1000.0
        
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
        
        for square in squares:
            square.update(squares, dt)
        
        screen.fill(RANDOM_COLOUR)
        
        for square in squares:
            square.draw(screen)
        
        new_squares = []
        for square in squares:
            square.age += dt
            if square.age < square.lifespan:
                new_squares.append(square)
            else:
                new_squares.append(Square(int(square.size)))
        
        squares = new_squares
        
        number_of_squares = font.render(f"{len(squares)} squares", True, 'Black')
        screen.blit(number_of_squares, (50, 20))
        
        actual_fps = font.render(f"FPS: {clock.get_fps():.3f}", True, 'Black')
        screen.blit(actual_fps, (50, 50))
        
        pygame.display.flip()
    
    pygame.quit()
```

**JavaScript** (Top-level initialization + game loop):
```javascript
// Global game state
const gameState = {
  running: true,
  squares: [],
  lastFrameTime: 0
};

/**
 * Initialize the game canvas and squares.
 * Equivalent to pygame setup in main().
 */
function initGame() {
  const canvas = document.getElementById('gameCanvas');
  canvas.width = SCREEN_WIDTH;
  canvas.height = SCREEN_HEIGHT;
  
  const ctx = canvas.getContext('2d');
  ctx.font = '30px Arial';
  
  // Initialize squares (same distribution as Python)
  for (let i = 0; i < 5; i++) {
    gameState.squares.push(new Square(25));
  }
  for (let i = 0; i < 10; i++) {
    gameState.squares.push(new Square(10));
  }
  for (let i = 0; i < 30; i++) {
    gameState.squares.push(new Square(4));
  }
  
  // Start the game loop
  requestAnimationFrame(gameLoop);
}

/**
 * Main game loop. Equivalent to pygame while loop.
 * @param {number} currentTime - High-resolution timestamp from requestAnimationFrame
 */
function gameLoop(currentTime) {
  const canvas = document.getElementById('gameCanvas');
  const ctx = canvas.getContext('2d');
  
  // Calculate delta time (equivalent to clock.tick() / 1000.0)
  if (gameState.lastFrameTime === 0) {
    gameState.lastFrameTime = currentTime;
  }
  const dt = (currentTime - gameState.lastFrameTime) / 1000.0;
  gameState.lastFrameTime = currentTime;
  
  // Update all squares (equivalent to square.update() loop)
  for (let square of gameState.squares) {
    square.update(gameState.squares, dt);
  }
  
  // Clear and fill background (equivalent to screen.fill())
  ctx.fillStyle = colorToString(RANDOM_COLOUR);
  ctx.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
  
  // Draw all squares (equivalent to square.draw() loop)
  for (let square of gameState.squares) {
    square.draw(ctx);
  }
  
  // Rebuild squares list: age and rebirth (equivalent to new_squares logic)
  const newSquares = [];
  for (let square of gameState.squares) {
    square.age += dt;
    if (square.age < square.lifespan) {
      newSquares.push(square);
    } else {
      newSquares.push(new Square(Math.round(square.size)));
    }
  }
  gameState.squares = newSquares;
  
  // Draw debug text (equivalent to font.render() and screen.blit())
  ctx.fillStyle = 'rgb(0, 0, 0)';  // Black
  ctx.fillText(`${gameState.squares.length} squares`, 50, 20);
  ctx.fillText(`FPS: ${(1000 / (dt * 1000)).toFixed(3)}`, 50, 50);
  
  // Schedule next frame (equivalent to pygame.display.flip() and loop continuation)
  if (gameState.running) {
    requestAnimationFrame(gameLoop);
  }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', initGame);
```

**Porting Notes**:
- `main()` split into `initGame()` (setup) and `gameLoop()` (loop)
- `pygame.display.set_mode()` → `canvas` element + `getContext('2d')`
- `clock.tick(FPS)` → `requestAnimationFrame()` + manual `dt` calculation
- `pygame.event.QUIT` → No explicit equivalent (user closes tab/window)
- `pygame.display.flip()` → Implicit in `requestAnimationFrame()` cycle
- `pygame.quit()` → No cleanup needed in JS

---

## 8. Event Loop & Main Game Loop

### Comparison: Event Handling

#### Python/Pygame Model
```python
while running:
    dt = clock.tick(FPS) / 1000.0
    
    # Event handling
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
    
    # Update and draw...
    pygame.display.flip()
```

- **Blocking**: The loop actively polls for events each frame
- **FPS Control**: `clock.tick()` enforces the frame rate
- **Exit**: Player closes the window, sets `pygame.QUIT` event

#### JavaScript/Canvas Model
```javascript
function gameLoop(currentTime) {
  const dt = (currentTime - lastFrameTime) / 1000.0;
  lastFrameTime = currentTime;
  
  // Update and draw...
  
  requestAnimationFrame(gameLoop);
}

requestAnimationFrame(gameLoop);
```

- **Non-blocking**: Browser calls `gameLoop` when ready to draw (~60 FPS)
- **FPS Control**: Browser controls refresh rate (typically screen refresh)
- **Exit**: User closes tab/page (implicit, no explicit event handling needed)

### Key Differences

| Aspect | Python/Pygame | JavaScript/Canvas |
|--------|---------------|-------------------|
| **Flow Control** | While loop (blocks) | Callback via requestAnimationFrame |
| **FPS Limiting** | Explicit `clock.tick(FPS)` | Browser default (~60 FPS) |
| **Delta Time** | Returned by `clock.tick()` | Calculated from timestamps |
| **Events** | Polled via `pygame.event.get()` | Async via `addEventListener()` |
| **Screen Update** | Explicit `pygame.display.flip()` | Automatic after draw calls |

### Pseudocode: Game Loop (JavaScript)

```javascript
// State
const state = {
  running: true,
  lastFrameTime: 0,
  squares: [],
  ctx: null
};

// Main loop
function gameLoop(currentTime) {
  // 1. Calculate dt
  const dt = calculateDeltaTime(currentTime, state);
  
  // 2. Update
  updateAllSquares(state.squares, dt);
  
  // 3. Render
  clearCanvas(state.ctx);
  drawAllSquares(state.ctx, state.squares);
  drawDebugText(state.ctx, state.squares.length);
  
  // 4. Rebuild expired squares
  rebuildSquaresList(state);
  
  // 5. Schedule next frame
  if (state.running) {
    requestAnimationFrame(gameLoop);
  }
}

// Start
requestAnimationFrame(gameLoop);
```

---

## 9. Canvas Rendering & Drawing

### Coordinate System

Both Pygame and Canvas use the same coordinate system:
- **Origin**: (0, 0) at top-left corner
- **X-axis**: Increases to the right
- **Y-axis**: Increases downward
- **Conclusion**: No transformation or offset needed

### Drawing Operations

#### Background Fill

**Python**:
```python
screen.fill(RANDOM_COLOUR)  # RANDOM_COLOUR = (r, g, b)
```

**JavaScript**:
```javascript
ctx.fillStyle = `rgb(${RANDOM_COLOUR[0]}, ${RANDOM_COLOUR[1]}, ${RANDOM_COLOUR[2]})`;
ctx.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
```

#### Rectangle (Square) Drawing

**Python**:
```python
pygame.draw.rect(screen, self.color, (self.x, self.y, self.size, self.size))
```

**JavaScript**:
```javascript
ctx.fillStyle = `rgb(${this.color[0]}, ${this.color[1]}, ${this.color[2]})`;
ctx.fillRect(this.x, this.y, this.size, this.size);
```

#### Text Rendering

**Python**:
```python
font = pygame.font.Font(None, 30)
text_surface = font.render("FPS: 60.000", True, (0, 0, 0))
screen.blit(text_surface, (50, 20))
```

**JavaScript**:
```javascript
ctx.font = '30px Arial';
ctx.fillStyle = 'rgb(0, 0, 0)';
ctx.fillText('FPS: 60.000', 50, 20);
```

### Color Handling

#### RGB Tuple to CSS String

**Helper Function**:
```javascript
function colorToString(rgbArray) {
  return `rgb(${rgbArray[0]}, ${rgbArray[1]}, ${rgbArray[2]})`;
}
```

#### Usage
```javascript
// Set fill color before drawing
ctx.fillStyle = colorToString(square.color);
ctx.fillRect(square.x, square.y, square.size, square.size);
```

### Canvas State Management

Important Canvas properties that must be set:
- `ctx.fillStyle`: Color for fill operations
- `ctx.font`: Font family and size for text
- `ctx.globalAlpha`: Opacity (default 1.0, not used here)

**Setup in `initGame()`**:
```javascript
ctx.font = '30px Arial';
```

---

## 10. Potential Challenges & Workarounds

### Challenge 1: Precision Loss in Floating-Point Math

**Issue**: Python and JavaScript both use IEEE 754 floats, but minor rounding differences can accumulate over thousands of frames.

**Workaround**: 
- Keep physics calculations identical
- If precise frame-by-frame comparison is needed, periodically clamp positions to avoid drift
- Alternatively, use fixed-point arithmetic (not recommended for this project)

### Challenge 2: Random Number Generation

**Issue**: Python's `random` module and JavaScript's `Math.random()` use different algorithms and seeds.

**Workaround**:
- For this port, minor randomness differences are acceptable (different square spawn positions, colors, angles each run)
- If deterministic reproduction is needed, implement a seeded PRNG in JavaScript (e.g., Mersenne Twister)
- Current approach: Use `Math.random()` directly

### Challenge 3: Frame Rate Differences

**Issue**: Pygame enforces 60 FPS via `clock.tick(60)`, but browsers vary (60 FPS on 60Hz displays, 120 FPS on 120Hz displays).

**Workaround**:
- Use `dt` (delta time) consistently to ensure simulation speed is independent of frame rate
- Physics calculations already use `dt`, so this should work seamlessly
- If strict 60 FPS is needed, manually cap `dt` in JavaScript:
```javascript
const MAX_DT = 1 / 60;  // Cap to 60 FPS
const cappedDt = Math.min(dt, MAX_DT);
```

### Challenge 4: Font Rendering

**Issue**: Pygame and Canvas render text with different font metrics and anti-aliasing.

**Workaround**:
- Use generic font families in Canvas (`Arial`, `sans-serif`)
- Accept minor visual differences in text appearance
- For exact replication, would need to use web fonts or canvas text metrics API

### Challenge 5: Collision Detection Accuracy

**Issue**: Pygame's `Rect.colliderect()` uses integer pixel-level collision; Canvas simulation uses floats.

**Workaround**:
- Implement AABB collision as in the Square class (floats are fine)
- Minor precision differences should not affect simulation behavior significantly

### Challenge 6: Performance Considerations

**Issue**: JavaScript may run slower than Python, especially with 50 squares.

**Workaround**:
- Optimize collision detection if needed (spatial partitioning, quadtree)
- Use `requestAnimationFrame()` to sync with browser refresh
- Monitor FPS; if dropping below 30 FPS, reduce square count

### Challenge 7: Module Scope and Global State

**Issue**: Python uses module-level globals and Pygame singletons; JavaScript modules must manage state differently.

**Workaround**:
- Store constants and game state in global scope (acceptable for single-file demo)
- Alternatively, use a `GameState` object or class for better encapsulation
- Current approach: Global constants + `gameState` object

---

## 11. Testing Strategy

### Unit Testing (Per Component)

#### Test 1: Square Constructor
```javascript
// Verify a new square initializes with valid properties
const square = new Square(10);
console.assert(square.size === 10, 'Size should be 10');
console.assert(square.age === 0, 'Age should start at 0');
console.assert(square.x >= 0 && square.x < SCREEN_WIDTH, 'X should be in bounds');
```

#### Test 2: Collision Detection
```javascript
// Two overlapping squares should collide
const sq1 = new Square(10);
sq1.x = 50; sq1.y = 50;

const sq2 = new Square(10);
sq2.x = 55; sq2.y = 55;

console.assert(sq1.checkCollision(sq2) === true, 'Should collide');
```

#### Test 3: Flee Vector
```javascript
// Large square nearby should produce non-zero flee vector
const small = new Square(5);
small.x = 100; small.y = 100;

const large = new Square(25);
large.x = 110; large.y = 100;  // 10 pixels away, within DANGER_DISTANCE

const [fleeDx, fleeDy] = small.computeFleeVector([large]);
console.assert(fleeDx < 0, 'Should flee left (away from large square)');
```

### Integration Testing (Full Simulation)

#### Test 4: Simulation Runs for 10 Seconds
```javascript
// Run the game loop for 10 seconds, verify no crashes
let elapsedTime = 0;
const TEST_DURATION = 10000;  // 10 seconds

function testGameLoop(currentTime) {
  elapsedTime = currentTime;
  
  gameLoop(currentTime);
  
  if (elapsedTime < TEST_DURATION) {
    requestAnimationFrame(testGameLoop);
  } else {
    console.log('✓ Test passed: Simulation ran for 10 seconds');
  }
}

requestAnimationFrame(testGameLoop);
```

#### Test 5: Frame Rate Verification
```javascript
// Measure actual frame rate
let frameCount = 0;
let lastCheckTime = performance.now();

function measureFps() {
  frameCount++;
  const now = performance.now();
  if (now - lastCheckTime >= 1000) {
    console.log(`FPS: ${frameCount}`);
    frameCount = 0;
    lastCheckTime = now;
  }
}
// Call in gameLoop
```

#### Test 6: Visual Inspection
- Run the HTML file in a browser
- Verify squares move smoothly in random directions
- Verify smaller squares flee from larger ones
- Verify larger squares chase smaller ones
- Verify squares grow when colliding with smaller squares
- Verify squares respawn after lifespan expires
- Verify debug text (square count, FPS) displays correctly

#### Test 7: Behavior Comparison
```
Manual Verification Checklist:
- [ ] Square movement speed and direction appear consistent with Python version
- [ ] Flee behavior triggers within DANGER_DISTANCE
- [ ] Chase behavior triggers within DANGER_DISTANCE
- [ ] Collision growth visually matches Python behavior
- [ ] Debug text (count, FPS) renders clearly
- [ ] Animation is smooth (no stuttering)
- [ ] No memory leaks (performance stable over time)
```

---

## 12. File Structure & Organization

### Directory Layout

```
lab8-pygame/
├── main.py                          # Original Python/Pygame source
├── README.md                        # Project documentation
├── requirements.txt                 # Python dependencies
├── JOURNAL.md                       # Development journal
│
├── .github/
│   ├── prompts/
│   │   └── transpiler.prompt.md    # This transpiler agent prompt
│   ├── agents/
│   │   ├── *.agent.md              # Existing agents
│   └── ...
│
└── web/                             # ← NEW: JavaScript/Canvas output
    ├── js-port.md                   # This porting plan
    ├── index.html                   # Final self-contained file (to be created)
    └── (optional: assets/ or other files if needed later)
```

### Self-Contained HTML Structure

**Target File**: `web/index.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Smooth Squares - Canvas Port</title>
  <style>
    body {
      margin: 0;
      padding: 0;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      background-color: #f0f0f0;
    }
    canvas {
      border: 2px solid #333;
      display: block;
      background-color: #fff;
    }
  </style>
</head>
<body>
  <canvas id="gameCanvas"></canvas>
  
  <script>
    // ===== CONSTANTS =====
    // (All globals and constants here)
    
    // ===== UTILITY FUNCTIONS =====
    // (makeRandomColour, colorToString, etc.)
    
    // ===== SQUARE CLASS =====
    // (Complete Square class definition)
    
    // ===== GAME STATE & INITIALIZATION =====
    // (gameState, initGame, gameLoop)
    
    // ===== PAGE LOAD =====
    // (Event listener to start game)
  </script>
</body>
</html>
```

---

## 13. Implementation Checklist

Use this checklist to track progress during the implementation phase:

### Phase 1: Setup & Foundation
- [ ] Create `web/index.html` with basic canvas element and CSS
- [ ] Set up `<canvas id="gameCanvas">` and CanvasRenderingContext2D
- [ ] Define all global constants (SCREEN_WIDTH, FPS, DANGER_DISTANCE, etc.)
- [ ] Implement `makeRandomColour()` function
- [ ] Implement `colorToString()` helper function

### Phase 2: Square Class
- [ ] Implement `Square.constructor(size)`
- [ ] Implement `Square.update(allSquares, dt)`
- [ ] Implement `Square.computeFleeVector(allSquares)`
- [ ] Implement `Square.computeChaseVector(allSquares)`
- [ ] Implement `Square.draw(ctx)`
- [ ] Implement `Square.checkCollision(other)`

### Phase 3: Game Loop & Initialization
- [ ] Create `gameState` object to hold simulation state
- [ ] Implement `initGame()` function (canvas setup, square initialization)
- [ ] Implement `gameLoop(currentTime)` function (delta time, updates, rendering)
- [ ] Implement debug text rendering (square count, FPS)

### Phase 4: Rendering Pipeline
- [ ] Implement background fill (canvas clear)
- [ ] Implement square drawing (ctx.fillRect loop)
- [ ] Implement text rendering (FPS and count)
- [ ] Verify coordinate system (no transformations needed)
- [ ] Verify colors render correctly

### Phase 5: Integration & Testing
- [ ] Call `initGame()` on page load via `DOMContentLoaded`
- [ ] Verify game loop starts automatically
- [ ] Run in browser and observe square movement
- [ ] Verify flee/chase behavior visually
- [ ] Verify collision growth visually
- [ ] Verify debug text updates
- [ ] Verify no console errors

### Phase 6: Performance & Polish
- [ ] Monitor FPS (target: stable 60 FPS or better)
- [ ] Check for memory leaks (run for 5+ minutes)
- [ ] Verify smooth animation (no stuttering)
- [ ] Optional: Add comments explaining Pygame equivalences
- [ ] Optional: Test on different browsers/devices

### Phase 7: Documentation
- [ ] Add JSDoc comments to all classes and methods
- [ ] Add inline comments for non-obvious logic
- [ ] Verify this `js-port.md` matches final implementation
- [ ] Update project README if needed

---

## Summary

This porting plan provides a complete roadmap for translating the Python/Pygame **Smooth Squares** simulation into Vanilla JavaScript with HTML5 Canvas. The plan maintains **strict 1-to-1 structural parity**, ensuring students can trace behavior directly between the two implementations.

### Key Takeaways

1. **Structural Mapping**: Every class, method, and function has a direct JavaScript equivalent
2. **Timing Strategy**: `requestAnimationFrame()` + timestamp-based `dt` replaces Pygame's `clock.tick()`
3. **Graphics**: Canvas CanvasRenderingContext2D replaces Pygame's drawing functions
4. **No Refactoring**: Logic, variable names, and algorithms remain identical (only style and naming conventions adjusted)
5. **Educational Value**: Students see how the same simulation logic works across different graphics paradigms

The implementation can proceed directly from this plan without additional architectural decisions.

---

**Next Steps**: When ready, proceed to implementation using this plan and the `transpiler.prompt.md` prompt as reference.
