#!/usr/bin/env python3
"""Run the shared game logic outside Roblox.

Bundles src/shared into one Luau file (each module wrapped with a fake `script` and `require`),
then runs it with the luau CLI (https://github.com/luau-lang/luau/releases).

    python3 tests/run.py          # unit tests (tests/*.spec.luau)
    python3 tests/run.py sim      # economy simulation report (tests/sim/*.luau)

Set LUAU=/path/to/luau if it isn't on PATH.
"""
import os
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
SHARED = ROOT / "src" / "shared"
TESTS = ROOT / "tests"
LUAU = os.environ.get("LUAU", "luau")


def bundle(test_files):
    parts = [(TESTS / "prelude.luau").read_text()]
    for path in sorted(SHARED.rglob("*.luau")):
        rel = path.relative_to(SHARED).with_suffix("")
        instance_path = "/".join(["ReplicatedStorage", "FlipShared", *rel.parts])
        parts.append(f'__module("{instance_path}", function(script, require)\n{path.read_text()}\nend)')
    for path in sorted((TESTS / "support").glob("*.luau")):
        parts.append(f'__module("Tests/{path.stem}", function(script, require)\n{path.read_text()}\nend)')
    for path in test_files:
        name = path.relative_to(ROOT).as_posix()
        parts.append(f'__file("{name}", function(require, FlipShared, Tests)\n{path.read_text()}\nend)')
    parts.append("__runTests()")
    return "\n".join(parts)


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "test"
    if mode == "sim":
        files = sorted((TESTS / "sim").glob("*.luau"))
    else:
        files = sorted(TESTS.glob("*.spec.luau"))
    with tempfile.NamedTemporaryFile("w", suffix=".luau", delete=False) as out:
        out.write(bundle(files))
    try:
        return subprocess.call([LUAU, out.name])
    finally:
        os.unlink(out.name)


if __name__ == "__main__":
    sys.exit(main())
