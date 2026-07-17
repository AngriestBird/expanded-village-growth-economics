#!/usr/bin/env python3
"""Check translation files against the master english.txt.

Fails if a translation defines a STR_ key that does not exist in english.txt
(an orphan, usually a leftover from a removed string). Missing keys are only
reported, since OpenTTD falls back to the master language for those.
"""
import re
import sys
import glob
import os

KEY_RE = re.compile(r'#?\s*(STR_\w+)\s*:')


def parse_keys(path, include_commented=False):
    keys = set()
    with open(path, encoding='utf-8') as f:
        for line in f:
            s = line.strip()
            m = KEY_RE.match(s)
            if not m:
                continue
            if s.startswith('#') and not include_commented:
                continue
            keys.add(m.group(1))
    return keys


def main():
    lang_dir = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', 'lang'))
    master = os.path.join(lang_dir, 'english.txt')
    known = parse_keys(master, include_commented=True)
    active_master = parse_keys(master)

    failed = False
    for path in sorted(glob.glob(os.path.join(lang_dir, '*.txt'))):
        name = os.path.basename(path)
        if name == 'english.txt':
            continue
        keys = parse_keys(path)
        orphans = sorted(keys - known)
        missing = sorted(active_master - keys)
        if orphans:
            failed = True
            print(f"ERROR {name}: {len(orphans)} unknown key(s) not in english.txt:")
            for k in orphans:
                print(f"    {k}")
        if missing:
            print(f"info  {name}: {len(missing)} key(s) missing (fall back to English)")

    if failed:
        print("Language check failed: remove or fix unknown keys.")
        sys.exit(1)
    print("Language check passed.")


if __name__ == '__main__':
    main()
