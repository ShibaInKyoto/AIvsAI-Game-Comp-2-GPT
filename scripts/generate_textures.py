"""Small original seamless art-deco surfaces, generated with Python's standard library."""
from pathlib import Path
import math
import random
import struct
import zlib
OUT = Path(__file__).resolve().parents[1] / 'assets' / 'textures'
OUT.mkdir(parents=True, exist_ok=True)

def png(name, size, paint):
    raw = b''.join(b'\0' + bytes(c for x in range(size) for c in paint(x, y)) for y in range(size))
    def chunk(kind, body):
        return struct.pack('!I', len(body)) + kind + body + struct.pack('!I', zlib.crc32(kind + body) & 0xffffffff)
    (OUT / name).write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('!2I5B', size, size, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))

def wood(x,y):
    grain = math.sin(y * 0.8 + math.sin(x / 22) * 2) * 7 + math.sin(y * 2.1 + x / 50) * 3
    edge = -20 if y < 2 or y > 125 else 0
    return tuple(max(0,min(255,round(c + grain + edge))) for c in (148, 123, 113))

def carpet(x,y):
    d = abs(x-64) / 30 + abs((y % 64)-32) / 25
    line = abs(d - 1) < .055 or abs(d - .72) < .035
    dots = (x % 16 in (0,1)) and (y % 16 in (0,1))
    if line: return (191, 144, 106)
    if dots: return (129, 78, 91)
    return (105, 58, 78)

def paper(x,y):
    # Nested fan motif; gold stays subtle enough to keep relics legible.
    px = abs((x % 64)-32)
    py = y % 64
    curve = math.sqrt(px*px + (py+8)*(py+8))
    line = curve % 16 < 1.6
    return (116, 130, 110) if line else (62, 100, 104)

png('wood.png', 128, wood)
png('runner.png', 128, carpet)
png('wallpaper.png', 128, paper)
print('Generated original woodgrain, woven runner and fan wallpaper.')
