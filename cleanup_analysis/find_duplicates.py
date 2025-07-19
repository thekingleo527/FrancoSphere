#!/usr/bin/env python3
import os
from collections import defaultdict

duplicates = defaultdict(list)

with open('./cleanup_analysis/all_files.txt', 'r') as f:
    for line in f:
        filepath = line.strip()
        if filepath:
            filename = os.path.basename(filepath)
            duplicates[filename].append(filepath)

# Write duplicate report
with open('./cleanup_analysis/duplicates.txt', 'w') as out:
    for filename, paths in sorted(duplicates.items()):
        if len(paths) > 1:
            out.write(f"\n=== {filename} ({len(paths)} copies) ===\n")
            for path in paths:
                out.write(f"  {path}\n")
