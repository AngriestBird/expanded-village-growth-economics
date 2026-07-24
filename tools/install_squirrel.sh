#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
	printf 'Usage: %s INSTALL_DIR\n' "$0" >&2
	exit 2
fi

commit=f92bc298784ceea459b12e2de33bdff672bfeb83
archive_sha256=722f1a5f271dfb7ac90a42d3789a861b381b4741499de29ce06d238384645f2d
install_dir=$1
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

archive="$work_dir/squirrel.tar.gz"
source_dir="$work_dir/source"

curl --proto '=https' --tlsv1.2 \
	--fail --location --retry 3 --silent --show-error \
	--output "$archive" \
	"https://codeload.github.com/albertodemichelis/squirrel/tar.gz/$commit"
printf '%s  %s\n' "$archive_sha256" "$archive" | sha256sum --check --strict

mkdir -p "$source_dir" "$install_dir"
tar --extract --gzip --file "$archive" --directory "$source_dir" --strip-components=1
make -C "$source_dir" -j2 sq64 CC=g++
install -m 0755 "$source_dir/bin/sq" "$install_dir/sq"
"$install_dir/sq" -v | grep --fixed-strings "Squirrel 3.2 stable"
