import pygame
import random
import math

pygame.init()

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
FPS = 60
NUM_SQUARES = 100
MAX_SPEED = 300

danger_distance = 50

font = pygame.font.Font(None, 50)
fps_surface = font.render(f"{FPS} FPS", True, 'Black')

MIN_SIZE = 10
MAX_SIZE = 50

WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
RANDOM_COLOUR = [random.randint(0, 255) for _ in range(3)]


class Square:
    """Represents a moving square on the screen."""

    def __init__(self):
        self.size = random.randint(MIN_SIZE, MAX_SIZE)

        self.x = random.randint(0, SCREEN_WIDTH - self.size)
        self.y = random.randint(0, SCREEN_HEIGHT - self.size)

        self.color = (
            random.randint(50, 255),
            random.randint(50, 255),
            random.randint(50, 255)
        )

        self.angle = random.uniform(0, 2 * math.pi)

        self.direction_timer = 0
        self.direction_change_interval = random.uniform(0.5, 1.5)

        size_ratio = (self.size - MIN_SIZE) / (MAX_SIZE - MIN_SIZE)
        self.speed = MAX_SPEED * (1 - size_ratio)
        
        # life_span = random.randint(30, 180)

    def update(self, all_squares, dt):
        """Update position and handle bouncing."""

        self.direction_timer += dt
        if self.direction_timer >= self.direction_change_interval:
            self.angle = random.uniform(0, 2 * math.pi)
            self.direction_timer = 0
            self.direction_change_interval = random.uniform(0.5, 1.5)

        vx = self.speed * math.cos(self.angle)
        vy = self.speed * math.sin(self.angle)

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

    def compute_flee_vector(self, all_squares):
        """Return a push-away vector from bigger nearby squares."""
        flee_dx = 0
        flee_dy = 0

        for other_square in all_squares:
            if other_square is self:
                continue

            dx = self.x - other_square.x
            dy = self.y - other_square.y
            distance = math.sqrt(dx**2 + dy**2)

            if other_square.size > self.size and distance < danger_distance and distance > 0:
                away_dx = dx / distance
                away_dy = dy / distance
                flee_dx += away_dx
                flee_dy += away_dy

        return flee_dx, flee_dy

    def draw(self, screen):
        """Draw the square on the screen."""
        pygame.draw.rect(screen, self.color, (self.x, self.y, self.size, self.size))

def main():
    """Main game loop."""
    screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
    pygame.display.set_caption("Random Moving Squares")
    clock = pygame.time.Clock()

    squares = [Square() for _ in range(NUM_SQUARES)]

    running = True
    while running:
        dt = clock.tick(FPS) / 1000
        
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