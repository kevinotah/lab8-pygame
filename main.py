import pygame
import random
import math
from typing import List, Tuple

pygame.init()

SCREEN_WIDTH: int = 800
SCREEN_HEIGHT: int = 600
FPS: int = 60
NUM_SQUARES: int = 50
MAX_SPEED: float = 120

DANGER_DISTANCE: float = 80

font: pygame.font.Font = pygame.font.Font(None, 50)
fps_surface: pygame.Surface = font.render(f"{FPS} FPS", True, 'Black')

MIN_SIZE: int = 10
MAX_SIZE: int = 50

WHITE: Tuple[int, int, int] = (255, 255, 255)
BLACK: Tuple[int, int, int] = (0, 0, 0)


def make_random_colour() -> Tuple[int, int, int]:
    return (
        random.randint(0, 255),
        random.randint(0, 255),
        random.randint(0, 255)
    )


RANDOM_COLOUR: Tuple[int, int, int] = make_random_colour()


class Square:
    def __init__(self) -> None:
        self.size: int = random.randint(MIN_SIZE, MAX_SIZE)

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

        size_ratio: float = (self.size - MIN_SIZE) / (MAX_SIZE - MIN_SIZE)
        self.speed: float = MAX_SPEED * (1 - size_ratio)

        self.lifespan: int = random.randint(30, 180)
        self.age: float = 0.0

    def update(self, all_squares: List['Square'], dt: float) -> None:

        self.direction_timer += dt
        if self.direction_timer >= self.direction_change_interval:
            self.angle += random.uniform(-1.0, 1.0) * 0.8 
            self.direction_timer = 0
            self.direction_change_interval = random.uniform(0.8, 2.0)

        vx: float = math.cos(self.angle) * self.speed
        vy: float = math.sin(self.angle) * self.speed

        flee_dx, flee_dy = self.compute_flee_vector(all_squares)
        chase_dx, chase_dy = self.compute_chase_vector(all_squares)

        vx += flee_dx * 120
        vy += flee_dy * 120

        vx -= chase_dx * 120
        vy -= chase_dy * 120

        self.x += vx * dt
        self.y += vy * dt

        if self.x <= 0 or self.x >= SCREEN_WIDTH - self.size:
            self.angle = math.pi - self.angle
            self.x = max(0, min(SCREEN_WIDTH - self.size, self.x))

        if self.y <= 0 or self.y >= SCREEN_HEIGHT - self.size:
            self.angle = -self.angle
            self.y = max(0, min(SCREEN_HEIGHT - self.size, self.y))

        self.age += dt

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

    def draw(self, screen: pygame.Surface) -> None:
        pygame.draw.rect(screen, self.color, (self.x, self.y, self.size, self.size))


def main() -> None:
    screen: pygame.Surface = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
    pygame.display.set_caption("Smooth Squares")
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

        screen.fill(RANDOM_COLOUR)

        for square in squares:
            square.draw(screen)
            
        new_squares: List[Square] = []

        for square in squares:
            square.age += dt

            if square.age < square.lifespan:
                new_squares.append(square)
            else:
                new_squares.append(Square())

        squares = new_squares

        screen.blit(fps_surface, (50, 50))

        pygame.display.flip()

    pygame.quit()


if __name__ == "__main__":
    main()