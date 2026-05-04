import pygame
import random
import math
from typing import List, Tuple

pygame.init()

SCREEN_WIDTH: int = 800
SCREEN_HEIGHT: int = 600
FPS: int = 60

NUM_SQUARES: int = 50

MIN_SIZE: int = 10
MAX_SIZE: int = 50

MAX_SPEED: float = 120.0
MIN_SPEED: float = 40.0

FLEE_FORCE: float = 200.0
CHASE_FORCE: float = 400.0

DANGER_DISTANCE: float = 50.0
DANGER_DISTANCE_SQ: float = DANGER_DISTANCE ** 2

WHITE: Tuple[int, int, int] = (255, 255, 255)
BLACK: Tuple[int, int, int] = (0, 0, 0)


def make_random_colour() -> Tuple[int, int, int]:
    return (
        random.randint(0, 255),
        random.randint(0, 255),
        random.randint(0, 255),
    )


BACKGROUND_COLOR: Tuple[int, int, int] = make_random_colour()

font: pygame.font.Font = pygame.font.Font(None, 40)


def normalize(dx: float, dy: float) -> Tuple[float, float]:
    length: float = math.sqrt(dx * dx + dy * dy)
    if length == 0:
        return 0.0, 0.0
    return dx / length, dy / length


def clamp_velocity(vx: float, vy: float, max_speed: float) -> Tuple[float, float]:
    speed: float = math.sqrt(vx * vx + vy * vy)
    if speed > max_speed:
        scale: float = max_speed / speed
        return vx * scale, vy * scale
    return vx, vy


class Square:
    def __init__(self) -> None:
        self.size: int = random.randint(MIN_SIZE, MAX_SIZE)

        self.x: float = random.uniform(0, SCREEN_WIDTH - self.size)
        self.y: float = random.uniform(0, SCREEN_HEIGHT - self.size)

        self.vx: float = random.uniform(-1, 1)
        self.vy: float = random.uniform(-1, 1)
        self.vx, self.vy = normalize(self.vx, self.vy)

        initial_speed: float = random.uniform(40.0, MAX_SPEED)
        self.vx *= initial_speed
        self.vy *= initial_speed

        self.color: Tuple[int, int, int] = (
            random.randint(50, 255),
            random.randint(50, 255),
            random.randint(50, 255),
        )

        size_ratio: float = (self.size - MIN_SIZE) / (MAX_SIZE - MIN_SIZE)
        self.max_speed: float = MIN_SPEED + (MAX_SPEED - MIN_SPEED) * (1 - size_ratio)

        self.lifespan: float = random.uniform(30, 180)
        self.age: float = 0.0

    def compute_interaction(self, squares: List["Square"]) -> Tuple[float, float]:
        force_x: float = 0.0
        force_y: float = 0.0

        size_factor: float = self.size / MAX_SIZE

        for other in squares:
            if other is self:
                continue

            dx: float = self.x - other.x
            dy: float = self.y - other.y
            dist_sq: float = dx * dx + dy * dy

            if dist_sq == 0 or dist_sq > DANGER_DISTANCE_SQ:
                continue

            distance: float = math.sqrt(dist_sq)
            dir_x, dir_y = dx / distance, dy / distance

            closeness: float = 1.0 - (distance / DANGER_DISTANCE)

            if other.size > self.size:
                # flee (unchanged)
                force_x += dir_x * FLEE_FORCE * size_factor
                force_y += dir_y * FLEE_FORCE * size_factor
            else:
                # chase (stronger when closer)
                chase_strength: float = CHASE_FORCE * size_factor * closeness
                force_x -= dir_x * chase_strength
                force_y -= dir_y * chase_strength

        return force_x, force_y

    def update(self, squares: List["Square"], dt: float) -> None:
        force_x, force_y = self.compute_interaction(squares)

        self.vx += force_x * dt
        self.vy += force_y * dt

        self.vx, self.vy = clamp_velocity(self.vx, self.vy, self.max_speed)

        self.x += self.vx * dt
        self.y += self.vy * dt

        # bounce
        if self.x <= 0 or self.x >= SCREEN_WIDTH - self.size:
            self.vx *= -1
            self.x = max(0, min(SCREEN_WIDTH - self.size, self.x))

        if self.y <= 0 or self.y >= SCREEN_HEIGHT - self.size:
            self.vy *= -1
            self.y = max(0, min(SCREEN_HEIGHT - self.size, self.y))

        self.age += dt

    def draw(self, screen: pygame.Surface) -> None:
        pygame.draw.rect(
            screen,
            self.color,
            (self.x, self.y, self.size, self.size),
        )


def main() -> None:
    screen: pygame.Surface = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
    pygame.display.set_caption("Smart Squares")
    clock: pygame.time.Clock = pygame.time.Clock()

    squares: List[Square] = [Square() for _ in range(NUM_SQUARES)]

    running: bool = True
    while running:
        dt: float = clock.tick(FPS) / 1000.0

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

        for square in squares:
            square.update(squares, dt)

        new_squares: List[Square] = []
        for square in squares:
            if square.age < square.lifespan:
                new_squares.append(square)
            else:
                new_squares.append(Square())

        squares = new_squares

        screen.fill(BACKGROUND_COLOR)

        for square in squares:
            square.draw(screen)

        fps_text: pygame.Surface = font.render(
            f"{int(clock.get_fps())} FPS", True, BLACK
        )
        count_text: pygame.Surface = font.render(
            f"{len(squares)} squares", True, BLACK
        )

        screen.blit(fps_text, (20, 20))
        screen.blit(count_text, (20, 60))

        pygame.display.flip()

    pygame.quit()


if __name__ == "__main__":
    main()