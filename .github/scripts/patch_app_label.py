#!/usr/bin/env python3
"""Capitalise the launcher label.

`flutter create` writes `android:label` from `--project-name`, which has
to be a valid Dart package name and so is lowercase — leaving "peekadoo"
under the icon on the home screen. CI regenerates the manifest on every
build, so this runs on every build.
"""

import pathlib
import re
import sys

LABEL = 'Peekadoo'
MANIFEST = pathlib.Path('android/app/src/main/AndroidManifest.xml')


def main() -> None:
    if not MANIFEST.exists():
        sys.exit(f'{MANIFEST} not found — run flutter create first')

    text = MANIFEST.read_text()
    patched, count = re.subn(
        r'android:label="[^"]*"', f'android:label="{LABEL}"', text, count=1
    )
    if count != 1:
        sys.exit(f'{MANIFEST}: no android:label to set')

    MANIFEST.write_text(patched)
    print(f'launcher label set to "{LABEL}"')


if __name__ == '__main__':
    main()
