#!/usr/bin/env python3
"""
Corrections for compilation albums - maps to original release dates
"""

# Song corrections: (track_name, album_name) -> original_release_date
ORIGINAL_DATES = {
    # Format: ("Track Name", "Album Pattern") -> "YYYY-MM-DD"
    ("(Marie's The Name) His Latest Flame", "Elvis 30 #1 Hits"): "1961-08-08",
    ("Southbound", "Brothers And Sisters (Deluxe"): "1973-08-15",
    ("Hold Me, Thrill Me, Kiss Me, Kill Me - Filtered", "The Best Of 1990-2000"): "1995-06-05",
    ("American Girl", "Greatest Hits"): "1976-09-14",
    ("Drown", "(Rotten Apples) The Smashing Pumpki"): "1995-10-23",
    ("Ocean Size - 2006 Remaster", "Up from the Catacombs"): "1989-09-07",
    ("Harborcoat - Live At The Olympia Dublin", "Complete Rarities"): "1983-01-01",
    ("We Walk - Live/Remastered", "Complete Rarities"): "1985-01-01",
    ("Boulevard of Broken Dreams", "American Idiot (20th Anniversary"): "2004-11-01",
    ("Dancing Days - 2019 Remaster", "Purple (Super Deluxe"): "1971-11-08",
    ("All Your Lies", "Ultramega OK (Expanded"): "1988-06-09",
    ("Mood for Trouble", "Ultramega OK (Expanded"): "1988-06-09",
    ("Flower", "Ultramega OK (Expanded"): "1988-06-09",
    ("Losing My Religion - Live", "R.E.M. Live"): "1991-01-01",
    ("Wait for Me", "Mechanical Bull (Expanded"): "2012-09-18",
    ("The Boy", "Aeroplane Flies High (Deluxe"): "1998-01-01",
    ("Invisible Sun", "Why Me? Why Not. (Deluxe"): "2019-09-20",
    ("As Alive As You Need Me To Be", "As Alive As You Need Me To Be"): "2025-07-17",
    ("Everywhere I Go - Remastered", "Reconciled & Into The Woods"): "2016-04-08",
    ("Who Are You", "Who Are You (Super Deluxe"): "1978-12-18",
    ("Acquiesce - Live from Wembley", "Acquiesce (Live from Wembley"): "1996-10-07",
    ("The Underdog", "Ga Ga Ga Ga Ga (2017"): "2007-04-10",
    ("Hands All Over", "Chris Cornell (Deluxe"): "1989-01-24",
    ("Comfortably Numb - Live from the Luck", "The Luck and Strange Concerts"): "1979-11-30",
    ("More Than This", "Roxy Music Collection"): "1982-05-01",
    ("Everybody Wants You", "Absolute Hits"): "1982-07-23",
    ("Crown of Thorns", "On Earth As It Is"): "1989-03-20",
}

import csv
import sys

def fix_original_dates(input_csv, output_csv=None):
    """Fix compilation album dates to original release dates"""
    
    if output_csv is None:
        output_csv = input_csv.replace('.csv', '-corrected.csv')
    
    corrections_made = 0
    
    with open(input_csv, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        rows = list(reader)
    
    print("🔧 FIXING ORIGINAL RELEASE DATES")
    print("=" * 80)
    
    for row in rows:
        track = row['Track Name'].strip('"')
        album = row['Album Name'].strip('"')
        original_date = row['Release Date']
        
        # Check for matches
        for (track_pattern, album_pattern), correct_date in ORIGINAL_DATES.items():
            if track_pattern.lower() in track.lower() and album_pattern.lower() in album.lower():
                row['Release Date'] = correct_date
                corrections_made += 1
                print(f"✓ {track}")
                print(f"  {original_date} → {correct_date}")
                break
    
    # Write corrected CSV
    with open(output_csv, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    
    print("=" * 80)
    print(f"\nFixed {corrections_made} songs")
    print(f"Saved to: {output_csv}\n")
    
    return corrections_made

if __name__ == '__main__':
    input_file = sys.argv[1] if len(sys.argv) > 1 else 'BW26-withallcorrectMETA.csv'
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    fix_original_dates(input_file, output_file)
