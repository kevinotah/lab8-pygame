# Architecture Documentation

## Overview

The project is a single-module Pygame simulation centered in `main.py`. It creates a population of `Square` objects that move continuously, change direction at intervals, avoid larger neighbors, chase smaller neighbors, bounce on screen boundaries, and respawn when lifespan expires.

## Dependency Graph

```mermaid
graph TD
    MAIN["main.py"]
    PYGAME["pygame"]
    RANDOM["random"]
    MATH["math"]
    TYPING["typing (List, Tuple)"]
    SQUARE["Square class"]
    MAINFN["main()"]
    COLORFN["make_random_colour()"]

    MAIN -->|"imports"| PYGAME
    MAIN -->|"imports"| RANDOM
    MAIN -->|"imports"| MATH
    MAIN -->|"imports"| TYPING

    MAIN -->|"defines"| SQUARE
    MAIN -->|"defines"| MAINFN
    MAIN -->|"defines"| COLORFN

    MAIN -->|"calls once at startup"| COLORFN
```

Notes:
- Runtime has no separate package layers; game orchestration and entity logic coexist in one file.
- Global constants configure display, movement, and interaction ranges.

## High-Level Runtime Flow

```mermaid
flowchart TD
    START["Process start"] --> INIT["Initialize pygame"]
    INIT --> SCREEN["Create display and clock"]
    SCREEN --> SPAWN["Create NUM_SQUARES Square instances"]
    SPAWN --> LOOP{"running?"}

    LOOP -->|"yes"| TICK["clock.tick(FPS) -> dt"]
    TICK --> EVENTS["Read event queue"]
    EVENTS --> QUITCHECK{"QUIT event found?"}
    QUITCHECK -->|"yes"| STOP["Set running = False"]
    QUITCHECK -->|"no"| UPDATEALL["For each square: square.update(squares, dt)"]

    UPDATEALL --> CLEAR["Fill screen with RANDOM_COLOUR"]
    CLEAR --> DRAWALL["For each square: draw rectangle"]
    DRAWALL --> LIFE["Build new_squares with lifespan check"]
    LIFE --> HUD["Render square count and FPS text"]
    HUD --> FLIP["pygame.display.flip()"]
    FLIP --> LOOP

    STOP --> EXIT["pygame.quit()"]
```

Notes:
- The frame loop is time-based via $dt=\frac{\text{milliseconds}}{1000}$.
- Expired squares are replaced immediately to keep population size stable.

## Function-Level Call Graph

```mermaid
graph TD
    ENTRY["if __name__ == \"__main__\""] --> MAINFN["main()"]

    MAINFN --> SQCTOR["Square.__init__()"]
    MAINFN --> UPDATE["Square.update(all_squares, dt)"]
    MAINFN --> DRAW["Square.draw(screen)"]
    MAINFN --> NEWSQ["Square.__init__() for respawn"]

    UPDATE --> FLEE["Square.compute_flee_vector(all_squares)"]
    UPDATE --> CHASE["Square.compute_chase_vector(all_squares)"]

    FLEE --> DIST1["math.sqrt()"]
    CHASE --> DIST2["math.sqrt()"]
    UPDATE --> COS["math.cos()"]
    UPDATE --> SIN["math.sin()"]

    SQCTOR --> RANDINT1["random.randint()"]
    SQCTOR --> UNIFORM1["random.uniform()"]
    UPDATE --> UNIFORM2["random.uniform()"]
```

Notes:
- `Square.update()` is the central behavior aggregator.
- Flee/chase computations scan all squares each frame, creating pairwise interaction cost.

## Primary Execution Sequence

```mermaid
sequenceDiagram
    participant B as "Python Runtime"
    participant M as "main()"
    participant C as "pygame.time.Clock"
    participant E as "pygame Event Queue"
    participant S as "Square instance"
    participant D as "Display Surface"

    B->>M: "invoke main()"
    M->>M: "create display, caption, and clock"
    M->>S: "construct initial square population"

    loop "Frame loop while running"
        M->>C: "tick(FPS)"
        C-->>M: "dt seconds"

        M->>E: "pygame.event.get()"
        E-->>M: "event list"

        alt "quit event present"
            M->>M: "set running = False"
        else "continue simulation"
            loop "for each square"
                M->>S: "update(squares, dt)"
                S->>S: "maybe change direction"
                S->>S: "compute flee and chase vectors"
                S->>S: "move and clamp/bounce on borders"
                S->>S: "increment age"
            end

            M->>D: "fill background"
            loop "for each square"
                M->>S: "draw(screen)"
                S->>D: "pygame.draw.rect(...)"
            end

            M->>M: "rebuild list with lifespan replacement"
            M->>D: "draw HUD text (count and FPS)"
            M->>D: "display.flip()"
        end
    end

    M->>M: "pygame.quit()"
```

Notes:
- `age` increments in `Square.update()` and again in the lifespan pass in `main()`, effectively doubling age progression per frame.
- Lifespan values are compared against age measured in seconds (since age uses `dt`).

## Data and State Summary

- Global configuration:
  - `SCREEN_WIDTH = 800`, `SCREEN_HEIGHT = 600`, `FPS = 60`
  - `NUM_SQUARES = 50`, `MAX_SPEED = 120`, `DANGER_DISTANCE = 80`
  - `MIN_SIZE = 10`, `MAX_SIZE = 50`
- Per-square mutable state:
  - spatial: `x`, `y`, `angle`
  - appearance: `size`, `color`
  - motion control: `speed`, `direction_timer`, `direction_change_interval`
  - lifecycle: `lifespan`, `age`

## Assumptions

- Architecture reflects only the currently present runtime in `main.py`.
- No persistence, networking, multithreading, or external services are part of the execution path.
