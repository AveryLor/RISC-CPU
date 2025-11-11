from PIL import Image, ImageDraw, ImageFont
import os

# Path to your .ttf file
font_path = './Minecraftia-Regular.ttf'

# Set up output directory
output_dir = 'output_bmp_files'
os.makedirs(output_dir, exist_ok=True)

# Load the font (size 50, you can adjust size as needed)
font = ImageFont.truetype(font_path, size=50)

# Define the characters you want to convert to BMP
# This example includes all uppercase and lowercase letters, and digits.
characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

# Loop through each character and create a .bmp file
for char in characters:
    # Create a new blank image (white background)
    image = Image.new('RGB', (60, 60), color='white')  # Adjust size as needed
    
    # Create a drawing object
    draw = ImageDraw.Draw(image)
    
    # Calculate the width and height of the text to be drawn
    width, height = draw.textsize(char, font=font)
    
    # Calculate the position to center the text
    position = ((60 - width) // 2, (60 - height) // 2)
    
    # Draw the character onto the image
    draw.text(position, char, font=font, fill='black')  # Black text
    
    # Save the image as a BMP file
    image.save(os.path.join(output_dir, f"{char}.bmp"))

print(f"All letters have been saved as BMP files in '{output_dir}'")
