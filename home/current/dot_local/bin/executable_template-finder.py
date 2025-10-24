#!/usr/bin/env python
import os
import re
import hashlib
import argparse
from collections import defaultdict

def normalize_code(code):
    # Strip comments, whitespace, and normalize identifiers
    code = re.sub(r'#.*', '', code)  # remove comments
    code = re.sub(r'\s+', ' ', code)  # collapse whitespace
    code = re.sub(r'\b\w+\b', 'VAR', code)  # normalize identifiers
    return code.strip()

def hash_window(tokens, start, size):
    window = ' '.join(tokens[start:start+size])
    return hashlib.md5(window.encode()).hexdigest()

def extract_templates(file_paths, window_size=10, min_occurrences=2):
    hash_map = defaultdict(list)

    for path in file_paths:
        with open(path, 'r', encoding='utf-8') as f:
            raw = f.read()
            norm = normalize_code(raw)
            tokens = norm.split()

            for i in range(len(tokens) - window_size + 1):
                h = hash_window(tokens, i, window_size)
                hash_map[h].append((path, i))

    # Filter by occurrence threshold
    templates = {h: locs for h, locs in hash_map.items() if len(locs) >= min_occurrences}
    return templates

def main():
    parser = argparse.ArgumentParser(description="Detect templating opportunities across source files.")
    parser.add_argument("files", nargs='+', help="List of source files to analyze")
    parser.add_argument("--window", type=int, default=10, help="Minimum token window size")
    parser.add_argument("--min", type=int, default=2, help="Minimum occurrences to consider a template")
    args = parser.parse_args()

    templates = extract_templates(args.files, args.window, args.min)

    print(f"\n🔍 Found {len(templates)} templating opportunities:\n")
    for h, locs in templates.items():
        print(f"Template Hash: {h}")
        for path, idx in locs:
            print(f"  - {path} @ token index {idx}")
        print()

if __name__ == "__main__":
    main()
