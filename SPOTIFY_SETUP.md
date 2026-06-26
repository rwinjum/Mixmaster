# Spotify Setup Guide for Mixmaster

This guide explains how to enable Spotify playlist import functionality in Mixmaster.

## What You'll Need

To import playlists directly from Spotify, you need:
- A Spotify account (free or premium)
- Spotify API credentials (Client ID and Client Secret)

## Step 1: Create a Spotify Developer Application

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Log in with your Spotify account (create one if needed - it's free)
3. Click **"Create an App"**
4. Accept the terms and create the app
5. You'll see your **Client ID** and **Client Secret**

⚠️ **Keep your Client Secret private!** Don't share it or commit it to GitHub.

## Step 2: Configure Environment Variables

### Option A: Windows (Permanent)

1. Open **Environment Variables**:
   - Press `Win + X` → Select "System"
   - Click "Advanced system settings"
   - Click "Environment Variables"

2. Under "User variables", click **New**
   - Variable name: `SPOTIFY_CLIENT_ID`
   - Variable value: (paste your Client ID)
   - Click OK

3. Click **New** again
   - Variable name: `SPOTIFY_CLIENT_SECRET`
   - Variable value: (paste your Client Secret)
   - Click OK

4. **Restart your terminal and Python servers** for the changes to take effect

### Option B: Windows (Per Session)

Open PowerShell and set environment variables:

```powershell
$env:SPOTIFY_CLIENT_ID = "your-client-id-here"
$env:SPOTIFY_CLIENT_SECRET = "your-client-secret-here"

# Then start the proxy:
python gemini_proxy.py
```

### Option C: Create a `.env` File (Recommended for Development)

Create a file named `.env` in your Mixmaster folder:

```
SPOTIFY_CLIENT_ID=your-client-id-here
SPOTIFY_CLIENT_SECRET=your-client-secret-here
```

Then install python-dotenv:
```powershell
pip install python-dotenv
```

And in your terminal before running gemini_proxy.py:
```powershell
python -c "from dotenv import load_dotenv; load_dotenv()"
python gemini_proxy.py
```

## Step 3: Restart Your Servers

1. **Stop the Flask proxy** (if running)
2. Restart it:
   ```powershell
   python gemini_proxy.py
   ```
3. Check the output - you should see:
   ```
   ✅ Spotify API configured
   ```

## Step 4: Use Spotify Import in Mixmaster

1. Open Mixmaster in your browser
2. Find the **"Or import from Spotify"** section
3. Paste any public Spotify playlist URL:
   ```
   https://open.spotify.com/playlist/37i9dQZF1DXcZQZ8DUJt... (example)
   ```
4. Click **"📥 Import from Spotify"**
5. Wait for the playlist to load - you'll see all songs with complete metadata!

## Finding Spotify Playlist URLs

### Method 1: Spotify App
1. Open Spotify app or web player
2. Find your playlist
3. Click the **"..."** menu → **Share** → **Copy link to playlist**
4. Paste into Mixmaster

### Method 2: Browser
1. Go to [open.spotify.com](https://open.spotify.com)
2. Click on a playlist
3. Copy the URL from the address bar

## Supported Playlists

✅ Public playlists (anyone can see)
✅ Private playlists (if you're the owner)
✅ Collaborative playlists
✅ All genres and sizes

## Troubleshooting

### "Spotify credentials not configured"
- Make sure environment variables are set
- Restart the Flask proxy after setting variables
- Check the proxy output - it should say "✅ Spotify API configured"

### "Failed to fetch playlist"
- Check that the playlist URL is correct
- Make sure the playlist is public (or you own it if private)
- Try a different playlist to test

### "Failed to authenticate with Spotify"
- Verify Client ID and Client Secret are correct
- Re-copy them from the Spotify Developer Dashboard
- Make sure there are no extra spaces

### Playlist imports slowly
- Large playlists (500+ songs) take longer due to API rate limits
- This is normal - Spotify throttles requests
- Be patient, the import will complete

## What Data Gets Imported?

When you import a playlist, Mixmaster fetches:
- Track name
- Artist(s)
- Album
- Release date
- Duration
- Genres
- Energy (0-1)
- Tempo (BPM)
- Danceability (0-1)
- Key (0-11)
- Valence (0-1)
- And more!

This metadata is used to organize your playlist by genre, era, pace, and create smooth transitions between songs.

## Security Notes

- Your Client Secret is stored in environment variables (not in code)
- Credentials are **not** sent to Mixmaster's servers - only to Spotify's official API
- No data is logged or stored permanently
- The connection uses HTTPS encryption

## Advanced: Using Your Own Spotify App

Already have a Spotify app? You can use its credentials instead:

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Click on your existing app
3. View your credentials
4. Set `SPOTIFY_CLIENT_ID` and `SPOTIFY_CLIENT_SECRET` as shown above

## Need Help?

- [Spotify Developer Docs](https://developer.spotify.com/documentation/web-api)
- [Spotify Authorization Guide](https://developer.spotify.com/documentation/general/guides/authorization/)
- GitHub Issues (create one in the Mixmaster repo)

---

**Enjoy importing your Spotify playlists into Mixmaster!** 🎵
