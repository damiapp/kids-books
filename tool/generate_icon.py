#!/usr/bin/env python3
"""Draws the Peekadoo launcher icon.

Run it to regenerate `assets/icon/` after changing a colour or a
proportion:

    pip install Pillow && python3 tool/generate_icon.py

It writes two files, because Android wants two things:

* `icon.png` — the whole icon, background included, for legacy launchers.
* `icon_foreground.png` — the art alone on transparency, for adaptive
  icons, which composite it over `adaptive_icon_background` and then let
  the launcher crop the result to whatever shape it likes. Anything
  outside the middle ~66% of that canvas can be cropped away, so the
  eyes are drawn well inside it and only the wall is allowed to bleed.

The subject is peek-a-boo, which is what the name is: two eyes looking
over a wall. It survives being 48px on a home screen, which rules out
anything with fine detail.
"""

import pathlib

from PIL import Image, ImageDraw

SIZE = 1024
OUT = pathlib.Path('assets/icon')

TEAL = (58, 167, 160, 255)        # the app's seed colour
CREAM = (253, 251, 246, 255)      # the app's background
INK = (45, 62, 66, 255)           # pupils — softer than pure black
SHADOW = (0, 0, 0, 26)            # a hair of depth under the wall


def draw_art(draw: ImageDraw.ImageDraw, scale: float) -> None:
    """Wall plus eyes. Coordinates are fractions of the canvas, mapped
    through `scale` about the centre — the adaptive foreground draws the
    same art smaller so the eyes stay inside the safe zone."""

    def px(xn: float) -> float:
        return SIZE * (0.5 + (xn - 0.5) * scale)

    def py(yn: float) -> float:
        return SIZE * (0.5 + (yn - 0.5) * scale)

    def r(n: float) -> float:
        return SIZE * n * scale

    eye_cy, eye_r, eye_dx = 0.47, 0.135, 0.150
    pupil_r, wall_top = 0.060, 0.600

    for sign in (-1, 1):
        ex, ey = px(0.5 + sign * eye_dx), py(eye_cy)
        er = r(eye_r)
        draw.ellipse([ex - er, ey - er, ex + er, ey + er], fill=CREAM)

        # Pupils sit low and slightly inward — looking over the edge,
        # not straight through you.
        cx, cy = ex - sign * r(0.012), ey + r(0.035)
        pr = r(pupil_r)
        draw.ellipse([cx - pr, cy - pr, cx + pr, cy + pr], fill=INK)

        # Catchlight. Small, but it's the difference between eyes and dots.
        hr = r(0.021)
        hx, hy = cx + sign * r(0.020), cy - r(0.032)
        draw.ellipse([hx - hr, hy - hr, hx + hr, hy + hr], fill=CREAM)

    # A soft dome rather than a flat band, and wide enough that no
    # launcher mask can reveal its ends. Drawn last so it overlaps the
    # eyes — that overlap is what makes them read as *behind* it.
    draw.ellipse(
        [px(-0.35), py(wall_top), px(1.35), py(2.2)],
        fill=CREAM,
    )


def build(foreground_only: bool) -> Image.Image:
    img = Image.new(
        'RGBA', (SIZE, SIZE), (0, 0, 0, 0) if foreground_only else TEAL
    )
    # Adaptive foregrounds get cropped at the edges, so that art is drawn
    # smaller to keep the eyes well inside the safe zone.
    draw_art(ImageDraw.Draw(img), scale=0.74 if foreground_only else 1.0)
    return img


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    build(foreground_only=False).save(OUT / 'icon.png')
    build(foreground_only=True).save(OUT / 'icon_foreground.png')
    print(f'wrote {OUT}/icon.png and {OUT}/icon_foreground.png')


if __name__ == '__main__':
    main()
