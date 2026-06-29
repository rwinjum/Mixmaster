#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Flask proxy server for Ollama local LLM and Spotify API
Bypasses CORS issues for local development
"""

from flask import Flask, request, jsonify, session, redirect, url_for
import requests
import os
import json
import csv
import io
import base64
import ssl
import sys
from urllib.parse import urlencode

# Force UTF-8 output on Windows
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

app = Flask(__name__)
app.secret_key = 'mixmaster-dev-secret-key'  # For session management
app.config['PREFERRED_URL_SCHEME'] = 'https'  # Force HTTPS in url_for()

# Ollama API configuration (default local port)
OLLAMA_API_URL = 'http://localhost:11434/api/generate'
OLLAMA_MODEL = 'llama2'  # Default model, can be changed to mistral, neural-chat, etc.

# Spotify API configuration - Load from environment variables
SPOTIFY_CLIENT_ID = os.getenv('SPOTIFY_CLIENT_ID', '')
SPOTIFY_CLIENT_SECRET = os.getenv('SPOTIFY_CLIENT_SECRET', '')
# Use localhost.run for HTTPS, or set SPOTIFY_REDIRECT_URI env var for custom URL
SPOTIFY_REDIRECT_URI = os.getenv('SPOTIFY_REDIRECT_URI', 'http://localhost:5000/api/spotify-callback')

# Enable CORS with credentials support
from flask_cors import CORS
CORS(app, 
     resources={r"/api/*": {"origins": ["http://localhost:8000", "http://localhost:5000", "https://6eea51a564e14f.lhr.life"], "supports_credentials": True}},
     support_credentials=True)

# Spotify Helper Functions
def get_spotify_access_token():
    """Get Spotify API access token using Client Credentials flow"""
    if not SPOTIFY_CLIENT_ID or not SPOTIFY_CLIENT_SECRET:
        raise ValueError("Spotify credentials not configured. Set SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET environment variables.")
    
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

def get_spotify_user_token_from_session():
    """Get user access token from session (for OAuth)"""
    return session.get('spotify_access_token')

def refresh_spotify_user_token():
    """Refresh user access token if expired"""
    refresh_token = session.get('spotify_refresh_token')
    if not refresh_token:
        return None
    
    auth_url = 'https://accounts.spotify.com/api/token'
    auth_data = {
        'grant_type': 'refresh_token',
        'refresh_token': refresh_token,
        'client_id': SPOTIFY_CLIENT_ID,
        'client_secret': SPOTIFY_CLIENT_SECRET
    }
    
    response = requests.post(auth_url, data=auth_data, timeout=10)
    if response.status_code == 200:
        data = response.json()
        session['spotify_access_token'] = data['access_token']
        return data['access_token']
    
    return None

def fetch_spotify_playlist(playlist_id):
    """Fetch playlist data from Spotify"""
    token = get_spotify_access_token()
    headers = {'Authorization': f'Bearer {token}'}
    
    playlist_url = f'https://api.spotify.com/v1/playlists/{playlist_id}'
    response = requests.get(playlist_url, headers=headers, timeout=10)
    
    if response.status_code != 200:
        raise Exception(f"Failed to fetch playlist: {response.status_code} - {response.text}")
    
    return response.json()

def fetch_playlist_tracks(playlist_id):
    """Fetch all tracks from a Spotify playlist with pagination"""
    token = get_spotify_access_token()
    headers = {'Authorization': f'Bearer {token}'}
    
    all_tracks = []
    url = f'https://api.spotify.com/v1/playlists/{playlist_id}/tracks'
    
    while url:
        response = requests.get(url, headers=headers, timeout=10)
        if response.status_code == 403:
            raise Exception("Access denied: Playlist is private or not accessible. Only public playlists can be imported with current authentication.")
        elif response.status_code != 200:
            raise Exception(f"Failed to fetch tracks: {response.status_code} - {response.text}")
        
        data = response.json()
        all_tracks.extend(data.get('items', []))
        url = data.get('next')  # Get next page URL if exists
    
    return all_tracks

def fetch_playlist_tracks_public(playlist_id):
    """Fetch tracks from a public Spotify playlist using field filtering"""
    token = get_spotify_access_token()
    headers = {'Authorization': f'Bearer {token}'}
    
    all_tracks = []
    url = f'https://api.spotify.com/v1/playlists/{playlist_id}/tracks'
    
    while url:
        # Add fields parameter to minimize response size and avoid 403
        params = {
            'fields': 'items(track(id,name,artists,album,uri,external_urls)),next',
            'limit': 50
        }
        response = requests.get(url, headers=headers, params=params, timeout=10)
        
        if response.status_code == 403:
            raise Exception("Playlist is private. Client Credentials can only access public playlists.")
        elif response.status_code != 200:
            print(f"Response: {response.status_code} - {response.text}")
            raise Exception(f"Failed to fetch tracks: {response.status_code}")
        
        data = response.json()
        all_tracks.extend(data.get('items', []))
        url = data.get('next')
    
    return all_tracks

def fetch_track_audio_features(track_ids):
    """Fetch audio features for multiple tracks"""
    token = get_spotify_access_token()
    headers = {'Authorization': f'Bearer {token}'}
    
    # Spotify API allows max 100 IDs per request
    all_features = {}
    for i in range(0, len(track_ids), 100):
        batch = track_ids[i:i+100]
        url = f'https://api.spotify.com/v1/audio-features?ids={",".join(batch)}'
        
        response = requests.get(url, headers=headers, timeout=10)
        if response.status_code != 200:
            print(f"Warning: Could not fetch audio features for batch {i//100 + 1}")
            continue
        
        data = response.json()
        for feature in data.get('audio_features', []):
            if feature:
                all_features[feature['id']] = feature
    
    return all_features

def fetch_playlist_tracks_user(playlist_id, access_token):
    """Fetch all tracks from a Spotify playlist with user authorization"""
    headers = {'Authorization': f'Bearer {access_token}'}
    
    all_tracks = []
    url = f'https://api.spotify.com/v1/playlists/{playlist_id}/tracks'
    
    while url:
        response = requests.get(url, headers=headers, timeout=10)
        if response.status_code == 403:
            raise Exception("Access denied: Unable to fetch playlist tracks. Ensure you're logged in with the correct Spotify account.")
        elif response.status_code != 200:
            raise Exception(f"Failed to fetch tracks: {response.status_code} - {response.text}")
        
        data = response.json()
        all_tracks.extend(data.get('items', []))
        url = data.get('next')  # Get next page URL if exists
    
    return all_tracks

def fetch_track_audio_features_user(track_ids, access_token):
    """Fetch audio features for multiple tracks with user authorization"""
    headers = {'Authorization': f'Bearer {access_token}'}
    
    # Spotify API allows max 100 IDs per request
    all_features = {}
    for i in range(0, len(track_ids), 100):
        batch = track_ids[i:i+100]
        url = f'https://api.spotify.com/v1/audio-features?ids={",".join(batch)}'
        
        response = requests.get(url, headers=headers, timeout=10)
        if response.status_code != 200:
            print(f"Warning: Could not fetch audio features for batch {i//100 + 1}")
            continue
        
        data = response.json()
        for feature in data.get('audio_features', []):
            if feature:
                all_features[feature['id']] = feature
    
    return all_features
    
    return all_features

def convert_to_csv(tracks, audio_features):
    """Convert Spotify playlist data to CSV format"""
    output = io.StringIO()
    writer = csv.writer(output)
    
    # Write header
    writer.writerow([
        'Track URI', 'Track Name', 'Album Name', 'Artist Name(s)', 'Release Date',
        'Duration (ms)', 'Popularity', 'Explicit', 'Genres', 'Danceability', 'Energy',
        'Key', 'Loudness', 'Mode', 'Speechiness', 'Acousticness', 'Instrumentalness',
        'Liveness', 'Valence', 'Tempo', 'Time Signature'
    ])
    
    # Write tracks
    for track_item in tracks:
        track = track_item.get('track')
        if not track:
            continue
        
        track_id = track.get('id', '')
        features = audio_features.get(track_id, {})
        
        # Extract genres from all artists
        artists = track.get('artists', [])
        artist_names = ', '.join([a.get('name', '') for a in artists])
        
        # Get artist genres (if available)
        artist_genres = []
        for artist in artists:
            if 'genres' in artist:
                artist_genres.extend(artist.get('genres', []))
        
        genres_str = ', '.join(list(dict.fromkeys(artist_genres)))  # Remove duplicates
        
        writer.writerow([
            track.get('uri', ''),
            track.get('name', ''),
            track.get('album', {}).get('name', ''),
            artist_names,
            track.get('album', {}).get('release_date', ''),
            track.get('duration_ms', 0),
            track.get('popularity', 0),
            str(track.get('explicit', False)).lower(),
            genres_str,
            round(features.get('danceability', 0), 3),
            round(features.get('energy', 0), 3),
            features.get('key', 0),
            round(features.get('loudness', 0), 3),
            features.get('mode', 0),
            round(features.get('speechiness', 0), 3),
            round(features.get('acousticness', 0), 3),
            round(features.get('instrumentalness', 0), 6),
            round(features.get('liveness', 0), 3),
            round(features.get('valence', 0), 3),
            round(features.get('tempo', 0), 3),
            features.get('time_signature', 4)
        ])
    
    return output.getvalue()

@app.route('/api/spotify-playlist', methods=['POST'])
def spotify_playlist():
    """Fetch Spotify playlist and convert to CSV using user authorization"""
    try:
        data = request.get_json()
        playlist_id = data.get('playlist_id')
        
        if not playlist_id:
            return jsonify({'success': False, 'error': 'No playlist ID provided'}), 400
        
        # Get user's access token from session
        access_token = get_spotify_user_token_from_session()
        if not access_token:
            # No user auth, return auth URL
            return jsonify({
                'success': False, 
                'error': 'User authentication required',
                'auth_url': url_for('spotify_login', _external=True, next_playlist=playlist_id)
            }), 401
        
        headers = {'Authorization': f'Bearer {access_token}'}
        
        # Fetch playlist info
        print(f"Fetching playlist: {playlist_id}")
        playlist_url = f'https://api.spotify.com/v1/playlists/{playlist_id}'
        response = requests.get(playlist_url, headers=headers, timeout=10)
        
        if response.status_code == 401:
            # Token expired, try to refresh
            access_token = refresh_spotify_user_token()
            if not access_token:
                return jsonify({'success': False, 'error': 'Session expired. Please login again.'}), 401
            headers['Authorization'] = f'Bearer {access_token}'
            response = requests.get(playlist_url, headers=headers, timeout=10)
        
        if response.status_code != 200:
            return jsonify({'success': False, 'error': f"Failed to fetch playlist: {response.status_code}"}), 400
        
        playlist = response.json()
        
        # Fetch all tracks
        print("Fetching playlist tracks...")
        tracks = fetch_playlist_tracks_user(playlist_id, access_token)
        print(f"Found {len(tracks)} tracks")
        
        # Extract track IDs for audio features
        track_ids = [t.get('track', {}).get('id') for t in tracks if t.get('track')]
        track_ids = [tid for tid in track_ids if tid]  # Remove None values
        
        # Fetch audio features
        print("Fetching audio features...")
        audio_features = fetch_track_audio_features_user(track_ids, access_token)
        
        # Convert to CSV
        csv_data = convert_to_csv(tracks, audio_features)
        
        return jsonify({
            'success': True,
            'playlist_name': playlist.get('name', 'Playlist'),
            'track_count': len(tracks),
            'csv_data': csv_data
        })
    
    except Exception as e:
        print(f"Error fetching Spotify playlist: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/spotify-playlist-public', methods=['POST'])
def spotify_playlist_public():
    """Fetch public Spotify playlist and convert to CSV using Client Credentials"""
    try:
        data = request.get_json()
        playlist_id = data.get('playlist_id')
        
        if not playlist_id:
            return jsonify({'success': False, 'error': 'No playlist ID provided'}), 400
        
        print(f"📥 Fetching public playlist: {playlist_id}")
        
        # Fetch playlist info with Client Credentials
        token = get_spotify_access_token()
        headers = {'Authorization': f'Bearer {token}'}
        
        playlist_url = f'https://api.spotify.com/v1/playlists/{playlist_id}'
        response = requests.get(playlist_url, headers=headers, timeout=10)
        
        if response.status_code != 200:
            return jsonify({'success': False, 'error': f"Failed to fetch playlist: {response.status_code}. Playlist may be private."}), 400
        
        playlist = response.json()
        
        # Fetch all tracks using public method
        print("📋 Fetching playlist tracks...")
        tracks = fetch_playlist_tracks_public(playlist_id)
        print(f"✅ Found {len(tracks)} tracks")
        
        # Extract track IDs for audio features
        track_ids = [t.get('track', {}).get('id') for t in tracks if t.get('track')]
        track_ids = [tid for tid in track_ids if tid]  # Remove None values
        
        if track_ids:
            # Fetch audio features
            print("🎵 Fetching audio features...")
            audio_features = fetch_track_audio_features(track_ids)
        else:
            audio_features = {}
        
        # Convert to CSV
        csv_data = convert_to_csv(tracks, audio_features)
        
        return jsonify({
            'success': True,
            'playlist_name': playlist.get('name', 'Playlist'),
            'track_count': len(tracks),
            'csv_data': csv_data
        })
    
    except Exception as e:
        print(f"❌ Error fetching public playlist: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/spotify-login', methods=['GET'])
def spotify_login():
    """Redirect user to Spotify login"""
    if not SPOTIFY_CLIENT_ID:
        return jsonify({'error': 'Spotify not configured'}), 500
    
    auth_url = 'https://accounts.spotify.com/authorize'
    params = {
        'client_id': SPOTIFY_CLIENT_ID,
        'response_type': 'code',
        'redirect_uri': SPOTIFY_REDIRECT_URI,
        'scope': 'playlist-read-public playlist-read-private',
        'state': os.urandom(16).hex()
    }
    
    session['spotify_state'] = params['state']
    return redirect(f"{auth_url}?{urlencode(params)}")

@app.route('/api/spotify-callback', methods=['GET'])
def spotify_callback():
    """Handle Spotify OAuth callback"""
    print(f"📍 Callback received | Protocol: {request.scheme} | Host: {request.host}")
    code = request.args.get('code')
    state = request.args.get('state')
    error = request.args.get('error')
    
    # Log any Spotify errors
    if error:
        print(f"❌ Spotify error: {error}")
        return jsonify({'error': f'Spotify error: {error}'}), 400
    
    if not code or state != session.get('spotify_state'):
        return jsonify({'error': 'Invalid authorization'}), 400
    
    # Exchange code for token
    token_url = 'https://accounts.spotify.com/api/token'
    data = {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': SPOTIFY_REDIRECT_URI,
        'client_id': SPOTIFY_CLIENT_ID,
        'client_secret': SPOTIFY_CLIENT_SECRET
    }
    
    print(f"🔄 Exchanging code for token...")
    response = requests.post(token_url, data=data, timeout=10)
    if response.status_code != 200:
        print(f"❌ Token exchange failed: {response.status_code} - {response.text}")
        return jsonify({'error': 'Failed to get access token'}), 400
    
    token_data = response.json()
    session['spotify_access_token'] = token_data['access_token']
    session['spotify_refresh_token'] = token_data.get('refresh_token')
    print(f"✅ Token received and stored in session")
    
    # Redirect back to app (HTTP is OK for local redirect)
    return redirect('http://localhost:8000/mixmaster_complete.html?spotify_auth=success')

@app.route('/api/ollama', methods=['POST'])
def ollama_proxy():
    """Proxy endpoint for Ollama API calls"""
    try:
        data = request.get_json()
        prompt = data.get('prompt')
        
        if not prompt:
            return jsonify({'error': 'No prompt provided'}), 400
        
        # Call Ollama API
        response = requests.post(
            OLLAMA_API_URL,
            headers={'Content-Type': 'application/json'},
            json={
                'model': OLLAMA_MODEL,
                'prompt': prompt,
                'stream': False,
                'temperature': 0.7
            },
            timeout=120
        )
        
        if response.status_code != 200:
            return jsonify({
                'error': f'Ollama API error: {response.status_code}',
                'details': response.text,
                'success': False
            }), response.status_code
        
        data = response.json()
        result_text = data.get('response', '')
        
        if not result_text:
            return jsonify({
                'error': 'Empty response from Ollama',
                'success': False
            }), 500
        
        return jsonify({
            'success': True,
            'result': result_text.strip()
        })
    
    except requests.exceptions.ConnectionError:
        return jsonify({
            'error': 'Cannot connect to Ollama',
            'message': 'Ollama is not running. Please start Ollama with: ollama serve',
            'success': False
        }), 503
    except requests.exceptions.Timeout:
        return jsonify({'error': 'Request timeout', 'success': False}), 504
    except requests.exceptions.RequestException as e:
        return jsonify({'error': str(e), 'success': False}), 500
    except (KeyError, IndexError, json.JSONDecodeError) as e:
        return jsonify({'error': 'Unexpected API response format', 'details': str(e), 'success': False}), 500
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500

@app.route('/api/status', methods=['GET'])
def status():
    """Check Ollama connection status"""
    try:
        response = requests.get('http://localhost:11434/api/tags', timeout=5)
        if response.status_code == 200:
            data = response.json()
            models = [m['name'] for m in data.get('models', [])]
            return jsonify({
                'status': 'connected',
                'ollama_running': True,
                'available_models': models,
                'current_model': OLLAMA_MODEL
            })
    except:
        pass
    
    return jsonify({
        'status': 'disconnected',
        'ollama_running': False,
        'message': 'Ollama is not running. Install and start it with: ollama serve'
    }), 503

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'ok', 'service': 'Ollama Proxy', 'provider': 'Local LLM'})

if __name__ == '__main__':
    print("🚀 Starting Ollama Proxy & Spotify Server on http://localhost:5000")
    print(f"📡 Proxying to: {OLLAMA_API_URL}")
    print(f"🤖 Model: {OLLAMA_MODEL}")
    
    if SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET:
        print("✅ Spotify API configured")
    else:
        print("⚠️  Spotify API not configured")
        print("   To enable Spotify import, set these environment variables:")
        print("   - SPOTIFY_CLIENT_ID")
        print("   - SPOTIFY_CLIENT_SECRET")
        print("   Get credentials at: https://developer.spotify.com/dashboard")
    
    print("\n⚠️  Make sure Ollama is running!")
    print("   Run this in another terminal: ollama serve")
    
    # Run on HTTP, bind to all interfaces for tunnel access
    app.run(debug=False, host='0.0.0.0', port=5000)
