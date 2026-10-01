from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parent
ASSETS = ROOT / "assets"
PRODUCT_PATH = ASSETS / "images" / "hero-mockup_hero-1785028293510.webp"
DESKTOP_BG = ASSETS / "banner-v2-desktop-background.png"
MOBILE_BG = ASSETS / "banner-v2-mobile-background.png"
DESKTOP_OUT = ASSETS / "banner-checkout-desktop.png"
MOBILE_OUT = ASSETS / "banner-checkout-mobile.png"

NAVY = "#2B3F76"
DEEP_NAVY = "#132B4C"
TEAL = "#24A999"
MUTED = "#526181"
WHITE = "#FFFFFF"
SCALE = 2


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(fr"C:\Windows\Fonts\{name}", size * SCALE)


def cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    return ImageOps.fit(image.convert("RGB"), size, method=Image.Resampling.LANCZOS).convert("RGBA")


def draw_brand(draw: ImageDraw.ImageDraw, x: int, y: int, size: int = 18) -> None:
    x *= SCALE
    y *= SCALE
    line = max(3, int(size * 0.22)) * SCALE
    radius = size * SCALE
    draw.arc((x - radius, y - radius, x + int(radius * .55), y + int(radius * 1.15)), 108, 255, fill=TEAL, width=line)
    draw.arc((x - int(radius * .55), y - radius, x + radius, y + int(radius * 1.15)), 285, 72, fill=TEAL, width=line)
    heart = [
        (x, y + int(radius * .72)),
        (x - int(radius * .72), y - int(radius * .05)),
        (x - int(radius * .62), y - int(radius * .58)),
        (x - int(radius * .12), y - int(radius * .64)),
        (x, y - int(radius * .34)),
        (x + int(radius * .12), y - int(radius * .64)),
        (x + int(radius * .62), y - int(radius * .58)),
        (x + int(radius * .72), y - int(radius * .05)),
    ]
    draw.polygon(heart, fill=NAVY)
    light = font("segoeui.ttf", size)
    bold = font("segoeuib.ttf", size)
    tx = x + int(radius * 1.45)
    ty = y - int(radius * .78)
    draw.text((tx, ty), "CUIDADO", font=light, fill=NAVY)
    w = draw.textlength("CUIDADO", font=light)
    draw.text((tx + w + 6 * SCALE, ty), "SERENO", font=bold, fill=TEAL)


def add_product(canvas: Image.Image, box: tuple[int, int], shadow_strength: int = 85) -> None:
    max_w, max_h = box
    product = Image.open(PRODUCT_PATH).convert("RGBA")
    product.thumbnail((max_w * SCALE, max_h * SCALE), Image.Resampling.LANCZOS)
    px = canvas.width - product.width - 22 * SCALE
    py = (canvas.height - product.height) // 2
    mask = product.getchannel("A").filter(ImageFilter.GaussianBlur(13 * SCALE))
    shadow = Image.new("RGBA", product.size, (6, 20, 37, shadow_strength))
    shadow.putalpha(mask.point(lambda value: int(value * .38)))
    canvas.alpha_composite(shadow, (px + 8 * SCALE, py + 12 * SCALE))
    canvas.alpha_composite(product, (px, py))


def draw_bullet(draw: ImageDraw.ImageDraw, x: int, y: int, text: str, text_font: ImageFont.FreeTypeFont, color: str = NAVY) -> None:
    x *= SCALE
    y *= SCALE
    r = 9 * SCALE
    draw.ellipse((x, y, x + 2 * r, y + 2 * r), fill=TEAL)
    draw.line(
        (
            x + 5 * SCALE,
            y + 9 * SCALE,
            x + 8 * SCALE,
            y + 12 * SCALE,
            x + 13 * SCALE,
            y + 6 * SCALE,
        ),
        fill=WHITE,
        width=2 * SCALE,
        joint="curve",
    )
    draw.text((x + 27 * SCALE, y - 4 * SCALE), text, font=text_font, fill=color)


def create_desktop() -> None:
    width, height = 1200, 400
    canvas = cover(Image.open(DESKTOP_BG), (width * SCALE, height * SCALE))
    draw = ImageDraw.Draw(canvas)
    draw_brand(draw, 61, 43, 17)

    kicker = font("segoeuib.ttf", 13)
    headline = font("segoeuib.ttf", 37)
    body = font("segoeui.ttf", 17)
    bullet = font("segoeui.ttf", 15)
    strip = font("segoeuib.ttf", 14)

    draw.text((60 * SCALE, 78 * SCALE), "GUIA COMPLETO DE CUIDADOS", font=kicker, fill=TEAL)
    draw.multiline_text(
        (58 * SCALE, 104 * SCALE),
        "Cuide de quem você ama com\nmais segurança e confiança.",
        font=headline,
        fill=NAVY,
        spacing=0,
    )
    draw.text(
        (60 * SCALE, 202 * SCALE),
        "Orientações práticas para uma rotina mais leve e organizada.",
        font=body,
        fill=MUTED,
    )

    draw_bullet(draw, 61, 243, "Passo a passo simples e visual", bullet)
    draw_bullet(draw, 61, 277, "Exercícios, alongamentos e massagens", bullet)
    draw_bullet(draw, 61, 311, "Calendário de cuidados + 6 bônus", bullet)

    draw.rounded_rectangle(
        (58 * SCALE, 352 * SCALE, 693 * SCALE, 390 * SCALE),
        radius=19 * SCALE,
        fill=DEEP_NAVY,
    )
    draw.text((82 * SCALE, 359 * SCALE), "ACESSO IMEDIATO  •  MATERIAL 100% DIGITAL", font=strip, fill=WHITE)
    add_product(canvas, (420, 382))

    canvas.resize((width, height), Image.Resampling.LANCZOS).convert("RGB").save(DESKTOP_OUT, "PNG", optimize=True)


def create_mobile() -> None:
    width, height = 720, 960
    canvas = cover(Image.open(MOBILE_BG), (width * SCALE, height * SCALE))
    draw = ImageDraw.Draw(canvas)
    draw_brand(draw, 61, 48, 19)

    kicker = font("segoeuib.ttf", 13)
    headline = font("segoeuib.ttf", 32)
    bullet = font("segoeui.ttf", 16)
    strip = font("segoeuib.ttf", 15)

    draw.text((58 * SCALE, 83 * SCALE), "GUIA COMPLETO DE CUIDADOS", font=kicker, fill=TEAL)
    draw.multiline_text(
        (56 * SCALE, 112 * SCALE),
        "Cuide de quem você ama\ncom mais segurança\ne confiança.",
        font=headline,
        fill=NAVY,
        spacing=-2 * SCALE,
    )
    product = Image.open(PRODUCT_PATH).convert("RGBA")
    product.thumbnail((450 * SCALE, 430 * SCALE), Image.Resampling.LANCZOS)
    px = (canvas.width - product.width) // 2
    py = 290 * SCALE
    mask = product.getchannel("A").filter(ImageFilter.GaussianBlur(14 * SCALE))
    shadow = Image.new("RGBA", product.size, (3, 15, 35, 90))
    shadow.putalpha(mask.point(lambda value: int(value * .42)))
    canvas.alpha_composite(shadow, (px + 8 * SCALE, py + 12 * SCALE))
    canvas.alpha_composite(product, (px, py))

    draw_bullet(draw, 65, 705, "Orientações simples e visuais", bullet)
    draw_bullet(draw, 65, 749, "Exercícios e atividades práticas", bullet)
    draw_bullet(draw, 65, 793, "Calendário + 6 bônus exclusivos", bullet)

    draw.rounded_rectangle(
        (54 * SCALE, 862 * SCALE, 666 * SCALE, 923 * SCALE),
        radius=30 * SCALE,
        fill=TEAL,
    )
    label = "ACESSO IMEDIATO • MATERIAL DIGITAL"
    label_w = draw.textlength(label, font=strip)
    draw.text(((canvas.width - label_w) / 2, 878 * SCALE), label, font=strip, fill=WHITE)

    canvas.resize((width, height), Image.Resampling.LANCZOS).convert("RGB").save(MOBILE_OUT, "PNG", optimize=True)


create_desktop()
create_mobile()
print(f"Desktop banner: {DESKTOP_OUT} (1200x400)")
print(f"Mobile banner:  {MOBILE_OUT} (720x960)")
