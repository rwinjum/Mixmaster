#!/usr/bin/env python3
"""
Enrich BW26 CSV with Spotify audio features
"""

import csv
import requests
import os
import sys

SPOTIFY_CLIENT_ID = os.getenv('SPOTIFY_CLIENT_ID', '3afa78aa7f0746649c89fc8ac1955048')
SPOTIFY_CLIENT_SECRET = os.getenv('SPOTIFY_CLIENT_SECRET', 'db3c2a12e93249faa7649c0f5fa73b05')

def get_spotify_access_token():
    """Get Spotify API access token"""
    auth_url = 'https://accounts.spotify.com/api/token'
    auth_data = {
        'grant_type': 'client_credentials',
        'client_id': SPOTIFY_CLIENT_ID,
        'client_secret': SPOTIFY_CLIENT_SECRET
    }
    
    response = requests.post(auth_url, data=auth_data, timeout=10)
    if response.status_code != 200:
        raise Exception(f"Failed to authenticate with Spotify: {response.status_code}")
    
    return response.json()['access_token']

def fetch_audio_features(track_ids, token):
    """Fetch audio features for multiple tracks"""
    headers = {'Authorization': f'Bearer {token}'}
    features_dict = {}
    
    # Spotify allows max 100 IDs per request
    for i in range(0, len(track_ids), 100):
        batch = track_ids[i:i+100]
        batch = [tid for tid in batch if tid]  # Filter out None/empty
        
        if not batch:
            continue
            
        url = f'https://api.spotify.com/v1/audio-features?ids={",".join(batch)}'
        response = requests.get(url, headers=headers, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            for feature in data.get('audio_features', []):
                if feature:
                    features_dict[feature['id']] = feature
        else:
            print(f"Warning: Batch {i//100 + 1} failed: {response.status_code}")
            print(f"Response: {response.text[:200]}")
    
    return features_dict

def enrich_csv(input_file, output_file):
    """Read CSV, fetch audio features, write enriched CSV"""
    
    print(f"📖 Reading {input_file}...")
    rows = []
    spotify_ids = []
    
    with open(input_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(row)
            spotify_id = row.get('Spotify - id', '').strip()
            if spotify_id:
                spotify_ids.append(spotify_id)
    
    print(f"✅ Found {len(rows)} tracks with {len(spotify_ids)} Spotify IDs")
    
    print("🔐 Authenticating with Spotify...")
    token = get_spotify_access_token()
    
    print("🎵 Fetching audio features...")
    audio_features = fetch_audio_features(spotify_ids, token)
    
    print(f"✅ Retrieved features for {len(audio_features)} tracks")
    
    # Audio feature column names
    audio_cols = [
        'Danceability', 'Energy', 'Key', 'Loudness', 'Mode',
        'Speechiness', 'Acousticness', 'Instrumentalness', 'Liveness',
        'Valence', 'Tempo', 'Time Signature'
    ]
    
    # Prepare output data
    output_rows = []
    fieldnames = list(rows[0].keys()) + audio_cols
    
    for row in rows:
        spotify_id = row.get('Spotify - id', '').strip()
        
        if spotify_id and spotify_id in audio_features:
            features = audio_features[spotify_id]
            row['Danceability'] = features.get('danceability', '')
            row['Energy'] = features.get('energy', '')
            row['Key'] = features.get('key', '')
            row['Loudness'] = features.get('loudness', '')
            row['Mode'] = features.get('mode', '')
            row['Speechiness'] = features.get('speechiness', '')
            row['Acousticness'] = features.get('acousticness', '')
            row['Instrumentalness'] = features.get('instrumentalness', '')
            row['Liveness'] = features.get('liveness', '')
            row['Valence'] = features.get('valence', '')
            row['Tempo'] = features.get('tempo', '')
            row['Time Signature'] = features.get('time_signature', '')
        else:
            # Add empty columns for tracks without features
            for col in audio_cols:
                row[col] = ''
        
        output_rows.append(row)
    
    print(f"💾 Writing enriched CSV to {output_file}...")
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(output_rows)
    
    print(f"✅ Success! Enriched CSV saved to {output_file}")
    print(f"   Total tracks: {len(output_rows)}")
    print(f"   Tracks with audio features: {len(audio_features)}")

if __name__ == '__main__':
    input_file = 'BW26-4.csv'
    output_file = 'BW26-enriched.csv'
    
    try:
        enrich_csv(input_file, output_file)
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
