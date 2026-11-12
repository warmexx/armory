"""Cut Armory's own race portraits from Blizzard's character create icons.

For races without Interface\CharacterFrame\TemporaryPortrait-<Sex>-<Race> in the game.
Writes 64x64 round 32-bit TGA files to Artwork/, in the style of Blizzard's portraits.
Needs a Retail art export (start the client with -console, then: exportInterfaceFiles art) and Pillow.

Usage: python -I portraits.py
"""
import os
from PIL import Image, ImageDraw

ICONS = r"D:\Games\World of Warcraft\_retail_\BlizzardInterfaceArt\Interface\GLUES\CHARACTERCREATE\CharacterCreateIcons.BLP"
ARTWORK = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "Artwork")

# Cell (row, column) in the icon sheet. Cells are 124 px, every 130.4 px, starting at 4 px.
CELLS = {
    "Female-EarthenDwarf": (4, 3),
    "Male-EarthenDwarf": (5, 3),
    "Female-Harronir": (3, 4),
    "Male-Harronir": (4, 4),
}
S = 4  # supersampling for smooth edges

src = Image.open(ICONS).convert("RGBA")
for name, (r, c) in CELLS.items():
    x = 4 + round(130.4 * c)
    y = 4 + round(130.4 * r)
    face = src.crop((x, y, x + 124, y + 124)).resize((54 * S, 54 * S), Image.LANCZOS)
    img = Image.new("RGBA", (64 * S, 64 * S), (0, 0, 0, 0))
    disc = Image.new("L", img.size, 0)
    ImageDraw.Draw(disc).ellipse((1 * S, 1 * S, 63 * S, 63 * S), fill=255)
    inner = Image.new("L", img.size, 0)
    ImageDraw.Draw(inner).ellipse((5 * S, 5 * S, 59 * S, 59 * S), fill=255)
    img.paste((0, 0, 0, 255), (0, 0), disc)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    layer.paste(face, (5 * S, 5 * S))
    img.paste(layer, (0, 0), inner)
    path = os.path.join(ARTWORK, "TemporaryPortrait-" + name + ".tga")
    img.resize((64, 64), Image.LANCZOS).save(path, compression=None)
    print(path)
