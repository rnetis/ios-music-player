"""Generates the 1024x1024 app icon (AppIcon.png) for the MusicPlayer asset catalog.

Pure Python stdlib (zlib + struct) — no Pillow required.

Usage:  python scripts/make_icon.py
Output: MusicPlayer/Assets.xcassets/AppIcon.appiconset/AppIcon.png
"""

import struct
import zlib

SIZE = 1024
OUT = "MusicPlayer/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

# Layout constants
NOTE_CX, NOTE_CY = 512, 480
HEAD_R = 88
HEAD1 = (400, 660)
HEAD2 = (624, 660)
STEM_W = 30
STEM_TOP = 392
STEM_BOTTOM = HEAD1[1] - HEAD_R + 8
BEAM = (STEM_TOP - 6, STEM_TOP + 46)


def png_chunk(kind, data):
    return (
        struct.pack(">I", len(data))
        + kind
        + data
        + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    )


def write_png(path, width, height, pixel):
    """pixel(x, y) -> (r, g, b)"""
    raw = bytearray()
    for y in range(height):
        raw.append(0)  # filter: none
        for x in range(width):
            raw.extend(pixel(x, y))
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(png_chunk(b"IHDR", ihdr))
        f.write(png_chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        f.write(png_chunk(b"IEND", b""))


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def in_ellipse(x, y, cx, cy, rx, ry):
    dx = (x - cx) / rx
    dy = (y - cy) / ry
    return dx * dx + dy * dy <= 1.0


def in_rect(x, y, x0, y0, x1, y1):
    return x0 <= x <= x1 and y0 <= y <= y1


def in_note(x, y):
    """Beamed eighth note (heads, stems, beam)."""
    if in_ellipse(x, y, HEAD1[0], HEAD1[1], HEAD_R, HEAD_R):
        return True
    if in_ellipse(x, y, HEAD2[0], HEAD2[1], HEAD_R, HEAD_R):
        return True
    if in_rect(x, y, HEAD1[0] + 34, STEM_TOP, HEAD1[0] + 34 + STEM_W, STEM_BOTTOM):
        return True
    if in_rect(x, y, HEAD2[0] + 34, STEM_TOP, HEAD2[0] + 34 + STEM_W, STEM_BOTTOM):
        return True
    if in_rect(x, y, HEAD1[0] + 34 - 8, BEAM[0], HEAD2[0] + 34 + STEM_W + 8, BEAM[1]):
        return True
    return False


def main():
    top = (58, 22, 92)
    bottom = (10, 8, 20)
    glow_color = (168, 85, 247)  # purple glow
    under_color = (94, 234, 212)  # cyan under-glow
    white = (248, 250, 255)

    GLOW_R = 330  # glow radius around NOTE_CX, NOTE_CY
    UNDER_R = 168  # tight cyan halo around the note

    def pixel(x, y):
        # Background: vertical gradient
        t = y / (SIZE - 1)
        color = lerp(top, bottom, t)

        # Radial purple glow
        dx = x - NOTE_CX
        dy = y - NOTE_CY
        dist = (dx * dx + dy * dy) ** 0.5
        if dist < GLOW_R:
            a = (1.0 - dist / GLOW_R) ** 2 * 0.55
            color = lerp(color, glow_color, a)

        # Note shape (cyan halo then white core)
        if in_note(x, y):
            color = under_color
        if in_note(x, y) and dist < UNDER_R:
            # fade the halo into the white core near the center
            f = min(1.0, dist / UNDER_R)
            color = lerp(under_color, white, f)
        return color

    write_png(OUT, SIZE, SIZE, pixel)
    print(f"Wrote {OUT} ({SIZE}x{SIZE})")


if __name__ == "__main__":
    main()
