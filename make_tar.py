#!python

import argparse
import os

from pathlib import Path
import platform
import re
from shutil import copy2, rmtree, copytree
import tarfile

# ----------------------------------
# Definitions:
# ----------------------------------

# Game Script name
gs_name = "Expanded_Village_Growth_Economics"

# ----------------------------------


def get_openttd_game_dir(explicit_path=None):
    if explicit_path:
        return Path(explicit_path).expanduser()

    system = platform.system()
    if system == "Windows":
        candidates = [
            Path(os.environ.get("LOCALAPPDATA", Path.home() / "AppData" / "Local"))
            / "OpenTTD"
            / "game",
            Path(os.environ.get("APPDATA", Path.home() / "AppData" / "Roaming"))
            / "OpenTTD"
            / "game",
            Path.home() / "Documents" / "OpenTTD" / "game",
        ]
    elif system == "Darwin":
        candidates = [
            Path.home() / "Documents" / "OpenTTD" / "game",
            Path.home() / "Library" / "Application Support" / "OpenTTD" / "game",
        ]
    else:
        candidates = [
            Path.home() / ".local" / "share" / "openttd" / "game",
            Path.home() / ".openttd" / "game",
        ]

    for candidate in candidates:
        if candidate.exists():
            return candidate

    return candidates[0]


# Script:
parser = argparse.ArgumentParser(
    description="Build the RVG tarball and optionally install it into OpenTTD's game folder."
)
parser.add_argument(
    "--install",
    action="store_true",
    help="copy the generated tarball to the OpenTTD game directory",
)
parser.add_argument("--game-dir", help="explicit OpenTTD game directory path")
args = parser.parse_args()

mainversion = -1
subversion = -1
patchversion = -1
version_path = Path("src/version.nut")
if not version_path.exists():
    version_path = Path("version.nut")

try:
    with open(version_path, "r") as file:
        for line in file:
            r = re.search(r"SELF_MAJORVERSION\s+<-\s+([0-9]+)", line)
            if r is not None:
                mainversion = r.group(1)
            r2 = re.search(r"SELF_MINORVERSION\s+<-\s+([0-9]+)", line)
            if r2 is not None:
                subversion = r2.group(1)
            r3 = re.search(r"SELF_PATCHVERSION\s+<-\s+([0-9]+)", line)
            if r3 is not None:
                patchversion = r3.group(1)
except OSError as exc:
    print(f"Couldn't read {version_path}: {exc}")
    raise SystemExit(1)

if mainversion == -1 or subversion == -1:
    print("Couldn't find " + gs_name + " version in " + str(version_path) + "!")
    raise SystemExit(1)

if patchversion == -1:
    patchversion = 0

tmp_dir = (
    gs_name + "-" + str(mainversion) + "." + str(subversion) + "." + str(patchversion)
)
tar_name = tmp_dir + ".tar"

tmp_path = Path(tmp_dir)
if tmp_path.exists():
    rmtree(tmp_path)
tmp_path.mkdir()

for file in ["readme.txt", "license.txt", "changelog.txt", "CREDITS.md"]:
    copy2(file, tmp_path)

for file in Path(".").glob("*.nut"):
    if file.is_file():
        copy2(str(file), tmp_path)

# Copy all Squirrel files in src/ while keeping directory layout.
for file in Path("src").rglob("*.nut"):
    dest = tmp_path / file.relative_to(".")
    dest.parent.mkdir(parents=True, exist_ok=True)
    copy2(str(file), dest)

copytree("lang", tmp_path / "lang")

with tarfile.open(tar_name, "w:") as tar_handle:
    for root, _dirs, file_list in os.walk(tmp_path):
        for file in file_list:
            tar_handle.add(os.path.join(root, file))

if args.install:
    install_dir = get_openttd_game_dir(args.game_dir)
    install_dir.mkdir(parents=True, exist_ok=True)
    copy2(tar_name, install_dir / tar_name)
    print(f"Installed tarball to {install_dir / tar_name}")

rmtree(tmp_path)
print(f"Created {tar_name}")
