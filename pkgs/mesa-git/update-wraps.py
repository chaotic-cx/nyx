#!/usr/bin/env/python3
# Adapted from https://github.com/NixOS/nixpkgs/blob/94ec6671dbe7d4879c2c8103e67425e85bf066d7/pkgs/development/libraries/mesa/update-wraps.py
import base64
import binascii
import configparser
import json
from operator import itemgetter
import pathlib
import sys
import urllib.parse


def to_sri(hash: str):
    raw = binascii.unhexlify(hash)
    b64 = base64.b64encode(raw).decode()
    return f"sha256-{b64}"


def main(dir: str):
    result = []
    for file in (pathlib.Path(dir) / "subprojects").glob("*.wrap"):
        name = file.stem
        parser = configparser.ConfigParser()
        _ = parser.read(file)
        sections = parser.sections()
        if "wrap-file" not in sections:
            continue

        url = parser.get("wrap-file", "source_url")
        if "crates.io" not in url:
            continue

        parsed = urllib.parse.urlparse(url)
        path = parsed.path.split("/")
        version = path[5]

        hash = to_sri(parser.get("wrap-file", "source_hash"))

        result.append({
            "pname": path[4],
            "wname": name,
            "version": version,
            "hash": hash,
        })

    sorted_result = sorted(result, key=itemgetter("wname"))

    here = pathlib.Path(__file__).parent
    with (here / "wraps.json").open("w") as fd:
        json.dump(sorted_result, fd, indent=2)
        _ = fd.write("\n")


if __name__ == '__main__':
    main(*sys.argv[1:])
