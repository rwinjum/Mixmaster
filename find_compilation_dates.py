#!/usr/bin/env python3
"""
Find compilation albums and re-releases with wrong dates
"""

import csv
import json

# Read the CSV
with open('BW26-withallcorrectMETA.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    rows = list(reader)

print("🔍 IDENTIFYING COMPILATION ALBUMS & RE-RELEASES")
print("=" * 90)

suspicious = []
for row in rows:
    track = row.get('Track Name', '').strip('"')
    album = row.get('Album Name', '').strip('"')
    date_str = row.get('Release Date', '')
    
    # Flag albums that look like compilations
    keywords = ['greatest hits', '#1 hits', 'anthology', 'deluxe edition', 'remaster', 
                'expanded', 'compilation', 'best of', 'super hits', 'rarities', 'live', 'expanded edition']
    
    if any(keyword in album.lower() for keyword in keywords):
        try:
            year = int(date_str.split('-')[0])
            if year > 2000:  # Compilation released recently
                suspicious.append({
                    'Track': track,
                    'Album': album,
                    'Album Release Date': date_str,
                })
        except:
            pass

print(f"\nFound {len(suspicious)} suspicious compilation/re-release albums:\n")
for i, item in enumerate(suspicious[:30], 1):
    print(f"{i:2}. {item['Track'][:40]:40} | {item['Album'][:35]:35} | {item['Album Release Date']}")

if len(suspicious) > 30:
    print(f"\n... and {len(suspicious) - 30} more")

print("=" * 90)
print(f"\n✅ Total: {len(suspicious)} songs need original release date correction\n")

# Save to JSON for reference
with open('compilation_albums.json', 'w') as f:
    json.dump(suspicious, f, indent=2)
    
print("💾 Saved to compilation_albums.json for reference")
