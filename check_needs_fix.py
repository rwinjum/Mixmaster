import csv

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

needs_fix = []
already_fixed = []

with open('BW26-withallcorrectMETA.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        track = row['Track Name'].lower()
        current_date = row['Release Date']
        current_year = current_date.split('-')[0]
        
        for song_pattern, correct_date in corrections.items():
            pattern_lower = song_pattern.lower()
            if pattern_lower in track:
                correct_year = correct_date.split('-')[0]
                if current_year != correct_year:
                    needs_fix.append({
                        'song': row['Track Name'],
                        'current': current_date,
                        'correct': correct_date,
                        'album': row['Album Name']
                    })
                else:
                    already_fixed.append(row['Track Name'])
                break

print(f"NEEDS FIXING: {len(needs_fix)} songs")
print("=" * 80)
for item in needs_fix[:15]:  # Show first 15
    print(f"❌ {item['song']}")
    print(f"   Current: {item['current']} | Should be: {item['correct']}")
    print(f"   Album: {item['album']}")
    print()

if len(needs_fix) > 15:
    print(f"... and {len(needs_fix) - 15} more")

print(f"\nALREADY FIXED: {len(already_fixed)} songs")
for song in already_fixed[:5]:
    print(f"  ✓ {song}")
if len(already_fixed) > 5:
    print(f"  ... and {len(already_fixed) - 5} more")
