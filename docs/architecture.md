# Pygame Moving Squares - Architecture Documentation

## Overview

This project is a simple Pygame-based simulation featuring multiple animated squares that move around the screen with intelligent behavior: they flee from larger squares and chase smaller ones. The architecture is minimal and focused, with a single main module orchestrating the game loop and a `Square` class handling individual entity behavior.

---

## 1. Module Dependency Graph

```mermaid
graph TD
    PY["pygame<br/>(library)"]
    MATH["math<br/>(library)"]
    RANDOM["random<br/>(library)"]
    TYPING["typing<br/>(library)"]
    
    MAIN["main.py"]
    
    MAIN -->|imports| PY
    MAIN -->|imports| MATH
    MAIN -->|imports| RANDOM
    MAIN -->|imports| TYPING
    
    MAIN -->|defines| SQUARE["Square<br/>(class)"]
    MAIN -->|defines| MAIN_FUNC["main<br/>(function)"]
    
    style PY fill:#e1f5ff
    style MATH fill:#e1f5ff
    style RANDOM fill:#e1f5ff
    style TYPING fill:#e1f5ff
    style MAIN fill:#fff3e0
    style SQUARE fill:#f3e5f5
    style MAIN_FUNC fill:#f3e5f5
```

**Dependencies:**
- `pygame`: Graphics rendering and event handling
- `math`: Trigonometric calculations for movement vectors
- `random`: Random initialization and variation
- `typing`: Type hints for clarity and IDE support

---

## 2. High-Level System Architecture

```mermaid
graph TD
    INIT["Initialization<br/>(pygame, screen, clock)"]
    SPAWN["Spawn Squares<br/>(50 instances)"]
    LOOP["Game Loop<br/>(runs at 60 FPS)"]
    EVENT["Event Handler<br/>(check quit)"]
    UPDATE["Update Phase<br/>(all squares)"]
    RENDER["Render Phase<br/>(draw & display)"]
    LIFECYCLE["Lifecycle<br/>(respawn expired)"]
    QUIT["Cleanup & Exit"]
    
    INIT --> SPAWN
    SPAWN --> LOOP
    LOOP --> EVENT
    EVENT -->|quit| QUIT
    EVENT -->|continue| UPDATE
    UPDATE --> RENDER
    RENDER --> LIFECYCLE
    LIFECYCLE -->|loop| LOOP
    
    style INIT fill:#c8e6c9
    style SPAWN fill:#c8e6c9
    style LOOP fill:#fff9c4
    style EVENT fill:#ffe0b2
    style UPDATE fill:#bbdefb
    style RENDER fill:#bbdefb
    style LIFECYCLE fill:#f8bbd0
    style QUIT fill:#d1c4e9
```

**Flow:**
1. **Initialization**: Pygame engine and display initialized, clock created
2. **Spawning**: 50 `Square` instances created with random properties
3. **Game Loop**: Continuous cycle at 60 FPS
4. **Event Handling**: Monitor for quit events
5. **Update**: Each square computes new velocity and position
6. **Render**: Clear screen, draw all active squares, update display
7. **Lifecycle**: Replace expired squares with new ones
8. **Cleanup**: Exit pygame on quit

---

## 3. Square Class Architecture

```mermaid
graph TD
    SQUARE_CLASS["Square Class"]
    
    subgraph "Initialization"
        INIT["__init__<br/>- Random size<br/>- Random position<br/>- Random color<br/>- Random angle<br/>- Speed (size-based)<br/>- Lifespan<br/>- Direction timer"]
    end
    
    subgraph "Behavior"
        UPDATE["update<br/>- Direction changes<br/>- Velocity calculation<br/>- Flee behavior<br/>- Chase behavior<br/>- Boundary collisions"]
        FLEE["compute_flee_vector<br/>- Detect larger nearby<br/>- Calculate unit vectors away"]
        CHASE["compute_chase_vector<br/>- Detect smaller nearby<br/>- Calculate unit vectors toward"]
    end
    
    subgraph "Rendering"
        DRAW["draw<br/>- Render as pygame rect"]
    end
    
    SQUARE_CLASS --> INIT
    SQUARE_CLASS --> UPDATE
    SQUARE_CLASS --> FLEE
    SQUARE_CLASS --> CHASE
    SQUARE_CLASS --> DRAW
    
    UPDATE -.uses.-> FLEE
    UPDATE -.uses.-> CHASE
    
    style SQUARE_CLASS fill:#f3e5f5
    style INIT fill:#c8e6c9
    style UPDATE fill:#bbdefb
    style FLEE fill:#fff9c4
    style CHASE fill:#fff9c4
    style DRAW fill:#ffe0b2
```

**Key Attributes:**
- `size`: Random integer (10-50 pixels)
- `x, y`: Screen position (float)
- `color`: RGB tuple (randomized)
- `angle`: Movement direction (radians)
- `speed`: Derived from size (larger = slower)
- `lifespan`: Duration before respawn (30-180 frames)
- `direction_timer`: Accumulator for direction changes

---

## 4. Detailed Call Graph - Square.update()

```mermaid
graph TD
    UPDATE["update<br/>(all_squares, dt)"]
    TIMER["Update direction<br/>timer"]
    CHANGE_DIR["Random direction<br/>change?"]
    ANGLE["Calculate angle<br/>from velocity"]
    CALC_VEL["Calculate base velocity<br/>(vx, vy)"]
    FLEE["compute_flee_vector<br/>returns: dx, dy"]
    APPLY_FLEE["Apply flee vector<br/>(multiply by 200)"]
    CHASE["compute_chase_vector<br/>returns: dx, dy"]
    APPLY_CHASE["Apply chase vector<br/>(multiply by 200)"]
    MOVE["Update position<br/>(x += vx*dt, y += vy*dt)"]
    BOUNCE_X["Bounce off<br/>left/right walls"]
    BOUNCE_Y["Bounce off<br/>top/bottom walls"]
    
    UPDATE --> TIMER
    TIMER --> CHANGE_DIR
    CHANGE_DIR -->|yes| ANGLE
    CHANGE_DIR -->|no| CALC_VEL
    ANGLE --> CALC_VEL
    CALC_VEL --> FLEE
    FLEE --> APPLY_FLEE
    APPLY_FLEE --> CHASE
    CHASE --> APPLY_CHASE
    APPLY_CHASE --> MOVE
    MOVE --> BOUNCE_X
    BOUNCE_X --> BOUNCE_Y
    
    style UPDATE fill:#bbdefb
    style TIMER fill:#fff9c4
    style CHANGE_DIR fill:#fff9c4
    style ANGLE fill:#ffe0b2
    style CALC_VEL fill:#ffe0b2
    style FLEE fill:#f8bbd0
    style APPLY_FLEE fill:#f8bbd0
    style CHASE fill:#f8bbd0
    style APPLY_CHASE fill:#f8bbd0
    style MOVE fill:#c8e6c9
    style BOUNCE_X fill:#c8e6c9
    style BOUNCE_Y fill:#c8e6c9
```

---

## 5. Sequence Diagram - Primary Execution Path

```mermaid
sequenceDiagram
    participant "Main"
    participant "Clock"
    participant "Event Queue"
    participant "Square[i]"
    participant "Screen"
    
    Main->>Main: Initialize pygame & screen
    Main->>Main: Create 50 Square instances
    Main->>Clock: Create clock object
    
    loop Game Loop (60 FPS)
        Main->>Clock: tick(FPS)
        activate Clock
        Clock-->>Main: dt (delta time ms)
        deactivate Clock
        
        Main->>Event Queue: Poll events
        activate Event Queue
        Event Queue-->>Main: QUIT or continue
        deactivate Event Queue
        
        loop For each Square
            Main->>Square: update(all_squares, dt)
            activate Square
                Square->>Square: Update direction timer
                Square->>Square: Compute base velocity
                Square->>Square: compute_flee_vector()
                Square->>Square: Adjust velocity (flee)
                Square->>Square: compute_chase_vector()
                Square->>Square: Adjust velocity (chase)
                Square->>Square: Update position
                Square->>Square: Handle boundary collisions
            deactivate Square
            
            Square-->>Main: Update complete
        end
        
        Main->>Screen: Fill background color
        
        loop For each Square
            alt Square lifespan < certain_variable
                Main->>Square: draw(screen)
                activate Square
                Square->>Screen: pygame.draw.rect()
                deactivate Square
            else Lifespan expired
                Main->>Main: Remove square & append new
            end
        end
        
        Main->>Screen: pygame.display.flip()
        activate Screen
        Screen-->>Main: Frame rendered
        deactivate Screen
    end
    
    Main->>Main: pygame.quit()
```

---

## 6. Behavior Model - Square Interactions

```mermaid
graph TB
    SQUARE_A["Square A<br/>(size=30)"]
    SQUARE_B["Square B<br/>(size=20)"]
    SQUARE_C["Square C<br/>(size=40)"]
    
    SQUARE_A -->|chases| SQUARE_B
    SQUARE_B -->|flees from| SQUARE_A
    SQUARE_B -->|flees from| SQUARE_C
    SQUARE_A -->|flees from| SQUARE_C
    SQUARE_C -->|chases| SQUARE_A
    SQUARE_C -->|chases| SQUARE_B
    
    style SQUARE_A fill:#fff9c4
    style SQUARE_B fill:#bbdefb
    style SQUARE_C fill:#f8bbd0
```

**Interaction Rules:**
- A square **flees** from any square larger than itself within `danger_distance` (50 px)
- A square **chases** any square smaller than itself within `danger_distance` (50 px)
- Flee and chase vectors are normalized and scaled (multiplied by 200 to override base movement)
- Movement is also influenced by random angle changes and boundary collisions

---

## 7. Data Flow - Per-Frame Update

```mermaid
graph LR
    INPUT["Input State<br/>- Position (x, y)<br/>- Angle<br/>- Size<br/>- Lifespan counter"]
    
    DETECT["Detection Phase<br/>- Scan all squares<br/>- Identify larger nearby<br/>- Identify smaller nearby"]
    
    COMPUTE["Computation Phase<br/>- Base velocity (angle)<br/>- Flee vector (from larger)<br/>- Chase vector (to smaller)<br/>- Combined velocity"]
    
    MOVE["Movement Phase<br/>- New position = old + velocity * dt<br/>- Bounce off walls<br/>- Clamp to bounds"]
    
    OUTPUT["Output State<br/>- New position<br/>- Updated timers<br/>- Ready for render"]
    
    INPUT --> DETECT
    DETECT --> COMPUTE
    COMPUTE --> MOVE
    MOVE --> OUTPUT
    
    style INPUT fill:#bbdefb
    style DETECT fill:#fff9c4
    style COMPUTE fill:#ffe0b2
    style MOVE fill:#c8e6c9
    style OUTPUT fill:#f3e5f5
```

---

## 8. Global Constants & Configuration

| Constant | Value | Purpose |
|----------|-------|---------|
| `SCREEN_WIDTH` | 800 | Display width (px) |
| `SCREEN_HEIGHT` | 600 | Display height (px) |
| `FPS` | 60 | Target frame rate |
| `NUM_SQUARES` | 50 | Initial square count |
| `MAX_SPEED` | 100 | Max velocity (px/s) |
| `danger_distance` | 50 | Detection radius (px) |
| `MIN_SIZE` | 10 | Minimum square size (px) |
| `MAX_SIZE` | 50 | Maximum square size (px) |

---

## 9. Performance Characteristics

- **O(n²) Complexity**: Each square's `update()` iterates through all other squares to compute flee/chase vectors.
- **50 Squares**: ~2,500 distance checks per frame at 60 FPS = ~150,000 checks/sec
- **Optimization Opportunity**: Spatial partitioning (quadtree/grid) could reduce collision checks to O(n log n)

---

## 10. Key Design Decisions

1. **Lifespan-based Lifecycle**: Squares expire after 30-180 frames and are replaced. This ensures dynamic behavior without persistent memory leaks.

2. **Size-based Speed**: Larger squares move slower, making them easier to catch and creating natural game balance.

3. **Random Direction Changes**: Squares periodically randomize their direction (every 0.5-1.5 seconds), preventing deterministic patterns.

4. **Vector Scaling**: Flee and chase vectors are multiplied by 200 to override base random movement, making behavior-driven navigation dominant.

5. **Angle-based Movement**: Uses trigonometry (`cos`/`sin`) for smooth movement in any direction.

---

## Technology Stack

- **Language**: Python 3.x
- **Framework**: Pygame 2.6.1
- **Type Hints**: Enabled (Python 3.5+)
- **Target Platform**: Windows/Linux/macOS (cross-platform)

---

## Entry Point

```python
if __name__ == "__main__":
    main()
```

Execution begins in the `main()` function, which initializes the pygame environment, spawns entities, and runs the continuous game loop until user quits.
