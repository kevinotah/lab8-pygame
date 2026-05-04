import pygame
import random
import math
from typing import List, Tuple

pygame.init()

# Window and simulation settings.
SCREEN_WIDTH: int = 800
SCREEN_HEIGHT: int = 600
FPS: int = 60
# NUM_SQUARES: int = 50
MAX_SPEED: float = 120

# Squares react to nearby larger/smaller squares only within this radius.
DANGER_DISTANCE: float = 80

font: pygame.font.Font = pygame.font.Font(None, 30)

MIN_SIZE: int = 4
MAX_SIZE: int = 25

WHITE: Tuple[int, int, int] = (255, 255, 255)
BLACK: Tuple[int, int, int] = (0, 0, 0)


def make_random_colour() -> Tuple[int, int, int]:
    # Return one RGB background color and keep it fixed for the whole run.
    return (
        random.randint(0, 255),
        random.randint(0, 255),
        random.randint(0, 255)
    )


# Chosen once at startup so the background does not change every frame.
RANDOM_COLOUR: Tuple[int, int, int] = make_random_colour()


class Square:
    def __init__(self, size: int) -> None:
        # Each square gets a random size, position, color, direction, and lifespan.
        # self.size: int = random.randint(MIN_SIZE, MAX_SIZE)
        self.size = size

        self.x: float = random.randint(0, SCREEN_WIDTH - self.size)
        self.y: float = random.randint(0, SCREEN_HEIGHT - self.size)

        self.color: Tuple[int, int, int] = (
            random.randint(50, 255),
            random.randint(50, 255),
            random.randint(50, 255)
        )

        self.angle: float = random.uniform(0, 2 * math.pi)

        self.direction_timer: float = 0.0
        self.direction_change_interval: float = random.uniform(0.8, 2.0)

        # Smaller squares move faster, larger squares move slower.
        size_ratio: float = (self.size - MIN_SIZE) / (MAX_SIZE - MIN_SIZE)
        self.speed: float = MAX_SPEED * (1 - size_ratio)

        # Age is measured in seconds so squares can expire after a random lifespan.
        self.lifespan: int = random.randint(30, 180)
        self.age: float = 0.0

    def update(self, all_squares: List['Square'], dt: float) -> None:

        # Occasionally change direction a little so movement stays less predictable.
        self.direction_timer += dt
        if self.direction_timer >= self.direction_change_interval:
            self.angle += random.uniform(-1.0, 1.0) * 0.8 
            self.direction_timer = 0
            self.direction_change_interval = random.uniform(0.8, 2.0)

        # Base motion comes from the current angle and the square's speed.
        vx: float = math.cos(self.angle) * self.speed
        vy: float = math.sin(self.angle) * self.speed

        # Flee from larger neighbors and chase smaller neighbors.
        flee_dx, flee_dy = self.compute_flee_vector(all_squares)
        chase_dx, chase_dy = self.compute_chase_vector(all_squares)

        # Behavioral forces are scaled so they visibly affect the base motion.
        vx += flee_dx * 120
        vy += flee_dy * 120

        vx -= chase_dx * 120
        vy -= chase_dy * 120

        # Apply frame-time scaling so movement stays consistent across FPS changes.
        self.x += vx * dt
        self.y += vy * dt

        # Reflect off the left/right walls and clamp the square back on-screen.
        if self.x < 0:
            self.x = SCREEN_WIDTH - self.size
        elif self.x > SCREEN_WIDTH - self.size:
            self.x = 0

        # Reflect off the top/bottom walls and clamp the square back on-screen.
        if self.y < 0:
            self.y = SCREEN_HEIGHT - self.size
        elif self.y > SCREEN_HEIGHT - self.size:
            self.y = 0            
        

    def compute_flee_vector(self, all_squares: List['Square']) -> Tuple[float, float]:
        # Return a vector pointing away from larger nearby squares.
        flee_dx: float = 0.0
        flee_dy: float = 0.0

        for other in all_squares:
            if other is self:
                continue

            # dx/dy point from the other square to this square.
            dx: float = self.x - other.x
            dy: float = self.y - other.y
            dist: float = math.sqrt(dx*dx + dy*dy)

            if other.size > self.size and 0 < dist < DANGER_DISTANCE:
                # Closer threats produce a stronger flee impulse.
                strength: float = (1 - dist / DANGER_DISTANCE)

                flee_dx += (dx / dist) * strength
                flee_dy += (dy / dist) * strength

        return flee_dx, flee_dy

    def compute_chase_vector(self, all_squares: List['Square']) -> Tuple[float, float]:
        # Return a vector pointing toward smaller nearby squares.
        chase_dx: float = 0.0
        chase_dy: float = 0.0

        for other in all_squares:
            if other is self:
                continue

            # dx/dy point from the other square to this square.
            dx: float = self.x - other.x
            dy: float = self.y - other.y
            dist: float = math.sqrt(dx*dx + dy*dy)

            if other.size < self.size and 0 < dist < DANGER_DISTANCE:
                # Closer prey produces a stronger chase impulse.
                strength: float = (1 - dist / DANGER_DISTANCE)

                chase_dx += (dx / dist) * strength
                chase_dy += (dy / dist) * strength

        return chase_dx, chase_dy

    def draw(self, screen: pygame.Surface) -> None:
        # Draw the square as a filled rectangle at its current position.
        pygame.draw.rect(screen, self.color, (self.x, self.y, self.size, self.size))


def main() -> None:
    # Create the display window and a clock for frame timing.
    screen: pygame.Surface = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
    pygame.display.set_caption("Smooth Squares")
    clock: pygame.time.Clock = pygame.time.Clock()

    # Start with different sizes of squares
    squares: List[Square] = []
    for _ in range(5): squares.append(Square(25))
    for _ in range(10): squares.append(Square(10))
    for _ in range(30): squares.append(Square(4))

    running: bool = True
    while running:
        # dt is the elapsed time in seconds since the previous frame.
        dt: float = clock.tick(FPS) / 1000.0

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

        # Update the motion and behavior of every square.
        for square in squares:
            square.update(squares, dt)

        # Paint the background before drawing the squares.
        screen.fill(RANDOM_COLOUR)

        # Draw each square after it has been updated.
        for square in squares:
            square.draw(screen)
            
        # Rebuild the list so expired squares are replaced with new ones.
        new_squares: List[Square] = []

        for square in squares:
            # Age increases over time; once it reaches lifespan, the square is reborn.
            square.age += dt

            if square.age < square.lifespan:
                new_squares.append(square)
            else:
                new_squares.append(Square(square.size))
                # q2 was done together with q1

        squares = new_squares
        
        # Draw simple on-screen debug text for the current square count and FPS.
        number_of_squares: pygame.Surface = font.render(f"{len(squares)} squares", True, 'Black')
        screen.blit(number_of_squares, (50, 20))

        actual_fps: pygame.Surface = font.render(f"FPS: {clock.get_fps():.3f}", True, 'Black')
        screen.blit(actual_fps, (50, 50))

        pygame.display.flip()

    # Cleanly shut down pygame after the loop exits.
    pygame.quit()


if __name__ == "__main__":
    main()