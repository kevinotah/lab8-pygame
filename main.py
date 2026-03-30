import pygame
import random
import math

# Initialize Pygame
pygame.init()

# Constants
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
FPS = 60
NUM_SQUARES = 100
MAX_SPEED = 5

# Size range (NEW)
MIN_SIZE = 10
MAX_SIZE = 50

# Colors
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
RANDOM_COLOUR = [random.randint(0, 255) for _ in range(3)]


class Square:
    """Represents a moving square on the screen."""
    
    def __init__(self):
        # Random size (NEW)
        self.size = random.randint(MIN_SIZE, MAX_SIZE)

        # Random starting position (UPDATED to use self.size)
        self.x = random.randint(0, SCREEN_WIDTH - self.size)
        self.y = random.randint(0, SCREEN_HEIGHT - self.size)
        
        # Random color
        self.color = (
            random.randint(50, 255),
            random.randint(50, 255),
            random.randint(50, 255)
        )
        
        # Random direction
        self.angle = random.uniform(0, 2 * math.pi)
        
        # Direction change timer
        self.direction_timer = 0
        self.direction_change_interval = random.randint(30, 90)

        size_ratio = (self.size - MIN_SIZE) / (MAX_SIZE - MIN_SIZE)

        self.speed = MAX_SPEED * (1 - size_ratio)

    def update(self):
        """Update position and handle bouncing."""
        
        # Direction change logic (UNCHANGED)
        self.direction_timer += 1
        if self.direction_timer >= self.direction_change_interval:
            self.angle = random.uniform(0, 2 * math.pi)
            self.direction_timer = 0
            self.direction_change_interval = random.randint(30, 90)
        
        vx = self.speed * math.cos(self.angle)
        vy = self.speed * math.sin(self.angle)
        
        # Update position
        self.x += vx
        self.y += vy
        
        if self.x <= 0 or self.x >= SCREEN_WIDTH - self.size:
            self.angle = math.pi - self.angle
            self.x = max(0, min(SCREEN_WIDTH - self.size, self.x))
        
        if self.y <= 0 or self.y >= SCREEN_HEIGHT - self.size:
            self.angle = -self.angle
            self.y = max(0, min(SCREEN_HEIGHT - self.size, self.y))

    def draw(self, screen):
        """Draw the square on the screen."""
        pygame.draw.rect(screen, self.color, (self.x, self.y, self.size, self.size))


def main():
    """Main game loop."""
    screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
    pygame.display.set_caption("Random Moving Squares")
    clock = pygame.time.Clock()
    
    # Create squares
    squares = [Square() for _ in range(NUM_SQUARES)]
    
    running = True
    while running:
        # Events
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
        
        # Update
        for square in squares:
            square.update()
        
        # Draw
        screen.fill(RANDOM_COLOUR)
        for square in squares:
            square.draw(screen)
        pygame.display.flip()
        
        clock.tick(FPS)
    
    pygame.quit()


if __name__ == "__main__":
    main()