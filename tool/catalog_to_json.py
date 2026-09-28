#!/usr/bin/env python3
"""One-way conversion of the old Dart catalog into assets/catalog.json.

Kept in the repo as the record of how the JSON was first produced. The
JSON is the source of truth now — edit that, not this.
"""

import json
import pathlib
import re

SRC = pathlib.Path('lib/data/lesson_catalog.dart')
OUT = pathlib.Path('assets/catalog.json')

src = SRC.read_text()

palette = dict(re.findall(r'^const (_\w+) = Color\(0x([0-9A-Fa-f]+)\);', src, flags=re.M))


def hex_of(name: str) -> str:
    return '#' + palette[name][2:].upper()      # drop the alpha byte


def unquote(v: str) -> str:
    return v[1:-1]


units = []
for m in re.finditer(
    r"LessonUnit\(\s*id: '([^']+)',\s*section: '([^']+)',\s*"
    r"title: ('[^']*'|\"[^\"]*\"),\s*color: Color\(0x([0-9A-Fa-f]+)\),\s*"
    r"lessonIds: \[([^\]]*)\]", src):
    uid, section, title, colour, ids = m.groups()
    units.append({
        'id': uid,
        'section': section,
        'title': unquote(title),
        'color': '#' + colour[2:].upper(),
        'lessonIds': [i.strip().strip("'") for i in ids.split(',') if i.strip()],
    })

lessons = []
for m in re.finditer(
    r"^    Lesson\(\n      id: '([^']+)',\n      title: ('[^']*'|\"[^\"]*\"),\n"
    r"      subtitle: ('[^']*'|\"[^\"]*\"),\n      coverEmoji: '([^']+)',\n"
    r"      coverColor: (_\w+),\n      words: \[\n(.*?)\n      \],",
        src, flags=re.M | re.S):
    lid, title, subtitle, cover, cover_colour, body = m.groups()
    words = []
    for w in re.finditer(
        r"LessonWord\(emoji: '([^']+)', word: ('[^']*'|\"[^\"]*\"), "
        r"text: ('[^']*'|\"[^\"]*\"), color: (_\w+)\)", body):
        emoji, word, text, colour = w.groups()
        words.append({
            'emoji': emoji,
            'word': unquote(word),
            'text': unquote(text),
            'color': hex_of(colour),
        })
    lessons.append({
        'id': lid,
        'title': unquote(title),
        'subtitle': unquote(subtitle),
        'coverEmoji': cover,
        'coverColor': hex_of(cover_colour),
        'words': words,
    })

catalog = {'version': 1, 'units': units, 'lessons': lessons}
OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n')

print(f'{len(units)} units, {len(lessons)} lessons, '
      f'{sum(len(l["words"]) for l in lessons)} words -> {OUT}')
