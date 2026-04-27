# Light Refactoring Plan: Pygame Moving Squares

## Overview

**Current Code Purpose:**
This pygame application simulates 50 animated squares with predator-prey behavior. Squares flee from larger neighbors and chase smaller ones using vector-based physics, with a time-based game loop running at 60 FPS.

**Current State Assessment:**
The code is functionally correct and well-structured with:
- ✓ Comprehensive type hints throughout
- ✓ Clear class separation (Square + main function)
- ✓ Proper physics calculations (time-based movement)
- ✓ Organized constants and color definitions

**Areas for Improvement:**
- ❌ `certain_variable` is cryptically named; should reflect its purpose (tracks square age/lifetime)
- ❌ Docstring for `compute_chase_vector()` is copy-pasted incorrectly (says "bigger" when it means "smaller")
- ❌ Magic number `200` appears twice without explanation; should be extracted to a named constant
- ❌ Variable names like `away_dx` and `away_dy` suggest "away" motion, but they're actually normalized direction vectors
- ❌ Velocity combination logic could be clearer with intermediate variables
- ❌ Comment explaining why `max(0, min(...))` clamping is used would help beginners
- ❌ No explanation of the 200x scaling factor's purpose

---

## Refactoring Goals

1. **Improve Naming:** Replace cryptic names with self-documenting ones
2. **Extract Constants:** Move magic numbers to named top-level constants
3. **Fix Documentation:** Correct misleading docstrings and add physics explanations
4. **Clarify Intent:** Use intermediate variables to make complex calculations readable
5. **Beginner Understanding:** Add inline comments explaining the "why" behind design choices

---

## Step-by-Step Refactoring Plan

### Step 1: Rename `certain_variable` to `age`
**What to do:**
- Find all occurrences of `certain_variable` in the Square class
- Replace with `age` (more semantically meaningful)
- Update the logic comment to explain it tracks elapsed time

**Why this is beneficial:**
- `age` immediately tells readers this variable accumulates over time
- Matches domain language: "squares are born and live for a lifespan"
- Easier to debug when variable names match their intent
- Beginner concept: self-documenting code reduces cognitive load

**Instructions for inline comments:**
- Add a comment in `__init__`: `# age: Tracks elapsed time in seconds; used for lifespan expiration`
- Add a comment in `main()` where age is incremented: `# Accumulate age; when >= lifespan, square is recycled`

**Before:**
```python
self.certain_variable: float = 0
# ...
square.certain_variable += dt
if square.certain_variable < square.lifespan:
```

**After:**
```python
self.age: float = 0  # Tracks time elapsed since birth; used for lifespan expiration
# ...
square.age += dt  # Increment age by delta time
if square.age < square.lifespan:  # Check if still within lifespan window
```

---

### Step 2: Fix `compute_chase_vector()` Docstring
**What to do:**
- Update the docstring from `"Return a push-away vector from bigger nearby squares."` to `"Return a move-toward vector for smaller nearby squares."`
- This corrects the copy-paste error from `compute_flee_vector()`

**Why this is beneficial:**
- Prevents confusion: docstrings should match actual behavior
- Chase logic targets *smaller* squares, not bigger ones
- Beginners rely on docstrings; incorrect ones teach wrong patterns

**Instructions for inline comments:**
- Add a comment clarifying the chase vs. flee distinction:
```python
def compute_chase_vector(self, all_squares: List['Square']) -> Tuple[float, float]:
    """Return a move-toward vector for smaller nearby squares (prey).
    
    This implements the "predator" instinct: chase and move toward squares
    smaller than self within danger_distance.
    """
```

---

### Step 3: Extract Magic Number Constants
**What to do:**
- Add two new module-level constants after MAX_SPEED:
  ```python
  FLEE_SCALE: float = 200  # Multiplier for flee vector strength
  CHASE_SCALE: float = 200  # Multiplier for chase vector strength
  ```
- Replace both hardcoded `200` values in `update()` with these constants

**Why this is beneficial:**
- Magic numbers are unexplained; named constants clarify intent
- Makes it easy to tune behavior later (one place to change)
- Encourages experimentation: students can see immediate effect of adjusting the multiplier
- Beginner concept: constants vs. literals—why programmers avoid magic numbers

**Instructions for inline comments:**
- Add comment explaining the scale factor:
```python
FLEE_SCALE: float = 200  # Scales flee vector to dominate random movement
CHASE_SCALE: float = 200  # Scales chase vector to dominate random movement
```
- Add comment in update() where applied:
```python
vx += flee_dx * FLEE_SCALE  # Apply scaled flee behavior
vy += flee_dy * FLEE_SCALE
vx -= chase_dx * CHASE_SCALE  # Apply scaled chase behavior
vy -= chase_dy * CHASE_SCALE
```

**Before:**
```python
vx += flee_dx * 200
vy += flee_dy * 200
vx -= chase_dx * 200
vy -= chase_dy * 200
```

**After:**
```python
vx += flee_dx * FLEE_SCALE  # Flee behavior scales up to dominate random movement
vy += flee_dy * FLEE_SCALE
vx -= chase_dx * CHASE_SCALE  # Chase behavior scales up to dominate random movement
vy -= chase_dy * CHASE_SCALE
```

---

### Step 4: Rename Vector Components for Clarity
**What to do:**
- In `compute_flee_vector()` and `compute_chase_vector()`, rename `away_dx` → `direction_x` and `away_dy` → `direction_y`
- This clarifies that these are normalized direction vectors, not "away" vectors specifically

**Why this is beneficial:**
- Naming accuracy: "away_dx" suggests magnitude/direction away; "direction_x" is generic and correct
- Mirrors the variable names `flee_dx` and `chase_dx` at the function level
- Reduces mental confusion: beginners won't misinterpret the purpose

**Instructions for inline comments:**
- Add comment in the loop:
```python
# Normalize the displacement to a unit direction vector
direction_x: float = dx / distance
direction_y: float = dy / distance
```

**Before:**
```python
away_dx: float = dx / distance
away_dy: float = dy / distance
flee_dx += away_dx
```

**After:**
```python
# Normalize displacement to unit direction vector (magnitude = 1)
direction_x: float = dx / distance
direction_y: float = dy / distance
flee_dx += direction_x
flee_dy += direction_y
```

---

### Step 5: Extract and Clarify Velocity Combination Logic
**What to do:**
- In `update()`, break the velocity combination into clearer steps:
  1. Calculate base velocity from angle
  2. Calculate behavioral modifiers (flee + chase)
  3. Apply scaling
  4. Combine all components

**Why this is beneficial:**
- Complex velocity logic becomes step-by-step and readable
- Intermediate variables self-document each calculation phase
- Beginners can trace execution by reading variable names instead of formulas

**Instructions for inline comments:**
- Add a section comment explaining the physics pipeline:
```python
# ========== VELOCITY CALCULATION ==========
# Phase 1: Base velocity from random angle
# Phase 2: Add behavioral vectors (flee from predators, chase prey)
# Phase 3: Integrate with delta time for frame-rate independence
```

**Before:**
```python
vx: float = self.speed * math.cos(self.angle)
vy: float = self.speed * math.sin(self.angle)

flee_dx, flee_dy = self.compute_flee_vector(all_squares)
vx += flee_dx * 200
vy += flee_dy * 200

chase_dx, chase_dy = self.compute_chase_vector(all_squares)
vx -= chase_dx * 200
vy -= chase_dy * 200

self.x += vx * dt
self.y += vy * dt
```

**After:**
```python
# ========== VELOCITY CALCULATION ==========
# Calculate base velocity from current angle and speed
base_vx: float = self.speed * math.cos(self.angle)
base_vy: float = self.speed * math.sin(self.angle)

# Apply flee behavior: move away from larger nearby squares
flee_dx, flee_dy = self.compute_flee_vector(all_squares)
flee_vx: float = flee_dx * FLEE_SCALE  # Scale to dominate random movement
flee_vy: float = flee_dy * FLEE_SCALE

# Apply chase behavior: move toward smaller nearby squares
chase_dx, chase_dy = self.compute_chase_vector(all_squares)
chase_vx: float = chase_dx * CHASE_SCALE
chase_vy: float = chase_dy * CHASE_SCALE

# Combine all velocity components
vx: float = base_vx + flee_vx - chase_vx
vy: float = base_vy + flee_vy - chase_vy

# Integrate position with delta time (time-based movement)
self.x += vx * dt
self.y += vy * dt
```

---

### Step 6: Clarify Boundary Collision and Clamping
**What to do:**
- Add an inline comment explaining the `max(0, min(...))` pattern
- Explain why clamping is needed (prevents off-screen rendering)

**Why this is beneficial:**
- This pattern is non-obvious to beginners; a comment saves debugging time
- Explains the difference between collision physics (angle reflection) and boundary enforcement (clamping)
- Beginner concept: defensive programming—ensuring graphics stay within bounds

**Instructions for inline comments:**
```python
# Bounce off wall by reflecting angle
if self.x <= 0 or self.x >= SCREEN_WIDTH - self.size:
    self.angle = math.pi - self.angle
    # Clamp position to ensure square stays on-screen after reflection
    # max(0, ...) prevents x from going negative; min(...) prevents overflow
    self.x = max(0, min(SCREEN_WIDTH - self.size, self.x))
```

**Before:**
```python
if self.x <= 0 or self.x >= SCREEN_WIDTH - self.size:
    self.angle = math.pi - self.angle
    self.x = max(0, min(SCREEN_WIDTH - self.size, self.x))
```

**After:**
```python
# Bounce off left/right walls by reflecting angle horizontally
if self.x <= 0 or self.x >= SCREEN_WIDTH - self.size:
    self.angle = math.pi - self.angle  # Mirror angle across vertical axis
    # Clamp position to valid range: [0, SCREEN_WIDTH - size]
    # Ensures square is always fully visible on screen
    self.x = max(0, min(SCREEN_WIDTH - self.size, self.x))
```

---

### Step 7: Document the Screen Color Logic
**What to do:**
- Add a comment explaining why the background color is constant throughout the game
- Clarify that `RANDOM_COLOUR` is generated once at module load, not per-frame

**Why this is beneficial:**
- Prevents confusion: why is a "random color" used if it never changes?
- Explains design intent: consistent background vs. per-frame randomization
- Beginners learn module-level vs. function-level code execution

**Instructions for inline comments:**
```python
# RANDOM_COLOUR is computed once at module load, providing a static background color
# If you want a different color each frame, move this call inside main()
RANDOM_COLOUR: Tuple[int, int, int] = make_random_colour()
```

And in main():
```python
screen.fill(RANDOM_COLOUR)  # Fill screen with static background color (set at module load)
```

---

## Final Output Requirements (Mandatory)

When this plan is executed, the output must:

1. **Contain only the refactored code** (no separate documentation files)
2. **Include inline comments explaining:**
   - What changed (`# Renamed: certain_variable → age`)
   - Why it changed (`# age is more semantically clear`)
   - Relevant programming concepts (`# Accumulates time; used for lifecycle management`)
3. **Keep all explanations concise and beginner-friendly** (2-3 lines per comment)
4. **Preserve all functionality** (no behavioral changes, only clarity improvements)
5. **Maintain consistent formatting** (indentation, spacing, PEP 8 compliance)

### Execution Notes:
- Run the refactored code to verify it matches the original behavior
- Squares should still flee/chase, bounce, and respawn identically
- Comments should enhance understanding without cluttering the code

---

## Key Concepts for Students

### 1. **Self-Documenting Code**
Variables named `age` instead of `certain_variable` reduce the need for external comments. Good naming is the first layer of documentation.

### 2. **Constants vs. Magic Numbers**
A magic number like `200` has no context. Extract it to `FLEE_SCALE = 200` with a comment explaining why 200 is chosen—students can then experiment by changing it.

### 3. **Docstring Accuracy**
Docstrings are promises about what code does. A wrong docstring teaches incorrect patterns and ruins trust. Always keep them synchronized with implementation.

### 4. **Intermediate Variables for Readability**
Complex formulas like `vx += flee_dx * 200` are hard to understand at a glance. Breaking it into `flee_vx = flee_dx * FLEE_SCALE` then `vx += flee_vx` makes intent clear.

### 5. **Defensive Programming**
The `max(0, min(...))` clamping is defensive: even if physics calculations send a square slightly off-screen, clamping ensures graphics stay valid. Comments on defensive code prevent "why is this here?" confusion.

### 6. **Module-Level vs. Function-Level Execution**
`RANDOM_COLOUR = make_random_colour()` runs once; `certain_variable += dt` runs 60 times per second. Students often confuse these scopes; comments clarify timing.

---

## Safety Notes

### Testing After Each Step:
1. After renaming `certain_variable` → `age`: Run the game, confirm squares still respawn after 30-180 frames
2. After extracting constants: Change `FLEE_SCALE` to 100 and 500; verify flee behavior intensifies/weakens proportionally
3. After renaming vectors: Run the game; behavior should be identical (only names change)
4. After restructuring velocity logic: Confirm flight paths match the original (use visual inspection or record paths)

### Behavioral Preservation:
- Do NOT change any logic (no `if` conditions, operators, or calculations)
- Do NOT modify physics parameters (speed, danger_distance, size ranges)
- Do NOT reorder statements (operation order matters for physics)
- Only reorder for clarity if it doesn't affect execution (e.g., variable declarations)

### Common Pitfalls:
- ❌ Changing `vx -= chase_dx` to `vx += chase_dx` (reverses chase direction—test carefully)
- ❌ Forgetting to update all references to renamed variables
- ❌ Changing the value of extracted constants (verify `FLEE_SCALE = 200` is not changed)
- ❌ Introducing new intermediate variables that shadow outer scope (use `_local` naming if needed)

### Verification:
After completing all steps:
```bash
python main.py
# Watch for 30+ seconds. Confirm:
# - 50 squares spawn and animate
# - Smaller squares flee from larger ones
# - Larger squares pursue smaller ones
# - Squares respawn after their lifespan expires
# - No errors or crashes
```

---

## Summary

This refactoring improves **code clarity** without changing **behavior**. By renaming variables, extracting constants, and adding explanatory comments, the code becomes easier for first-year CS students to:
- Understand intent at a glance
- Trace execution step-by-step
- Modify and experiment safely
- Learn best practices (naming, constants, documentation)

All changes are **optional but recommended** for a learning project.
