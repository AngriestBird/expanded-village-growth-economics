#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
	printf 'Usage: %s INSTALL_DIR\n' "$0" >&2
	exit 2
fi

commit=f92bc298784ceea459b12e2de33bdff672bfeb83
install_dir=$1
mkdir -p "$install_dir"
source_dir=$(mktemp -d "$install_dir/source.XXXXXX")

git clone --no-checkout https://github.com/albertodemichelis/squirrel.git "$source_dir"
git -C "$source_dir" checkout --detach "$commit"
make -C "$source_dir" -j2 sq64 CC=g++
install -m 0755 "$source_dir/bin/sq" "$install_dir/sq"
"$install_dir/sq" -v | grep --fixed-strings "Squirrel 3.2 stable"
