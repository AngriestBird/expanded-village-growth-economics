#!/usr/bin/env python3
"""Syntax-check every .nut file and run the Squirrel unit tests in tests/.

Needs a standalone Squirrel interpreter. Set SQ to point at one, otherwise `sq`
from PATH is used (Debian/Ubuntu: apt-get install squirrel3). Note that `sq`
exits 0 even when a script raises, so test success is decided by the sentinel
the test script prints on its way out. Compilation failures do exit non-zero.
"""
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

SENTINEL = "ALL TESTS PASSED"

# Distributions disagree on what to call the interpreter.
SQ_NAMES = ("sq", "sq3", "squirrel3", "squirrel")


def find_interpreter():
    explicit = os.environ.get("SQ")
    if explicit:
        return explicit
    for name in SQ_NAMES:
        found = shutil.which(name)
        if found:
            return found
    return None


def compile_check(sq, repo):
    """Compile each script without running it, to catch syntax errors early."""
    sources = sorted(repo.glob("*.nut")) + sorted(repo.glob("src/*.nut"))
    failed = []
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "out.cnut"
        for source in sources:
            result = subprocess.run(
                [sq, "-c", "-o", str(out), str(source.relative_to(repo))],
                cwd=repo,
                capture_output=True,
                text=True,
            )
            if result.returncode != 0:
                failed.append(source.relative_to(repo))
                sys.stdout.write(result.stdout)
                sys.stderr.write(result.stderr)

    print(f"Compiled {len(sources)} script(s), {len(failed)} failed.")
    return not failed


def main():
    repo = Path(__file__).resolve().parent.parent
    sq = find_interpreter()
    if not sq:
        print(
            "No Squirrel interpreter found (looked for: "
            + ", ".join(SQ_NAMES)
            + "). Install squirrel3 or set SQ=/path/to/sq."
        )
        return 1

    if not compile_check(sq, repo):
        return 1

    result = subprocess.run(
        [sq, "tests/run_tests.nut"], cwd=repo, capture_output=True, text=True
    )
    sys.stdout.write(result.stdout)
    sys.stderr.write(result.stderr)

    if result.returncode != 0 or SENTINEL not in result.stdout:
        print("Tests failed.")
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
