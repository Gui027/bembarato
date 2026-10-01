from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter


ROOT = Path(__file__).resolve().parent
ASSETS = ROOT / "assets"
BACKGROUND = ASSETS / "banner-background.png"
PRODUCT = ASSETS / "images" / "hero-mockup_hero-1785028293510.webp"
OUTPUT = ASSETS / "banner-checkout.png"

SCALE = 2
WIDTH, HEIGHT = 1200, 360


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size * SCALE)


canvas = Image.open(BACKGROUND).convert("RGB").resize(
    (WIDTH * SCALE, HEIGHT * SCALE), Image.Resampling.LANCZOS
).convert("RGBA")

# Light veil keeps copy readable while preserving the generated background.
veil = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
veil_draw = ImageDraw.Draw(veil)
veil_draw.rounded_rectangle(
    (36 * SCALE, 24 * SCALE, 735 * SCALE, 336 * SCALE),
    radius=28 * SCALE,
    fill=(255, 255, 255, 198),
)
canvas.alpha_composite(veil)

# Product mockup with a restrained shadow.
product = Image.open(PRODUCT).convert("RGBA")
product.thumbnail((390 * SCALE, 342 * SCALE), Image.Resampling.LANCZOS)
px = 790 * SCALE + (390 * SCALE - product.width) // 2
py = (HEIGHT * SCALE - product.height) // 2
shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
shadow_mask = product.getchannel("A").filter(ImageFilter.GaussianBlur(16 * SCALE))
shadow_layer = Image.new("RGBA", product.size, (24, 56, 76, 88))
shadow_layer.putalpha(shadow_mask.point(lambda value: int(value * 0.35)))
shadow.alpha_composite(shadow_layer, (px + 7 * SCALE, py + 13 * SCALE))
canvas.alpha_composite(shadow)
canvas.alpha_composite(product, (px, py))

draw = ImageDraw.Draw(canvas)
navy = "#2B3F76"
teal = "#24A999"

# Compact original Cuidado Sereno symbol.
icon_x, icon_y = 70 * SCALE, 48 * SCALE
line = 4 * SCALE
draw.arc(
    (icon_x - 14 * SCALE, icon_y - 14 * SCALE, icon_x + 9 * SCALE, icon_y + 20 * SCALE),
    105, 255, fill=teal, width=line,
)
draw.arc(
    (icon_x - 9 * SCALE, icon_y - 14 * SCALE, icon_x + 14 * SCALE, icon_y + 20 * SCALE),
    285, 75, fill=teal, width=line,
)
heart = [
    (icon_x, icon_y + 13 * SCALE),
    (icon_x - 13 * SCALE, icon_y - 1 * SCALE),
    (icon_x - 11 * SCALE, icon_y - 10 * SCALE),
    (icon_x - 2 * SCALE, icon_y - 11 * SCALE),
    (icon_x, icon_y - 6 * SCALE),
    (icon_x + 2 * SCALE, icon_y - 11 * SCALE),
    (icon_x + 11 * SCALE, icon_y - 10 * SCALE),
    (icon_x + 13 * SCALE, icon_y - 1 * SCALE),
]
draw.polygon(heart, fill=navy)

brand_light = font(r"C:\Windows\Fonts\segoeui.ttf", 18)
brand_bold = font(r"C:\Windows\Fonts\segoeuib.ttf", 18)
draw.text((96 * SCALE, 35 * SCALE), "CUIDADO", font=brand_light, fill=navy)
first_width = draw.textlength("CUIDADO", font=brand_light)
draw.text((96 * SCALE + first_width + 7 * SCALE, 35 * SCALE), "SERENO", font=brand_bold, fill=teal)

headline = font(r"C:\Windows\Fonts\segoeuib.ttf", 39)
body = font(r"C:\Windows\Fonts\segoeui.ttf", 19)
pill = font(r"C:\Windows\Fonts\segoeuib.ttf", 13)

draw.multiline_text(
    (68 * SCALE, 92 * SCALE),
    "Cuidar com segurança\nfica muito mais simples.",
    font=headline,
    fill=navy,
    spacing=2 * SCALE,
)
draw.text(
    (70 * SCALE, 218 * SCALE),
    "Um guia prático para uma rotina mais tranquila.",
    font=body,
    fill=(43, 63, 118, 215),
)

pill_box = (70 * SCALE, 274 * SCALE, 238 * SCALE, 312 * SCALE)
draw.rounded_rectangle(pill_box, radius=19 * SCALE, fill=teal)
label = "ACESSO IMEDIATO"
label_box = draw.textbbox((0, 0), label, font=pill)
label_w = label_box[2] - label_box[0]
label_h = label_box[3] - label_box[1]
draw.text(
    (
        (pill_box[0] + pill_box[2] - label_w) / 2,
        (pill_box[1] + pill_box[3] - label_h) / 2 - 2 * SCALE,
    ),
    label,
    font=pill,
    fill="white",
)

canvas = canvas.convert("RGB").resize((WIDTH, HEIGHT), Image.Resampling.LANCZOS)
canvas.save(OUTPUT, format="PNG", optimize=True)
print(f"Banner created: {OUTPUT} ({WIDTH}x{HEIGHT})")
