#!/usr/bin/env python3
"""
MIXMASTER CSV Cleanup Utility
Validates and auto-corrects common data quality issues in Spotify playlist CSVs
"""

import csv
import os
import sys
from datetime import datetime
from pathlib import Path


def predict_genre_from_features(row):
    """Predict genre from audio features when genre is empty"""
    try:
        energy = float(row.get('Energy', 0))
        danceability = float(row.get('Danceability', 0))
        tempo = float(row.get('Tempo', 0))
        acousticness = float(row.get('Acousticness', 0))
        instrumentalness = float(row.get('Instrumentalness', 0))
        valence = float(row.get('Valence', 0))
        speechiness = float(row.get('Speechiness', 0))
    except (ValueError, TypeError):
        return 'Pop'  # Fallback if features are missing
    
    # High speechiness -> Hip Hop/Rap
    if speechiness > 0.4:
        return 'Hip Hop/Rap'
    
    # Very acoustic -> Folk/Singer-Songwriter
    if acousticness > 0.7 and tempo < 110:
        return 'Folk'
    
    # High instrumentalness -> Instrumental/Ambient
    if instrumentalness > 0.6:
        return 'Instrumental'
    
    # High energy + high tempo + high danceability -> Dance/Electronic
    if energy > 0.7 and danceability > 0.7 and tempo > 120:
        return 'Electronic'
    
    # High energy + high tempo -> Rock
    if energy > 0.7 and tempo > 130:
        return 'Rock/Alternative'
    
    # High danceability -> Pop/Dance
    if danceability > 0.7 and energy > 0.5:
        return 'Pop/Dance'
    
    # High valence (positive) + mid tempo -> Pop
    if valence > 0.7 and danceability > 0.5:
        return 'Pop'
    
    # Slow + acoustic + low valence -> Blues/Soul
    if tempo < 100 and acousticness > 0.4 and valence < 0.4:
        return 'R&B/Soul'
    
    # Default based on energy
    if energy > 0.6:
        return 'Pop'
    if energy < 0.3:
        return 'Singer-Songwriter'
    
    return 'Pop'


def parse_date(date_str):
    """Parse various date formats and return YYYY-MM-DD"""
    if not date_str or date_str.strip() == '':
        return None
    
    date_str = date_str.strip().strip('"')
    
    # Try YYYY-MM-DD format
    try:
        dt = datetime.strptime(date_str, '%Y-%m-%d')
        return dt.strftime('%Y-%m-%d')
    except ValueError:
        pass
    
    # Try MM/DD/YYYY format
    try:
        dt = datetime.strptime(date_str, '%m/%d/%Y')
        return dt.strftime('%Y-%m-%d')
    except ValueError:
        pass
    
    # Try MM/DD/YY format (with 2-digit year conversion)
    try:
        dt = datetime.strptime(date_str, '%m/%d/%y')
        year = dt.year
        # Convert 2-digit years: 00-30 -> 2000s, 31-99 -> 1900s
        if year > 2030:
            year = year - 100
        return datetime(year, dt.month, dt.day).strftime('%Y-%m-%d')
    except ValueError:
        pass
    
    # Try YYYY only (just the year)
    try:
        year = int(date_str)
        if 1900 <= year <= 2100:
            return f'{year}-01-01'
    except ValueError:
        pass
    
    return None


def validate_audio_features(row, issues):
    """Validate audio features are in valid range (0-1)"""
    feature_fields = [
        'Danceability', 'Energy', 'Acousticness', 'Instrumentalness',
        'Liveness', 'Speechiness', 'Valence'
    ]
    
    for field in feature_fields:
        if field not in row:
            continue
        try:
            value = float(row[field])
            if value < 0 or value > 1:
                issues.append(f"  ⚠ {field}: {value} (should be 0-1)")
                return True
        except (ValueError, TypeError):
            pass
    
    return False


def cleanup_csv(input_file, output_file=None, auto_correct=True):
    """
    Validate and optionally auto-correct CSV file
    
    Args:
        input_file: Path to input CSV
        output_file: Path to output CSV (defaults to input_file-cleaned.csv)
        auto_correct: Whether to auto-correct issues
    
    Returns:
        Dictionary with statistics about issues found and corrected
    """
    
    if not os.path.exists(input_file):
        print(f"❌ File not found: {input_file}")
        return None
    
    if output_file is None:
        base_name = input_file.replace('.csv', '').replace('.CSV', '')
        output_file = f"{base_name}-cleaned.csv"
    
    stats = {
        'total_rows': 0,
        'empty_genres': 0,
        'empty_genres_corrected': 0,
        'date_format_issues': 0,
        'date_format_corrected': 0,
        'feature_range_issues': 0,
        'all_issues': []
    }
    
    try:
        # Read the CSV
        with open(input_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            if reader.fieldnames is None:
                print("❌ Error: CSV file is empty or invalid")
                return None
            
            rows = list(reader)
        
        stats['total_rows'] = len(rows)
        corrected_rows = []
        
        print(f"\n📊 Scanning {len(rows)} rows...")
        
        for i, row in enumerate(rows, 1):
            original_row = row.copy()
            issues = [f"Row {i}: {row.get('Title', 'Unknown')}"]
            has_issues = False
            
            # Check for empty genres
            genre = row.get('Genres', row.get('Genre', '')).strip().strip('"')
            if not genre or genre.lower() == '""':
                has_issues = True
                stats['empty_genres'] += 1
                issues.append("  ❌ Empty genre")
                
                if auto_correct:
                    predicted = predict_genre_from_features(row)
                    row['Genres'] = predicted
                    row['Genre'] = predicted
                    stats['empty_genres_corrected'] += 1
                    issues[-1] = f"  ✓ Empty genre → Predicted: {predicted}"
            
            # Check date format
            date_field = row.get('Release Date', row.get('Date', ''))
            if date_field:
                parsed_date = parse_date(date_field)
                if parsed_date != date_field and parsed_date is not None:
                    has_issues = True
                    stats['date_format_issues'] += 1
                    issues.append(f"  ❌ Date format: {date_field} → {parsed_date}")
                    
                    if auto_correct:
                        row['Release Date'] = parsed_date
                        if 'Date' in row:
                            row['Date'] = parsed_date
                        stats['date_format_corrected'] += 1
                        issues[-1] = f"  ✓ Date format: {date_field} → {parsed_date}"
            
            # Check audio features
            if validate_audio_features(row, issues):
                has_issues = True
                stats['feature_range_issues'] += 1
            
            if has_issues:
                stats['all_issues'].append('\n'.join(issues))
            
            corrected_rows.append(row)
        
        # Write corrected CSV if auto_correct is enabled
        if auto_correct and corrected_rows:
            # Use the original fieldnames but filter to only valid ones
            if reader.fieldnames:
                # Get all unique fieldnames from corrected_rows
                all_fieldnames = set(reader.fieldnames)
                for row in corrected_rows:
                    all_fieldnames.update(row.keys())
                fieldnames = list(all_fieldnames)
                
                with open(output_file, 'w', newline='', encoding='utf-8') as f:
                    writer = csv.DictWriter(f, fieldnames=fieldnames)
                    writer.writeheader()
                    writer.writerows(corrected_rows)
            
            print(f"✅ Cleaned CSV saved to: {output_file}")
        
        # Print summary
        print("\n" + "="*60)
        print("📋 CLEANUP REPORT")
        print("="*60)
        print(f"Total rows scanned: {stats['total_rows']}")
        print(f"Empty genres found: {stats['empty_genres']}")
        if auto_correct:
            print(f"  → Auto-corrected: {stats['empty_genres_corrected']}")
        print(f"Date format issues: {stats['date_format_issues']}")
        if auto_correct:
            print(f"  → Auto-corrected: {stats['date_format_corrected']}")
        print(f"Audio feature range issues: {stats['feature_range_issues']}")
        
        if stats['all_issues']:
            print("\n⚠️  ISSUES FOUND:")
            for issue in stats['all_issues'][:10]:  # Show first 10
                print(issue)
            if len(stats['all_issues']) > 10:
                print(f"\n... and {len(stats['all_issues']) - 10} more issues")
        else:
            print("\n✅ No issues found! CSV is clean.")
        
        print("="*60 + "\n")
        
        return stats
        
    except Exception as e:
        print(f"❌ Error processing file: {e}")
        return None


def main():
    """Command-line interface"""
    if len(sys.argv) < 2:
        print("MIXMASTER CSV Cleanup Utility")
        print("\nUsage:")
        print("  python csv_cleanup.py <input_file.csv> [output_file.csv]")
        print("\nExample:")
        print("  python csv_cleanup.py boys_weekend_2025.csv boys_weekend_2025-cleaned.csv")
        print("\nFeatures:")
        print("  • Detects and auto-corrects empty genres (using audio feature prediction)")
        print("  • Normalizes date formats (MM/DD/YY, MM/DD/YYYY, YYYY-MM-DD)")
        print("  • Validates audio features are in range (0-1)")
        print("  • Generates cleaned CSV ready for MIXMASTER")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    cleanup_csv(input_file, output_file, auto_correct=True)


if __name__ == '__main__':
    main()
