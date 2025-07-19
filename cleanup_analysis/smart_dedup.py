#!/usr/bin/env python3
"""
Smart deduplication - keeps the best version of each file
based on location and modification time
"""
import os
import subprocess
from datetime import datetime

def get_file_info(filepath):
    """Get file info including last commit date"""
    try:
        # Get last commit date
        result = subprocess.run(
            ['git', 'log', '-1', '--format=%at', filepath],
            capture_output=True, text=True
        )
        if result.returncode == 0 and result.stdout.strip():
            timestamp = int(result.stdout.strip())
            last_commit = datetime.fromtimestamp(timestamp)
        else:
            last_commit = datetime.fromtimestamp(os.path.getmtime(filepath))
        
        # Get file size
        size = os.path.getsize(filepath)
        
        return {
            'path': filepath,
            'last_commit': last_commit,
            'size': size,
            'depth': filepath.count('/')
        }
    except:
        return None

def choose_best_file(duplicates):
    """Choose the best file from duplicates based on criteria"""
    file_infos = []
    
    for filepath in duplicates:
        info = get_file_info(filepath)
        if info:
            file_infos.append(info)
    
    if not file_infos:
        return None
    
    # Sort by criteria (prefer organized structure, newer files, larger files)
    file_infos.sort(key=lambda x: (
        -x['depth'],  # Prefer files in subdirectories
        x['last_commit'],  # Prefer newer files
        -x['size']  # Prefer larger files (likely more complete)
    ))
    
    return file_infos[-1]['path']  # Return best match

# Read duplicates and process
with open('./cleanup_analysis/duplicates.txt', 'r') as f:
    content = f.read()

sections = content.split('\n===')
decisions = []

for section in sections[1:]:  # Skip first empty section
    lines = section.strip().split('\n')
    if lines:
        filename = lines[0].split('(')[0].strip()
        paths = [line.strip() for line in lines[1:] if line.strip()]
        
        if len(paths) > 1:
            best = choose_best_file(paths)
            if best:
                to_remove = [p for p in paths if p != best]
                decisions.append({
                    'keep': best,
                    'remove': to_remove,
                    'filename': filename
                })

# Generate removal script
with open('./cleanup_analysis/smart_cleanup.sh', 'w') as f:
    f.write('#!/bin/bash\n\n')
    f.write('# Smart cleanup - keeping best versions\n\n')
    
    for decision in decisions:
        f.write(f"# {decision['filename']}\n")
        f.write(f"# Keeping: {decision['keep']}\n")
        for path in decision['remove']:
            f.write(f"rm -f \"{path}\"\n")
        f.write('\n')

print(f"Generated smart cleanup script with {len(decisions)} decisions")
