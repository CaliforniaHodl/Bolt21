#!/usr/bin/env python3
"""Generate SEO share image (Open Graph / Twitter Card) for Bolt21"""

from PIL import Image, ImageDraw, ImageFont
import os

# Image dimensions (OG standard)
WIDTH = 1200
HEIGHT = 630

# Colors (Bolt21 brand)
BG_COLOR = (26, 26, 26)  # #1A1A1A
ORANGE = (255, 140, 0)    # #FF8C00
WHITE = (255, 255, 255)
GRAY = (153, 153, 153)    # #999999

def create_share_image():
    # Create base image
    img = Image.new('RGB', (WIDTH, HEIGHT), BG_COLOR)
    draw = ImageDraw.Draw(img)

    # Try to load logo
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    logo_path = os.path.join(project_root, 'assets', 'images', 'icon.png')

    logo_size = 200
    logo_y = 120

    if os.path.exists(logo_path):
        logo = Image.open(logo_path)
        logo = logo.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
        # Center logo horizontally
        logo_x = (WIDTH - logo_size) // 2
        # Handle transparency
        if logo.mode == 'RGBA':
            img.paste(logo, (logo_x, logo_y), logo)
        else:
            img.paste(logo, (logo_x, logo_y))
    else:
        # Draw placeholder lightning bolt
        bolt_x = WIDTH // 2
        bolt_points = [
            (bolt_x - 30, logo_y),
            (bolt_x + 50, logo_y),
            (bolt_x + 10, logo_y + 80),
            (bolt_x + 60, logo_y + 80),
            (bolt_x - 40, logo_y + 200),
            (bolt_x, logo_y + 120),
            (bolt_x - 50, logo_y + 120),
        ]
        draw.polygon(bolt_points, fill=ORANGE)

    # Load fonts (try system fonts, fall back to default)
    try:
        # Try common system fonts
        font_paths = [
            '/System/Library/Fonts/Helvetica.ttc',
            '/System/Library/Fonts/SFNSDisplay.ttf',
            '/Library/Fonts/Arial.ttf',
        ]
        title_font = None
        for fp in font_paths:
            if os.path.exists(fp):
                title_font = ImageFont.truetype(fp, 72)
                tagline_font = ImageFont.truetype(fp, 36)
                url_font = ImageFont.truetype(fp, 28)
                break
        if title_font is None:
            raise Exception("No fonts found")
    except:
        title_font = ImageFont.load_default()
        tagline_font = title_font
        url_font = title_font

    # Draw "Bolt21" title
    title = "Bolt21"
    title_bbox = draw.textbbox((0, 0), title, font=title_font)
    title_width = title_bbox[2] - title_bbox[0]
    title_x = (WIDTH - title_width) // 2
    title_y = logo_y + logo_size + 40
    draw.text((title_x, title_y), title, font=title_font, fill=WHITE)

    # Draw tagline
    tagline = "Lightning. Simplified."
    tagline_bbox = draw.textbbox((0, 0), tagline, font=tagline_font)
    tagline_width = tagline_bbox[2] - tagline_bbox[0]
    tagline_x = (WIDTH - tagline_width) // 2
    tagline_y = title_y + 80
    draw.text((tagline_x, tagline_y), tagline, font=tagline_font, fill=ORANGE)

    # Draw URL at bottom
    url = "bolt21.io"
    url_bbox = draw.textbbox((0, 0), url, font=url_font)
    url_width = url_bbox[2] - url_bbox[0]
    url_x = (WIDTH - url_width) // 2
    url_y = HEIGHT - 60
    draw.text((url_x, url_y), url, font=url_font, fill=GRAY)

    # Add subtle orange accent line
    line_y = tagline_y + 60
    line_width = 100
    line_x = (WIDTH - line_width) // 2
    draw.rectangle([line_x, line_y, line_x + line_width, line_y + 3], fill=ORANGE)

    # Save to web static folder
    output_dir = os.path.join(project_root, 'web', 'static', 'images', 'brand')
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, 'share.png')
    img.save(output_path, 'PNG', optimize=True)
    print(f"Created: {output_path}")

    # Also save to public folder if it exists
    public_dir = os.path.join(project_root, 'web', 'public', 'images', 'brand')
    os.makedirs(public_dir, exist_ok=True)
    public_path = os.path.join(public_dir, 'share.png')
    img.save(public_path, 'PNG', optimize=True)
    print(f"Created: {public_path}")

    return output_path

if __name__ == '__main__':
    create_share_image()
    print("\nShare image generated! (1200x630)")
    print("Update your site's og:image URLs to use https://bolt21.io/images/brand/share.png")
