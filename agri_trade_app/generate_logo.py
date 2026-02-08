#!/usr/bin/env python3
"""
Generate a unique logo for AgriTrade app
Creates a modern logo combining agricultural and trading elements
"""

try:
    from PIL import Image, ImageDraw, ImageFont
    import math
except ImportError:
    print("Please install Pillow: pip install Pillow")
    exit(1)

def generate_agritrade_logo(size=1024):
    """Generate a unique AgriTrade logo"""
    # Create image with green background
    img = Image.new('RGB', (size, size), color='#4CAF50')
    draw = ImageDraw.Draw(img)
    
    # Calculate center and dimensions
    center_x, center_y = size // 2, size // 2
    radius = size * 0.45
    
    # Draw white circle border
    border_width = int(size * 0.02)
    draw.ellipse(
        [(center_x - radius, center_y - radius), 
         (center_x + radius, center_y + radius)],
        outline='white',
        width=border_width
    )
    
    # Draw inner circle (slightly smaller)
    inner_radius = radius * 0.85
    draw.ellipse(
        [(center_x - inner_radius, center_y - inner_radius),
         (center_x + inner_radius, center_y + inner_radius)],
        fill='white',
        outline=None
    )
    
    # Draw agricultural symbol (wheat/crop stalks) at bottom
    stalk_bottom_y = center_y + size * 0.25
    stalk_height = size * 0.15
    stalk_width = size * 0.015
    
    # Left stalk
    _draw_wheat_stalk(draw, center_x - size * 0.15, stalk_bottom_y, stalk_height, stalk_width)
    # Center stalk (taller)
    _draw_wheat_stalk(draw, center_x, stalk_bottom_y, stalk_height * 1.2, stalk_width)
    # Right stalk
    _draw_wheat_stalk(draw, center_x + size * 0.15, stalk_bottom_y, stalk_height, stalk_width)
    
    # Draw trading/connection symbol (circular arrows) at top
    arrow_radius = size * 0.12
    arrow_center_y = center_y - size * 0.25
    
    # Draw circular trading arrows
    _draw_trading_arrows(draw, center_x, arrow_center_y, arrow_radius, size)
    
    # Draw "AT" monogram in center (AgriTrade initials)
    try:
        # Try to use a bold font
        font_size = int(size * 0.25)
        font = ImageFont.truetype("arial.ttf", font_size)
    except:
        try:
            font = ImageFont.truetype("arialbd.ttf", font_size)
        except:
            # Fallback to default font
            font = ImageFont.load_default()
    
    text = "AT"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    text_x = center_x - text_width // 2
    text_y = center_y - text_height // 2 - size * 0.05
    
    # Draw text with shadow effect
    draw.text((text_x + 2, text_y + 2), text, fill='#2E7D32', font=font)
    draw.text((text_x, text_y), text, fill='#4CAF50', font=font)
    
    return img

def _draw_wheat_stalk(draw, x, bottom_y, height, width):
    """Draw a wheat stalk"""
    # Main stalk
    top_y = bottom_y - height
    draw.rectangle(
        [(x - width, top_y), (x + width, bottom_y)],
        fill='#2E7D32'
    )
    
    # Wheat grains on top
    grain_size = width * 1.5
    for i in range(3):
        grain_y = top_y + (i * height * 0.15)
        grain_x = x + (width * 2 if i % 2 == 0 else -width * 2)
        draw.ellipse(
            [(grain_x - grain_size, grain_y - grain_size),
             (grain_x + grain_size, grain_y + grain_size)],
            fill='#2E7D32'
        )

def _draw_trading_arrows(draw, center_x, center_y, radius, size):
    """Draw circular trading arrows symbol"""
    arrow_width = int(size * 0.015)
    
    # Draw circle
    draw.ellipse(
        [(center_x - radius, center_y - radius),
         (center_x + radius, center_y + radius)],
        outline='#2E7D32',
        width=arrow_width
    )
    
    # Draw 4 arrows pointing in circular direction
    num_arrows = 4
    for i in range(num_arrows):
        angle = (i * 360 / num_arrows - 45) * math.pi / 180
        start_radius = radius * 0.7
        end_radius = radius * 0.9
        
        # Arrow line
        start_x = center_x + start_radius * math.cos(angle)
        start_y = center_y + start_radius * math.sin(angle)
        end_x = center_x + end_radius * math.cos(angle)
        end_y = center_y + end_radius * math.sin(angle)
        
        draw.line([(start_x, start_y), (end_x, end_y)], 
                 fill='#2E7D32', width=arrow_width)
        
        # Arrow head
        arrow_head_size = size * 0.025
        head_angle1 = angle + math.pi * 0.75
        head_angle2 = angle + math.pi * 1.25
        
        head1_x = end_x + arrow_head_size * math.cos(head_angle1)
        head1_y = end_y + arrow_head_size * math.sin(head_angle1)
        head2_x = end_x + arrow_head_size * math.cos(head_angle2)
        head2_y = end_y + arrow_head_size * math.sin(head_angle2)
        
        draw.line([(end_x, end_y), (head1_x, head1_y)], 
                 fill='#2E7D32', width=arrow_width)
        draw.line([(end_x, end_y), (head2_x, head2_y)], 
                 fill='#2E7D32', width=arrow_width)

if __name__ == '__main__':
    print("Generating AgriTrade logo...")
    logo = generate_agritrade_logo(1024)
    
    # Save to assets/icon directory
    import os
    output_dir = 'assets/icon'
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, 'app_icon.png')
    
    logo.save(output_path, 'PNG')
    print(f"Logo generated successfully at: {output_path}")
    print(f"Size: {logo.size[0]}x{logo.size[1]} pixels")
    print("\nNext steps:")
    print("1. Review the generated logo")
    print("2. Run: flutter pub get")
    print("3. Run: flutter pub run flutter_launcher_icons")
    print("4. Run: flutter clean && flutter run")

