import pygame
import random
import math
from typing import List, Tuple

pygame.init()

SCREEN_WIDTH: int = 800
SCREEN_HEIGHT: int = 600
FPS: int = 60
NUM_SQUARES: int = 100
MAX_SPEED: float = 300

danger_distance: float = 50

font: pygame.font.Font = pygame.font.Font(None, 50)
fps_surface: pygame.Surface = font.render(f"{FPS} FPS", True, 'Black')

MIN_SIZE: int = 10
MAX_SIZE: int = 50

WHITE: Tuple[int, int, int] = (255, 255, 255)
BLACK: Tuple[int, int, int] = (0, 0, 0)
RANDOM_COLOUR: List[int] = [random.randint(0, 255) for _ in range(3)]


class Square:
    """Represents a moving square on the screen."""

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

        self.direction_timer: float = 0
        self.direction_change_interval: float = random.uniform(0.5, 1.5)

        size_ratio: float = (self.size - MIN_SIZE) / (MAX_SIZE - MIN_SIZE)
        self.speed: float = MAX_SPEED * (1 - size_ratio)

    def update(self, all_squares: List['Square'], dt: float) -> None:
        """Update position and handle bouncing."""

        self.direction_timer += dt
        if self.direction_timer >= self.direction_change_interval:
            self.angle = random.uniform(0, 2 * math.pi)
            self.direction_timer = 0
            self.direction_change_interval = random.uniform(0.5, 1.5)

        vx: float = self.speed * math.cos(self.angle)
        vy: float = self.speed * math.sin(self.angle)

        flee_dx, flee_dy = self.compute_flee_vector(all_squares)
        vx += flee_dx * 200
        vy += flee_dy * 200

        self.x += vx * dt
        self.y += vy * dt

        if self.x <= 0 or self.x >= SCREEN_WIDTH - self.size:
            self.angle = math.pi - self.angle
            self.x = max(0, min(SCREEN_WIDTH - self.size, self.x))

        if self.y <= 0 or self.y >= SCREEN_HEIGHT - self.size:
            self.angle = -self.angle
            self.y = max(0, min(SCREEN_HEIGHT - self.size, self.y))

    def compute_flee_vector(self, all_squares: List['Square']) -> Tuple[float, float]:
        """Return a push-away vector from bigger nearby squares."""
        flee_dx: float = 0
        flee_dy: float = 0

        for other_square in all_squares:
            if other_square is self:
                continue

            dx: float = self.x - other_square.x
            dy: float = self.y - other_square.y
            distance: float = math.sqrt(dx**2 + dy**2)

            if other_square.size > self.size and distance < danger_distance and distance > 0:
                away_dx: float = dx / distance
                away_dy: float = dy / distance
                flee_dx += away_dx
                flee_dy += away_dy

        return flee_dx, flee_dy

    def draw(self, screen: pygame.Surface) -> None:
        """Draw the square on the screen."""
        pygame.draw.rect(screen, self.color, (self.x, self.y, self.size, self.size))

def main() -> None:
    """Main game loop."""
    screen: pygame.Surface = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
    pygame.display.set_caption("Random Moving Squares")
    clock: pygame.time.Clock = pygame.time.Clock()

    squares: List[Square] = [Square() for _ in range(NUM_SQUARES)]

    running: bool = True
    while running:
        dt: float = clock.tick(FPS) / 1000
        
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

        for square in squares:
            square.update(squares, dt)

        screen.fill(RANDOM_COLOUR)
        for square in squares:
            square.draw(screen)

        screen.blit(fps_surface, (50, 50))
        pygame.display.flip()
    
    pygame.quit()


if __name__ == "__main__":
    main()