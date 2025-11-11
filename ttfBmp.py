from PIL import Image, ImageDraw, ImageFont
import os

# Path to your .ttf file
font_path = './Minecraftia-Regular.ttf'

# --- MANUAL WIDTH SETTING ---
# Define the desired width for all output images
MANUAL_WIDTH = 80
IMAGE_HEIGHT = 60 
# ----------------------------

# --- CENTERING OFFSETS ---
# Adjust these values to shift the text:
# Positive X_OFFSET shifts the text RIGHT. Negative shifts it LEFT.
X_OFFSET = 0 
# Positive Y_OFFSET shifts the text DOWN. Negative shifts it UP.
Y_OFFSET = -5  # Example: Shift the character 5 pixels up
# -------------------------

# Set up output directory
output_dir = 'output_bmp_files_inverted'
os.makedirs(output_dir, exist_ok=True)

# Load the font (size 50, you can adjust size as needed)
font = ImageFont.truetype(font_path, size=50)

# Define the characters you want to convert to BMP
characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

# Loop through each character and create a .bmp file
for char in characters:
    # 1. Create a new blank image with the MANUAL_WIDTH and original height
    image = Image.new('RGB', (MANUAL_WIDTH, IMAGE_HEIGHT), color='black')
    
    # Create a drawing object
    draw = ImageDraw.Draw(image)
    
    # Calculate the width and height of the text to be drawn
    bbox = draw.textbbox((0, 0), char, font=font)
    text_width, text_height = bbox[2] - bbox[0], bbox[3] - bbox[1]
    
    # Calculate the position *including* the offset
    # The new position calculation: (Centered Position) + OFFSET
    position_x = ((MANUAL_WIDTH - text_width) // 2) + X_OFFSET
    position_y = ((IMAGE_HEIGHT - text_height) // 2) + Y_OFFSET
    
    # Set the final position tuple
    position = (position_x, position_y)
    
    # 2. Draw the character onto the image with WHITE text
    draw.text(position, char, font=font, fill='white')
    
    # Save the image as a BMP file
    image.save(os.path.join(output_dir, f"{char}.bmp"))

print(f"All letters have been saved as inverted BMP files (Width: {MANUAL_WIDTH}px, Y Offset: {Y_OFFSET}px) in '{output_dir}'")