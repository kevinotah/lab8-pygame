import pygame
import random
import math

# Initialize Pygame
pygame.init()

# Constants
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
FPS = 60
NUM_SQUARES = 10
SQUARE_SIZE = 30
MAX_SPEED = 5

# Colors
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)


class Square:
    """Represents a moving square on the screen."""
    
    def __init__(self):
        # Random starting position
        self.x = random.randint(0, SCREEN_WIDTH - SQUARE_SIZE)
        self.y = random.randint(0, SCREEN_HEIGHT - SQUARE_SIZE)
        
        # Random color
        self.color = (random.randint(50, 255), random.randint(50, 255), random.randint(50, 255))
        
        # Random direction (angle in radians)
        self.angle = random.uniform(0, 2 * math.pi)
        
        # Direction change timer: change direction every ~1 second (60 frames at 60 FPS)
        self.direction_timer = 0
        self.direction_change_interval = random.randint(30, 90)
    
    def update(self):
        """Update position and handle bouncing."""
        # Update direction timer
        self.direction_timer += 1
        if self.direction_timer >= self.direction_change_interval:
            # Pick new random direction
            self.angle = random.uniform(0, 2 * math.pi)
            self.direction_timer = 0
            self.direction_change_interval = random.randint(30, 90)
        
        # Calculate velocity from angle
        vx = MAX_SPEED * math.cos(self.angle)
        vy = MAX_SPEED * math.sin(self.angle)
        
        # Update position
        self.x += vx
        self.y += vy
        
        # Bounce off edges
        if self.x <= 0 or self.x >= SCREEN_WIDTH - SQUARE_SIZE:
            self.angle = math.pi - self.angle  # Reflect horizontally
            self.x = max(0, min(SCREEN_WIDTH - SQUARE_SIZE, self.x))
        
        if self.y <= 0 or self.y >= SCREEN_HEIGHT - SQUARE_SIZE:
            self.angle = -self.angle  # Reflect vertically
            self.y = max(0, min(SCREEN_HEIGHT - SQUARE_SIZE, self.y))
    
    def draw(self, screen):
        """Draw the square on the screen."""
        pygame.draw.rect(screen, self.color, (self.x, self.y, SQUARE_SIZE, SQUARE_SIZE))


def main():
    """Main game loop."""
    screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
    pygame.display.set_caption("Random Moving Squares")
    clock = pygame.time.Clock()
    
    # Create 10 squares
    squares = [Square() for _ in range(NUM_SQUARES)]
    
    running = True
    while running:
        # Handle events
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
        
        # Update squares
        for square in squares:
            square.update()
        
        # Draw
        screen.fill(WHITE)
        for square in squares:
            square.draw(screen)
        pygame.display.flip()
        
        # Frame rate
        clock.tick(FPS)
    
    pygame.quit()


if __name__ == "__main__":
    main()
