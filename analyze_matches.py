import csv

# Exact corrections database from HTML
corrections = {
    "(Marie's The Name) His Latest Flame": "1961-08-08",
    "Southbound": "1973-08-15",
    "Hold Me, Thrill Me, Kiss Me, Kill Me": "1995-06-05",
    "American Girl": "1976-09-14",
    "Drown": "1995-10-23",
    "Ocean Size": "1989-09-07",
    "Harborcoat": "1983-01-01",
    "We Walk": "1985-01-01",
    "Boulevard of Broken Dreams": "2004-11-01",
    "Dancing Days": "1971-11-08",
    "All Your Lies": "1988-06-09",
    "Mood for Trouble": "1988-06-09",
    "Losing My Religion": "1991-01-01",
    "Wait for Me": "2012-09-18",
    "The Boy": "1998-01-01",
    "Invisible Sun": "2019-09-20",
    "As Alive As You Need Me To Be": "2025-07-17",
    "Everywhere I Go": "2016-04-08",
    "Who Are You": "1978-12-18",
    "Acquiesce": "1996-10-07",
    "The Underdog": "2007-04-10",
    "Hands All Over": "1989-01-24",
    "Flower": "1988-06-09",
    "Comfortably Numb": "1979-11-30",
    "More Than This": "1982-05-01",
    "Everybody Wants You": "1982-07-23",
    "Crown of Thorns": "1989-03-20"
}

print("Checking which correction songs are in the CSV:\n")
found_count = 0
not_found = []

with open('BW26-withallcorrectMETA.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        track = row['Track Name'].lower() if row['Track Name'] else ''
        
        for song_pattern in corrections.keys():
            pattern_lower = song_pattern.lower()
            if pattern_lower in track:
                found_count += 1
                print(f"✓ Found: '{song_pattern}'")
                print(f"  Actual in CSV: '{row['Track Name']}'")
                print()
                break
        else:
            # Check if this was one we haven't found yet
            if any(correction.lower() not in track for correction in corrections.keys()):
                pass

print(f"\n--- SUMMARY ---")
print(f"Songs found from corrections database: {found_count}")
print(f"Total correction patterns: {len(corrections)}")
print(f"Missing from CSV:")

# Find which ones we didn't find
found_songs = set()
with open('BW26-withallcorrectMETA.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    all_tracks = [row['Track Name'].lower() for row in reader]

for song_pattern in corrections.keys():
    pattern_lower = song_pattern.lower()
    if not any(pattern_lower in track for track in all_tracks):
        print(f"  ✗ {song_pattern}")
