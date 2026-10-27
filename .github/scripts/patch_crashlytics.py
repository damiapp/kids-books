#!/usr/bin/env python3
"""Add the Crashlytics Gradle plugin to the generated Android project.

The Crashlytics Android SDK refuses to start without a build ID, which
only this plugin writes into the app — and "refuses" means it throws
during app startup. So an APK built without the plugin doesn't just lose
crash reports: it crashes on launch, on every phone. That is why the
workflow checks the built APK for the ID afterwards rather than trusting
this patch to have worked.

Like the other patches, this runs on every build, because CI regenerates
the whole android/ folder with `flutter create` each time.

Mapping-file upload is switched off. It only de-obfuscates the app's
Java/Kotlin frames — Dart stack traces, where Peekadoo's own code runs,
arrive readable without it — and it would make every build depend on a
network call to Firebase and on Crashlytics already being switched on in
the console.
"""

import pathlib
import re
import sys

# Pinned, because the plugins block can't take a range. Crashlytics
# 3.0.7 is the release that works with AGP 9 (the template uses 9.x).
CRASHLYTICS_PLUGIN = 'com.google.firebase.crashlytics'
CRASHLYTICS_VERSION = '3.0.7'

SETTINGS = pathlib.Path('android/settings.gradle.kts')
APP = pathlib.Path('android/app/build.gradle.kts')

IMPORT = 'import com.google.firebase.crashlytics.buildtools.gradle.CrashlyticsExtension\n'

RELEASE_CONFIG = """
            configure<CrashlyticsExtension> {
                mappingFileUploadEnabled = false
            }"""


def fail(message: str) -> None:
    sys.exit(
        f'{message}\nThe Flutter template changed — check what '
        f'`flutter create` writes now before trusting this patch.'
    )


def patch_settings(text: str) -> str:
    if CRASHLYTICS_PLUGIN in text:
        return text
    line = re.search(
        r'^([ \t]*)id\("com\.android\.application"\) version "[^"]+" apply false[ \t]*$',
        text,
        flags=re.M,
    )
    if not line:
        fail(f'{SETTINGS}: no com.android.application plugin declaration')
    indent = line.group(1)
    declaration = (
        f'\n{indent}id("{CRASHLYTICS_PLUGIN}") '
        f'version "{CRASHLYTICS_VERSION}" apply false'
    )
    return text[:line.end()] + declaration + text[line.end():]


def patch_app(text: str) -> str:
    if CRASHLYTICS_PLUGIN in text:
        return text

    # 1. Apply the plugin, right after the Android plugin it hooks into.
    line = re.search(
        r'^([ \t]*)id\("com\.android\.application"\)[ \t]*$', text, flags=re.M
    )
    if not line:
        fail(f'{APP}: no id("com.android.application") in its plugins block')
    text = (
        text[:line.end()]
        + f'\n{line.group(1)}id("{CRASHLYTICS_PLUGIN}")'
        + text[line.end():]
    )

    # 2. No mapping-file upload (see the module docstring).
    release = re.search(r'^[ \t]*release[ \t]*\{[ \t]*$', text, flags=re.M)
    if not release:
        fail(f'{APP}: no `release {{` build type')
    text = text[:release.end()] + RELEASE_CONFIG + text[release.end():]

    # 3. The extension's type, for configure<> above. Imports have to
    #    come before everything else in a .kts file.
    return IMPORT + text


def main() -> None:
    for path, patch in ((SETTINGS, patch_settings), (APP, patch_app)):
        if not path.exists():
            sys.exit(f'{path} not found — run flutter create first')
        before = path.read_text()
        after = patch(before)
        path.write_text(after)
        print(f'{path}: {"patched" if after != before else "already patched"}')


if __name__ == '__main__':
    main()
