#!/usr/bin/env python3
"""Generate branded blog header images for Bolt21"""

from PIL import Image, ImageDraw, ImageFont
import os
import re
import textwrap

# Image dimensions (blog header)
WIDTH = 1200
HEIGHT = 630

# Colors (Bolt21 brand)
BG_COLOR = (26, 26, 26)  # #1A1A1A
ORANGE = (247, 147, 26)   # #F7931A (Bitcoin orange)
WHITE = (255, 255, 255)
GRAY = (100, 100, 100)

def get_font(size):
    """Try to load a system font"""
    font_paths = [
        '/System/Library/Fonts/Helvetica.ttc',
        '/System/Library/Fonts/SFNSDisplay.ttf',
        '/Library/Fonts/Arial.ttf',
        '/System/Library/Fonts/Supplemental/Arial.ttf',
    ]
    for fp in font_paths:
        if os.path.exists(fp):
            try:
                return ImageFont.truetype(fp, size)
            except:
                continue
    return ImageFont.load_default()

def create_blog_image(title, output_path):
    """Create a branded blog header image"""
    img = Image.new('RGB', (WIDTH, HEIGHT), BG_COLOR)
    draw = ImageDraw.Draw(img)
    
    # Add gradient overlay effect (dark to slightly lighter)
    for y in range(HEIGHT):
        alpha = int(20 * (y / HEIGHT))
        draw.line([(0, y), (WIDTH, y)], fill=(26 + alpha, 26 + alpha, 26 + alpha))
    
    # Draw decorative lightning bolt pattern (subtle)
    for i in range(3):
        x_offset = 100 + i * 400
        bolt_color = (40, 40, 40)
        points = [
            (x_offset, 50),
            (x_offset + 30, 50),
            (x_offset + 15, 100),
            (x_offset + 40, 100),
            (x_offset - 10, 180),
            (x_offset + 10, 130),
            (x_offset - 5, 130),
        ]
        draw.polygon(points, fill=bolt_color)
    
    # Draw orange accent line at top
    draw.rectangle([0, 0, WIDTH, 6], fill=ORANGE)
    
    # Load fonts
    title_font = get_font(52)
    brand_font = get_font(28)
    
    # Wrap title text
    wrapped_title = textwrap.fill(title, width=35)
    lines = wrapped_title.split('\n')
    
    # Calculate title position (centered vertically)
    line_height = 65
    total_height = len(lines) * line_height
    start_y = (HEIGHT - total_height) // 2 - 20
    
    # Draw title lines
    for i, line in enumerate(lines):
        bbox = draw.textbbox((0, 0), line, font=title_font)
        text_width = bbox[2] - bbox[0]
        x = (WIDTH - text_width) // 2
        y = start_y + i * line_height
        draw.text((x, y), line, font=title_font, fill=WHITE)
    
    # Draw Bolt21 branding at bottom
    brand_text = "BOLT21"
    bbox = draw.textbbox((0, 0), brand_text, font=brand_font)
    brand_width = bbox[2] - bbox[0]
    brand_x = (WIDTH - brand_width) // 2
    brand_y = HEIGHT - 80
    
    # Orange underline for brand
    draw.rectangle([brand_x - 20, brand_y + 40, brand_x + brand_width + 20, brand_y + 44], fill=ORANGE)
    draw.text((brand_x, brand_y), brand_text, font=brand_font, fill=ORANGE)
    
    # Save
    img.save(output_path, 'PNG', optimize=True)
    print(f"Created: {output_path}")

def extract_title_from_frontmatter(filepath):
    """Extract title from markdown frontmatter"""
    with open(filepath, 'r') as f:
        content = f.read()
    
    match = re.search(r"title:\s*['\"](.+?)['\"]", content)
    if match:
        return match.group(1)
    return None

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    blog_content_dir = os.path.join(project_root, 'web', 'content', 'blog')
    blog_images_dir = os.path.join(project_root, 'web', 'static', 'images', 'blog')
    
    os.makedirs(blog_images_dir, exist_ok=True)
    
    # Process all blog posts
    count = 0
    for filename in os.listdir(blog_content_dir):
        if filename.endswith('.md') and filename != '_index.md':
            filepath = os.path.join(blog_content_dir, filename)
            title = extract_title_from_frontmatter(filepath)
            
            if title:
                # Generate image filename from markdown filename
                image_name = filename.replace('.md', '.png')
                output_path = os.path.join(blog_images_dir, image_name)
                
                create_blog_image(title, output_path)
                count += 1
    
    print(f"\nGenerated {count} blog images!")

if __name__ == '__main__':
    main()
