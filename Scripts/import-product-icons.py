#!/usr/bin/env python3
"""Regenerates the product icons of the app from the icon directory of the server.

Usage: Scripts/import-product-icons.py <path to backend/resources/icons/products>

Every `<key>.svg` becomes the image set `ProductIcons/<key>` of the asset catalog,
rendered as template with its vector data preserved. Path data is rewritten with
explicit separators, because the asset compiler rejects the compact notation some
optimisers produce for arc flags. The manifest and the license
note of the directory are copied into the resources of the app. Image sets of icons
that no longer exist are removed.
"""

import json
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "App" / "Assets.xcassets" / "ProductIcons"
RESOURCES = ROOT / "App" / "Resources"
SIZE = "24"
STROKE_WIDTH = "1.5"

NUMBER = re.compile(r"[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?")
ARC_PARAMETERS = 7
ARC_FLAGS = (3, 4)

GROUP_CONTENTS = {"info": {"author": "xcode", "version": 1}, "properties": {"provides-namespace": True}}


def image_set_contents(file_name: str) -> dict:
    """Describes an image set with one vector image that takes the tint of its view."""
    return {
        "images": [{"filename": file_name, "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
        "properties": {"preserves-vector-representation": True, "template-rendering-intent": "template"},
    }


def spaced_path(data: str) -> str:
    """Rewrites path data with one space between all commands and numbers.

    The two flags of an arc are single digits that may be written without separators,
    as in `a2 2 0 100 4`; they are read as such and written apart.
    """
    tokens = []
    command = ""
    parameter = 0
    position = 0
    while position < len(data):
        character = data[position]
        if character.isalpha():
            command = character
            parameter = 0
            tokens.append(character)
            position += 1
        elif character.isspace() or character == ",":
            position += 1
        elif command in "aA" and parameter % ARC_PARAMETERS in ARC_FLAGS:
            if character not in "01":
                raise ValueError(f"arc flag expected at {position} of {data!r}")
            tokens.append(character)
            parameter += 1
            position += 1
        else:
            number = NUMBER.match(data, position)
            if number is None:
                raise ValueError(f"number expected at {position} of {data!r}")
            tokens.append(number.group(0))
            parameter += 1
            position = number.end()
    return " ".join(tokens)


def normalise(svg: str) -> str:
    """Gives the drawing a fixed size, a black stroke of the app's width, no inherited colour and spaced path data."""
    root = re.search(r"<svg\b[^>]*>", svg)
    if root is None:
        raise ValueError("no <svg> element")
    tag = root.group(0)
    tag = re.sub(r'\s(?:width|height)="[^"]*"', "", tag)
    tag = re.sub(r'\sstroke-width="[^"]*"', f' stroke-width="{STROKE_WIDTH}"', tag)
    tag = tag.replace("<svg", f'<svg width="{SIZE}" height="{SIZE}"', 1)
    svg = svg[: root.start()] + tag + svg[root.end():]
    svg = re.sub(r'(\sd=")([^"]*)(")', lambda match: match.group(1) + spaced_path(match.group(2)) + match.group(3), svg)
    return svg.replace("currentColor", "#000")


def write_json(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__.strip().splitlines()[2], file=sys.stderr)
        return 2
    source = Path(sys.argv[1])
    icons = sorted(source.glob("*.svg"))
    manifest = json.loads((source / "manifest.json").read_text(encoding="utf-8"))
    missing = sorted({entry["key"] for entry in manifest} - {icon.stem for icon in icons})
    if not icons or missing:
        print(f"no icons found or icons of the manifest missing: {missing}", file=sys.stderr)
        return 1

    if ASSETS.exists():
        shutil.rmtree(ASSETS)
    ASSETS.mkdir(parents=True)
    write_json(ASSETS / "Contents.json", GROUP_CONTENTS)
    for icon in icons:
        image_set = ASSETS / f"{icon.stem}.imageset"
        image_set.mkdir()
        (image_set / icon.name).write_text(normalise(icon.read_text(encoding="utf-8")), encoding="utf-8")
        write_json(image_set / "Contents.json", image_set_contents(icon.name))

    RESOURCES.mkdir(parents=True, exist_ok=True)
    write_json(RESOURCES / "ProductIcons.json", manifest)
    shutil.copyfile(source / "README.md", RESOURCES / "ProductIcons-LICENSE.md")
    print(f"{len(icons)} icons imported")
    return 0


if __name__ == "__main__":
    sys.exit(main())
