#!/usr/bin/env python3
"""Raise the generated iOS project's deployment target.

`flutter create` writes an ios/ folder that still targets iOS 13, but
firebase_core 4.x requires iOS 15 — `pod install` refuses the mismatch
and the build dies before it compiles a line of Dart. CI regenerates
ios/ on every run, so this patch has to run on every run too.
"""

import pathlib
import re
import sys

TARGET = "15.0"

podfile = pathlib.Path("ios/Podfile")
pbxproj = pathlib.Path("ios/Runner.xcodeproj/project.pbxproj")

missing = [str(p) for p in (podfile, pbxproj) if not p.exists()]
if missing:
    sys.exit("iOS project not generated yet: no " + ", ".join(missing))

# 1. The app's own minimum. The template ships this line commented out.
text = podfile.read_text()
text, found = re.subn(
    r"^#?\s*platform :ios.*$",
    f"platform :ios, '{TARGET}'",
    text,
    count=1,
    flags=re.M,
)
if not found:
    text = f"platform :ios, '{TARGET}'\n" + text

# 2. Every pod's minimum. Some podspecs declare an older one, which Xcode
#    then warns about and, for a few, fails on.
if "IPHONEOS_DEPLOYMENT_TARGET" not in text:
    def extend(match):
        indent = match.group(1)
        return (
            f"{match.group(0)}\n"
            f"{indent}target.build_configurations.each do |config|\n"
            f"{indent}  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '{TARGET}'\n"
            f"{indent}end"
        )

    text, found = re.subn(
        r"( *)flutter_additional_ios_build_settings\(target\)", extend, text, count=1
    )
    if not found:
        sys.exit("Podfile has no flutter_additional_ios_build_settings hook to extend")

podfile.write_text(text)

# 3. The Runner target itself, which the Podfile can't reach.
project = pbxproj.read_text()
project, count = re.subn(
    r"IPHONEOS_DEPLOYMENT_TARGET = [\d.]+;",
    f"IPHONEOS_DEPLOYMENT_TARGET = {TARGET};",
    project,
)
pbxproj.write_text(project)

print(f"Pinned Podfile + {count} Runner build settings to iOS {TARGET}")
