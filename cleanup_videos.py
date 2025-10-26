#!/usr/bin/env python3
"""
Remove all videos added on or after October 20, 2025 from shot JSON files.
"""

import json
import re
from pathlib import Path
from datetime import datetime

# Cutoff date: October 20, 2025
CUTOFF_DATE = 20251020

def extract_date_from_filename(filename):
    """
    Extract date from various filename patterns.
    Returns integer YYYYMMDD or None if no date found.
    """
    # Pattern 1: Subject_xxx_202510232221_xxx.mp4 -> 20251023
    match = re.search(r'_(\d{12})_', filename)
    if match:
        date_str = match.group(1)[:8]  # Take first 8 digits (YYYYMMDD)
        return int(date_str)

    # Pattern 2: 2025-09-20T03-06-32_xxx.mp4 -> 20250920
    match = re.search(r'(\d{4})-(\d{2})-(\d{2})T', filename)
    if match:
        year, month, day = match.groups()
        return int(year + month + day)

    # Pattern 3: 20250919_2015_xxx.mp4 -> 20250919
    match = re.search(r'^(\d{8})_', filename)
    if match:
        return int(match.group(1))

    return None

def should_keep_video(filename, cutoff_date):
    """
    Returns True if video should be kept (date < cutoff), False otherwise.
    """
    date = extract_date_from_filename(filename)
    if date is None:
        # If we can't determine date, keep it (safer)
        print(f"  ⚠️  Could not extract date from: {filename} - KEEPING")
        return True

    return date < cutoff_date

def clean_shot_file(filepath):
    """
    Remove videos >= cutoff date from all variants in a shot file.
    Returns (total_videos_before, total_videos_after, removed_count)
    """
    with open(filepath, 'r') as f:
        data = json.load(f)

    if 'prompt_variants' not in data:
        return (0, 0, 0)

    total_before = 0
    total_after = 0
    removed = 0

    for variant in data['prompt_variants']:
        if 'videos' not in variant:
            continue

        videos_before = len(variant['videos'])
        total_before += videos_before

        # Filter videos
        kept_videos = [
            video for video in variant['videos']
            if should_keep_video(video.get('filename', ''), CUTOFF_DATE)
        ]

        videos_after = len(kept_videos)
        total_after += videos_after
        removed += (videos_before - videos_after)

        # Update variant
        variant['videos'] = kept_videos

        # Reset active_video_index if needed
        if videos_after == 0:
            variant['active_video_index'] = 0
        elif variant.get('active_video_index', 0) >= videos_after:
            variant['active_video_index'] = max(0, videos_after - 1)

    # Save updated file
    with open(filepath, 'w') as f:
        json.dump(data, f, indent=2)

    return (total_before, total_after, removed)

def main():
    shots_dir = Path('/Users/ingthor/Documents/stories/appdata/json/7/shots')

    # Find all JSON files
    json_files = list(shots_dir.rglob('*.json'))
    print(f"Found {len(json_files)} JSON files to process\n")

    total_videos_before = 0
    total_videos_after = 0
    total_removed = 0
    files_modified = 0

    for json_file in json_files:
        before, after, removed = clean_shot_file(json_file)

        if removed > 0:
            files_modified += 1
            print(f"✂️  {json_file.name}")
            print(f"    Before: {before} videos | After: {after} videos | Removed: {removed}")

        total_videos_before += before
        total_videos_after += after
        total_removed += removed

    print(f"\n{'='*60}")
    print(f"CLEANUP COMPLETE")
    print(f"{'='*60}")
    print(f"Files processed:  {len(json_files)}")
    print(f"Files modified:   {files_modified}")
    print(f"Videos before:    {total_videos_before}")
    print(f"Videos after:     {total_videos_after}")
    print(f"Videos removed:   {total_removed}")
    print(f"{'='*60}\n")

if __name__ == '__main__':
    main()
