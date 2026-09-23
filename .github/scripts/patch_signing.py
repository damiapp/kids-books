#!/usr/bin/env python3
"""Give the generated Android project a real release signing config.

`flutter create` writes a release build type that signs with
`signingConfigs.debug`, and CI regenerates the whole android/ folder on
every run — so this patch runs every run too.

The values come from the environment rather than a key.properties file:
one less file to write, one less path to get wrong, and nothing to
delete afterwards. The workflow only runs this when the keystore secret
is present, so the untouched template (debug signing) stays the
fallback for a fork without it.
"""

import os
import pathlib
import re
import sys

ENV_VARS = (
    'PEEKADOO_KEYSTORE',
    'PEEKADOO_STORE_PASSWORD',
    'PEEKADOO_KEY_ALIAS',
    'PEEKADOO_KEY_PASSWORD',
)

KOTLIN_CONFIG = """
    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("PEEKADOO_KEYSTORE"))
            storePassword = System.getenv("PEEKADOO_STORE_PASSWORD")
            keyAlias = System.getenv("PEEKADOO_KEY_ALIAS")
            keyPassword = System.getenv("PEEKADOO_KEY_PASSWORD")
        }
    }
"""

GROOVY_CONFIG = """
    signingConfigs {
        release {
            storeFile file(System.getenv("PEEKADOO_KEYSTORE"))
            storePassword System.getenv("PEEKADOO_STORE_PASSWORD")
            keyAlias System.getenv("PEEKADOO_KEY_ALIAS")
            keyPassword System.getenv("PEEKADOO_KEY_PASSWORD")
        }
    }
"""


def patch(path: pathlib.Path) -> str:
    text = path.read_text()
    kotlin = path.suffix == '.kts'

    if 'PEEKADOO_KEYSTORE' in text:
        return 'already patched'

    # 1. Declare the release config. It goes directly after `android {` so
    #    it exists before buildTypes asks for it by name — Gradle resolves
    #    getByName at configuration time, in file order.
    marker = re.search(r'^android\s*\{[ \t]*$', text, flags=re.M)
    if not marker:
        sys.exit(f'{path}: no `android {{` block to extend')
    insert_at = marker.end()
    config = KOTLIN_CONFIG if kotlin else GROOVY_CONFIG
    text = text[:insert_at] + config + text[insert_at:]

    # 2. Point the release build type at it instead of the debug key.
    if kotlin:
        pattern = r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)'
        replacement = 'signingConfig = signingConfigs.getByName("release")'
    else:
        pattern = r'signingConfig\s+signingConfigs\.debug\b'
        replacement = 'signingConfig signingConfigs.release'

    text, swapped = re.subn(pattern, replacement, text)
    if swapped != 1:
        sys.exit(
            f'{path}: expected exactly one debug signingConfig in the release '
            f'build type, found {swapped}. The Flutter template changed — '
            f'check what it writes now before trusting this patch.'
        )

    path.write_text(text)
    return f'patched ({swapped} build type)'


def main() -> None:
    missing = [name for name in ENV_VARS if not os.environ.get(name)]
    if missing:
        sys.exit('not set: ' + ', '.join(missing))

    keystore = pathlib.Path(os.environ['PEEKADOO_KEYSTORE'])
    if not keystore.is_file():
        sys.exit(f'keystore not found at {keystore}')

    for name in ('android/app/build.gradle.kts', 'android/app/build.gradle'):
        path = pathlib.Path(name)
        if path.exists():
            print(f'{name}: {patch(path)}')
            return

    sys.exit('no android/app/build.gradle[.kts] — run flutter create first')


if __name__ == '__main__':
    main()
