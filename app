import React, { useState, useCallback } from 'react';
import { Upload, Download, Music, ChevronUp, ChevronDown, RefreshCw, Save, FileText, Shuffle, Play, Globe, Brain } from 'lucide-react';

const SpotifyPlaylistOrganizer = () => {
  const [songs, setSongs] = useState([]);
  const [organizedGroups, setOrganizedGroups] = useState([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [selectedReorderOptions, setSelectedReorderOptions] = useState(['genre']);
  const [avoidSameArtist, setAvoidSameArtist] = useState(true);
  const [uploadedFile, setUploadedFile] = useState(null);
  const [showReplacementModal, setShowReplacementModal] = useState(false);
  const [replacementData, setReplacementData] = useState({ groupIndex: -1, songIndex: -1, suggestions: [] });
  const [isLoadingInternetSuggestions, setIsLoadingInternetSuggestions] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editSongData, setEditSongData] = useState({ 
    groupIndex: -1, 
    songIndex: -1, 
    title: '', 
    artist: '', 
    album: '', 
    genre: '', 
    era: '', 
    pace: '', 
    tempo: 120,
    key: 0 
  });

  // Helper functions
  const toSentenceCase = (text) => {
    if (!text) return '';
    return text.charAt(0).toUpperCase() + text.slice(1).toLowerCase();
  };

  const getEraFromDate = (dateString) => {
    if (!dateString) return '2000s';
    const year = parseInt(dateString.split('-')[0]);
    if (year >= 2020) return '2020s';
    if (year >= 2010) return '2010s';
    if (year >= 2000) return '2000s';
    if (year >= 1990) return '90s';
    if (year >= 1980) return '80s';
    if (year >= 1970) return '70s';
    if (year >= 1960) return '60s';
    return 'Classic';
  };

  const getPrimaryGenre = (genresString) => {
    if (!genresString || genresString === '""' || genresString === '') return 'Pop';
    const genres = genresString.toLowerCase().replace(/"/g, '');
    
    if (genres.includes('rock') || genres.includes('alternative') || genres.includes('indie')) return 'Rock/Alternative';
    if (genres.includes('pop') || genres.includes('dance')) return 'Pop/Dance';
    if (genres.includes('hip hop') || genres.includes('rap')) return 'Hip Hop/Rap';
    if (genres.includes('electronic') || genres.includes('house') || genres.includes('techno')) return 'Electronic';
    if (genres.includes('r&b') || genres.includes('soul') || genres.includes('funk')) return 'R&B/Soul';
    if (genres.includes('country')) return 'Country';
    if (genres.includes('jazz')) return 'Jazz';
    if (genres.includes('classical')) return 'Classical';
    
    return 'Pop';
  };

  const getPaceFromFeatures = (energy, tempo, danceability) => {
    const energyScore = energy || 0.5;
    const tempoScore = Math.min(1, (tempo || 120) / 140);
    const danceScore = danceability || 0.5;
    
    const overallPace = (energyScore + tempoScore + danceScore) / 3;
    
    if (overallPace > 0.7) return 'High';
    if (overallPace > 0.4) return 'Medium';
    return 'Low';
  };

  const getKeyName = (keyNum) => {
    const keys = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    return keys[keyNum] || 'C';
  };

  const formatDuration = (ms) => {
    const minutes = Math.floor(ms / 60000);
    const seconds = Math.floor((ms % 60000) / 1000);
    return `${minutes}:${seconds.toString().padStart(2, '0')}`;
  };

  const handleFileUpload = useCallback((event) => {
    const file = event.target.files[0];
    if (file && file.type === 'text/csv') {
      setUploadedFile(file);
      const reader = new FileReader();
      reader.onload = (e) => {
        const csv = e.target.result;
        const lines = csv.split('\n');
        const headers = lines[0].split(',').map(h => h.trim().replace(/"/g, ''));
        
        const parsedSongs = lines.slice(1).filter(line => line.trim()).map((line, index) => {
          const values = [];
          let current = '';
          let inQuotes = false;
          
          for (let i = 0; i < line.length; i++) {
            const char = line[i];
            if (char === '"') {
              inQuotes = !inQuotes;
            } else if (char === ',' && !inQuotes) {
              values.push(current.trim());
              current = '';
            } else {
              current += char;
            }
          }
          values.push(current.trim());
          
          const song = { id: index + 1 };
          
          const rawTitle = values[headers.indexOf('Track Name')] || '';
          const rawArtist = values[headers.indexOf('Artist Name(s)')] || '';
          const rawAlbum = values[headers.indexOf('Album Name')] || '';
          
          song.title = toSentenceCase(rawTitle);
          song.artist = toSentenceCase(rawArtist);
          song.album = toSentenceCase(rawAlbum);
          song.genres = values[headers.indexOf('Genres')] || '';
          song.releaseDate = values[headers.indexOf('Release Date')] || '';
          song.duration = parseInt(values[headers.indexOf('Duration (ms)')]) || 0;
          song.energy = parseFloat(values[headers.indexOf('Energy')]) || 0;
          song.tempo = parseFloat(values[headers.indexOf('Tempo')]) || 120;
          song.danceability = parseFloat(values[headers.indexOf('Danceability')]) || 0;
          song.key = parseInt(values[headers.indexOf('Key')]) || 0;
          song.valence = parseFloat(values[headers.indexOf('Valence')]) || 0;
          
          song.era = getEraFromDate(song.releaseDate);
          song.genre = getPrimaryGenre(song.genres);
          song.pace = getPaceFromFeatures(song.energy, song.tempo, song.danceability);
          song.keyName = getKeyName(song.key);
          song.durationFormatted = formatDuration(song.duration);
          
          return song;
        });
        
        setSongs(parsedSongs.filter(song => song.title && song.artist));
      };
      reader.readAsText(file);
    } else {
      alert('Please select a valid CSV file');
    }
  }, []);

  // Load sample data
  const loadSampleData = () => {
    const sampleSongs = [
      {
        id: 1,
        title: "Bohemian Rhapsody",
        artist: "Queen",
        album: "A Night At The Opera",
        genre: "Rock/Alternative",
        era: "70s",
        pace: "Medium",
        tempo: 144,
        keyName: "Bb",
        key: 10,
        energy: 0.6,
        valence: 0.5,
        danceability: 0.4,
        durationFormatted: "5:55"
      },
      {
        id: 2,
        title: "Billie Jean",
        artist: "Michael Jackson",
        album: "Thriller",
        genre: "Pop/Dance",
        era: "80s",
        pace: "High",
        tempo: 117,
        keyName: "F#",
        key: 6,
        energy: 0.8,
        valence: 0.7,
        danceability: 0.9,
        durationFormatted: "4:54"
      },
      {
        id: 3,
        title: "Hey Ya!",
        artist: "OutKast",
        album: "Speakerboxxx/The Love Below",
        genre: "Hip Hop/Rap",
        era: "2000s",
        pace: "High",
        tempo: 160,
        keyName: "G",
        key: 7,
        energy: 0.8,
        valence: 0.9,
        danceability: 0.9,
        durationFormatted: "3:55"
      },
      {
        id: 4,
        title: "Stairway To Heaven",
        artist: "Led Zeppelin",
        album: "Led Zeppelin IV",
        genre: "Rock/Alternative",
        era: "70s",
        pace: "Medium",
        tempo: 82,
        keyName: "A",
        key: 9,
        energy: 0.7,
        valence: 0.6,
        danceability: 0.3,
        durationFormatted: "8:02"
      },
      {
        id: 5,
        title: "Beat It",
        artist: "Michael Jackson",
        album: "Thriller",
        genre: "Pop/Dance",
        era: "80s",
        pace: "High",
        tempo: 138,
        keyName: "E",
        key: 4,
        energy: 0.9,
        valence: 0.6,
        danceability: 0.8,
        durationFormatted: "4:18"
      },
      {
        id: 6,
        title: "Smells Like Teen Spirit",
        artist: "Nirvana",
        album: "Nevermind",
        genre: "Rock/Alternative",
        era: "90s",
        pace: "High",
        tempo: 116,
        keyName: "F",
        key: 5,
        energy: 0.9,
        valence: 0.4,
        danceability: 0.5,
        durationFormatted: "5:01"
      }
    ];
    setSongs(sampleSongs);
    setUploadedFile({ name: 'sample-playlist.csv' });
  };

  // Calculate similarity between songs (enhanced for combined rules)
  const calculateSimilarity = (song1, song2, rule) => {
    let score = 0;
    
    // Handle combined rules
    if (rule === 'genre+era') {
      if (song1.genre === song2.genre && song1.era === song2.era) {
        score += 0.6; // Higher score for perfect combined match
      } else if (song1.genre === song2.genre) {
        score += 0.3; // Partial score for genre match only
      } else if (song1.era === song2.era) {
        score += 0.2; // Smaller score for era match only
      }
    } else if (rule === 'pace+era') {
      if (song1.pace === song2.pace && song1.era === song2.era) {
        score += 0.6; // Higher score for perfect combined match
      } else if (song1.pace === song2.pace) {
        score += 0.3; // Partial score for pace match only
      } else if (song1.era === song2.era) {
        score += 0.2; // Smaller score for era match only
      }
    } else {
      // Single rule
      if (song1[rule] && song2[rule] && song1[rule] === song2[rule]) {
        score += 0.4;
      }
    }
    
    // Additional similarity factors
    if (song1.artist === song2.artist) {
      score += 0.2;
    }
    
    const tempo1 = parseFloat(song1.tempo) || 120;
    const tempo2 = parseFloat(song2.tempo) || 120;
    if (Math.abs(tempo1 - tempo2) < 20) {
      score += 0.2;
    }
    
    // Energy similarity
    if (song1.energy && song2.energy) {
      const energyDiff = Math.abs(song1.energy - song2.energy);
      if (energyDiff < 0.2) {
        score += 0.1;
      }
    }
    
    // Genre compatibility (for non-genre rules)
    if (rule !== 'genre' && rule !== 'genre+era' && song1.genre === song2.genre) {
      score += 0.1;
    }
    
    return score;
  };

  // Calculate how well a song fits in a group (enhanced for combined rules)
  const calculateGroupFit = (song, replacingSong, rule, otherGroupSongs) => {
    let score = 0;
    
    // Primary rule match
    if (rule === 'genre+era') {
      if (song.genre === replacingSong.genre && song.era === replacingSong.era) {
        score += 0.6;
      } else if (song.genre === replacingSong.genre) {
        score += 0.3;
      } else if (song.era === replacingSong.era) {
        score += 0.2;
      }
    } else if (rule === 'pace+era') {
      if (song.pace === replacingSong.pace && song.era === replacingSong.era) {
        score += 0.6;
      } else if (song.pace === replacingSong.pace) {
        score += 0.3;
      } else if (song.era === replacingSong.era) {
        score += 0.2;
      }
    } else {
      // Single rule
      if (song[rule] === replacingSong[rule]) {
        score += 0.5;
      }
    }
    
    // Avoid same artist if setting is enabled
    if (avoidSameArtist) {
      const hasConflict = otherGroupSongs.some(groupSong => groupSong.artist === song.artist);
      if (hasConflict) {
        score -= 0.3;
      }
    }
    
    // Musical compatibility
    const musicalSimilarity = calculateSimilarity(song, replacingSong, rule);
    score += musicalSimilarity * 0.3;
    
    return Math.max(0, score);
  };

  // Get AI suggestions from existing playlist (enhanced for combined rules)
  const getAISuggestions = (baseSong, rule, availableSongs, avoidSameArtist, currentGroup) => {
    if (!availableSongs || availableSongs.length === 0) {
      return [];
    }
    
    let filteredSongs = availableSongs.filter(song => {
      // Check rule compatibility
      let ruleMatch = false;
      if (rule === 'genre+era') {
        ruleMatch = song.genre === baseSong.genre && song.era === baseSong.era;
      } else if (rule === 'pace+era') {
        ruleMatch = song.pace === baseSong.pace && song.era === baseSong.era;
      } else {
        // Single rule
        ruleMatch = song[rule] === baseSong[rule];
      }
      
      if (!ruleMatch) return false;
      
      if (avoidSameArtist) {
        const wouldCreateSameArtistInRow = currentGroup.some(groupSong => 
          groupSong.artist === song.artist
        );
        if (wouldCreateSameArtistInRow || song.artist === baseSong.artist) {
          return false;
        }
      }
      return true;
    });
    
    const songsWithSimilarity = filteredSongs.map(song => ({
      ...song,
      similarity: calculateSimilarity(baseSong, song, rule)
    }));
    
    const suggestions = songsWithSimilarity
      .filter(song => song.similarity > 0)
      .sort((a, b) => b.similarity - a.similarity)
      .slice(0, 5);
    
    // If we don't have enough exact matches, include near matches with lower similarity
    if (suggestions.length < 3) {
      const nearMatches = availableSongs
        .filter(song => !filteredSongs.includes(song)) // Songs that didn't match the rule exactly
        .filter(song => {
          if (avoidSameArtist) {
            const wouldCreateSameArtistInRow = currentGroup.some(groupSong => 
              groupSong.artist === song.artist
            );
            if (wouldCreateSameArtistInRow || song.artist === baseSong.artist) {
              return false;
            }
          }
          return true;
        })
        .map(song => ({
          ...song,
          similarity: calculateSimilarity(baseSong, song, rule) * 0.5 // Lower similarity for non-exact matches
        }))
        .sort((a, b) => b.similarity - a.similarity)
        .slice(0, 3 - suggestions.length);
      
      suggestions.push(...nearMatches);
    }
    
    return suggestions.slice(0, 3);
  };

  // Create search query for internet suggestions (enhanced for combined rules)
  const createSearchQuery = (currentSong, group) => {
    const rule = group.rule;
    const ruleValue = group.ruleValue;
    
    if (rule === 'genre+era') {
      return `${currentSong.genre} ${currentSong.era} songs similar to ${currentSong.artist}`;
    } else if (rule === 'pace+era') {
      return `${currentSong.pace} energy ${currentSong.era} music like ${currentSong.artist}`;
    } else if (rule === 'genre') {
      return `${ruleValue} songs similar to ${currentSong.artist}`;
    } else if (rule === 'era') {
      return `${ruleValue} music similar to ${currentSong.title} ${currentSong.artist}`;
    } else if (rule === 'pace') {
      return `${ruleValue} energy songs like ${currentSong.artist}`;
    }
    
    return `songs similar to ${currentSong.title} ${currentSong.artist}`;
  };

  // Generate additional internet suggestions for variety
  const generateMoreInternetSuggestions = async (currentSong, group, needed) => {
    await new Promise(resolve => setTimeout(resolve, 500)); // Shorter delay for additional suggestions
    
    const suggestions = [];
    let aiId = -6000; // Different ID range
    
    // Generate more variety based on different aspects
    if (group.rule === 'genre' || group.rule === 'genre+era') {
      if (group.ruleValue.includes('Rock') || currentSong.genre === 'Rock/Alternative') {
        suggestions.push(
          {
            id: aiId--,
            title: "Paranoid Android",
            artist: "Radiohead",
            album: "OK Computer",
            genre: "Rock/Alternative",
            era: "90s",
            pace: "Medium",
            tempo: 95,
            keyName: "C",
            key: 0,
            energy: 0.7,
            valence: 0.3,
            danceability: 0.4,
            durationFormatted: "6:23",
            reasoning: "Complex alternative rock masterpiece with dynamic shifts",
            confidence: 0.89
          },
          {
            id: aiId--,
            title: "Black",
            artist: "Pearl Jam",
            album: "Ten",
            genre: "Rock/Alternative",
            era: "90s",
            pace: "Low",
            tempo: 69,
            keyName: "E",
            key: 4,
            energy: 0.4,
            valence: 0.3,
            danceability: 0.3,
            durationFormatted: "5:43",
            reasoning: "Emotional grunge ballad with powerful guitar work",
            confidence: 0.87
          }
        );
      } else if (group.ruleValue.includes('Pop') || currentSong.genre === 'Pop/Dance') {
        suggestions.push(
          {
            id: aiId--,
            title: "Shape of You",
            artist: "Ed Sheeran",
            album: "÷ (Divide)",
            genre: "Pop/Dance",
            era: "2010s",
            pace: "Medium",
            tempo: 96,
            keyName: "C#",
            key: 1,
            energy: 0.7,
            valence: 0.9,
            danceability: 0.8,
            durationFormatted: "3:53",
            reasoning: "Modern pop hit with tropical house influences and mass appeal",
            confidence: 0.93
          },
          {
            id: aiId--,
            title: "Don't Stop Me Now",
            artist: "Queen",
            album: "Jazz",
            genre: "Pop/Dance",
            era: "70s",
            pace: "High",
            tempo: 156,
            keyName: "F",
            key: 5,
            energy: 0.9,
            valence: 0.9,
            danceability: 0.7,
            durationFormatted: "3:29",
            reasoning: "High-energy rock anthem with universal dance appeal",
            confidence: 0.91
          }
        );
      }
    } else if (group.rule === 'era' || group.rule === 'pace+era') {
      if (group.ruleValue.includes('2000s') || currentSong.era === '2000s') {
        suggestions.push(
          {
            id: aiId--,
            title: "Since U Been Gone",
            artist: "Kelly Clarkson",
            album: "Breakaway",
            genre: "Pop/Dance",
            era: "2000s",
            pace: "High",
            tempo: 130,
            keyName: "G",
            key: 7,
            energy: 0.8,
            valence: 0.7,
            danceability: 0.7,
            durationFormatted: "3:08",
            reasoning: "Pop-rock anthem that defined mid-2000s radio",
            confidence: 0.88
          }
        );
      }
    }
    
    // Add generic suggestions if we still need more
    if (suggestions.length < needed) {
      const genericSuggestions = [
        {
          id: aiId--,
          title: "Bohemian Rhapsody",
          artist: "Queen",
          album: "A Night at the Opera",
          genre: "Rock/Alternative",
          era: "70s",
          pace: "Medium",
          tempo: 144,
          keyName: "Bb",
          key: 10,
          energy: 0.6,
          valence: 0.5,
          danceability: 0.4,
          durationFormatted: "5:55",
          reasoning: "Timeless rock epic that works in almost any context",
          confidence: 0.85
        },
        {
          id: aiId--,
          title: "Hotel California",
          artist: "Eagles",
          album: "Hotel California",
          genre: "Rock/Alternative",
          era: "70s",
          pace: "Medium",
          tempo: 150,
          keyName: "B",
          key: 11,
          energy: 0.6,
          valence: 0.4,
          danceability: 0.5,
          durationFormatted: "6:30",
          reasoning: "Classic rock staple with broad appeal and recognition",
          confidence: 0.84
        }
      ];
      
      suggestions.push(...genericSuggestions.slice(0, needed - suggestions.length));
    }
    
    return suggestions.slice(0, needed).map(s => ({
      ...s,
      similarity: s.confidence,
      isInternetAISuggestion: true,
      searchQuery: `additional ${group.ruleValue} suggestions`
    }));
  };
  const simulateInternetMusicAPI = async (searchQuery, currentSong, group) => {
    await new Promise(resolve => setTimeout(resolve, 1500));
    
    const suggestions = [];
    let aiId = -5000;
    
    if (group.rule === 'genre') {
      if (group.ruleValue === 'Rock/Alternative') {
        suggestions.push(
          {
            id: aiId--,
            title: "Seven Nation Army",
            artist: "The White Stripes",
            album: "Elephant",
            genre: "Rock/Alternative",
            era: "2000s",
            pace: "Medium",
            tempo: 124,
            keyName: "E",
            key: 4,
            energy: 0.7,
            valence: 0.6,
            danceability: 0.5,
            durationFormatted: "3:51",
            reasoning: "Iconic rock anthem with powerful bass line and wide appeal",
            confidence: 0.95
          },
          {
            id: aiId--,
            title: "Use Somebody",
            artist: "Kings of Leon",
            album: "Only by the Night",
            genre: "Rock/Alternative",
            era: "2000s",
            pace: "Medium",
            tempo: 136,
            keyName: "C",
            key: 0,
            energy: 0.6,
            valence: 0.5,
            danceability: 0.4,
            durationFormatted: "3:50",
            reasoning: "Alternative rock with emotional depth and mainstream crossover appeal",
            confidence: 0.92
          }
        );
      } else if (group.ruleValue === 'Pop/Dance') {
        suggestions.push(
          {
            id: aiId--,
            title: "Blinding Lights",
            artist: "The Weeknd",
            album: "After Hours",
            genre: "Pop/Dance",
            era: "2020s",
            pace: "High",
            tempo: 171,
            keyName: "F",
            key: 5,
            energy: 0.8,
            valence: 0.6,
            danceability: 0.9,
            durationFormatted: "3:20",
            reasoning: "Modern pop hit with retro synth elements and massive dancefloor appeal",
            confidence: 0.97
          }
        );
      }
    }
    
    return suggestions.map(s => ({
      ...s,
      similarity: s.confidence,
      isInternetAISuggestion: true,
      searchQuery: searchQuery
    }));
  };

  // Generate AI suggestions from knowledge base
  const generateAIMusicSuggestions = (currentSong, group) => {
    const suggestions = [];
    let aiId = -1;
    
    if (group.rule === 'genre' && group.ruleValue === 'Rock/Alternative') {
      suggestions.push({
        id: aiId--,
        title: "Everlong",
        artist: "Foo Fighters",
        album: "The Colour And The Shape",
        genre: "Rock/Alternative",
        era: "90s",
        pace: "High",
        tempo: 158,
        keyName: "D",
        key: 2,
        energy: 0.8,
        valence: 0.7,
        danceability: 0.6,
        durationFormatted: "4:10",
        reasoning: "Classic alternative rock with driving energy"
      });
    } else if (group.rule === 'genre' && group.ruleValue === 'Pop/Dance') {
      suggestions.push({
        id: aiId--,
        title: "Can't Stop The Feeling!",
        artist: "Justin Timberlake",
        album: "Trolls Soundtrack",
        genre: "Pop/Dance",
        era: "2010s",
        pace: "High",
        tempo: 113,
        keyName: "C",
        key: 0,
        energy: 0.9,
        valence: 0.9,
        danceability: 0.8,
        durationFormatted: "3:56",
        reasoning: "Upbeat pop with infectious energy"
      });
    }
    
    return suggestions.slice(0, 3).map((suggestion, index) => ({
      ...suggestion,
      similarity: 0.8 - (index * 0.1),
      isAISuggestion: true,
      aiReasoning: suggestion.reasoning
    }));
  };

  // Enhanced suggestion function with proper separation
  const suggestSongReplacement = async (groupIndex, songIndex, includeInternetSuggestions = false) => {
    const group = organizedGroups[groupIndex];
    const currentSong = group.songs[songIndex];
    
    let allSuggestions = [];
    
    if (includeInternetSuggestions) {
      // INTERNET AI MODE: Only use simulated web suggestions
      console.log('Fetching INTERNET AI suggestions only...');
      
      try {
        const searchQuery = createSearchQuery(currentSong, group);
        const internetSuggestions = await simulateInternetMusicAPI(searchQuery, currentSong, group);
        if (internetSuggestions.length > 0) {
          console.log('Generated', internetSuggestions.length, 'internet AI suggestions');
          allSuggestions.push(...internetSuggestions.map(s => ({ ...s, source: 'internet_ai' })));
        }
      } catch (error) {
        console.error('Error fetching internet suggestions:', error);
      }
      
      // If we don't have enough internet suggestions, add some more variety
      if (allSuggestions.length < 3) {
        const moreInternetSuggestions = await generateMoreInternetSuggestions(currentSong, group, 3 - allSuggestions.length);
        allSuggestions.push(...moreInternetSuggestions.map(s => ({ ...s, source: 'internet_ai' })));
      }
      
    } else {
      // EXISTING MODE: Only use playlist songs and smart mining
      console.log('Fetching EXISTING suggestions only...');
      
      // Option 1: Unused songs from your playlist
      const usedSongIds = new Set();
      organizedGroups.forEach((g, gIndex) => {
        g.songs.forEach((s, sIndex) => {
          if (!(gIndex === groupIndex && sIndex === songIndex)) {
            usedSongIds.add(s.id);
          }
        });
      });
      
      const unusedSongs = songs.filter(s => !usedSongIds.has(s.id));
      
      if (unusedSongs.length > 0) {
        const suggestions = getAISuggestions(
          currentSong, 
          group.rule,
          unusedSongs, 
          avoidSameArtist, 
          group.songs.filter((_, i) => i !== songIndex)
        );
        
        if (suggestions.length > 0) {
          console.log('Found', suggestions.length, 'suggestions from unused songs');
          allSuggestions.push(...suggestions.slice(0, 3).map(s => ({ ...s, source: 'playlist' })));
        }
      }
      
      // Option 2: Smart playlist mining from other groups (if still need more)
      if (allSuggestions.length < 3) {
        console.log('Mining from other groups...');
        const allOtherSongs = [];
        organizedGroups.forEach((g, gIndex) => {
          if (gIndex !== groupIndex) {
            g.songs.forEach((song, sIndex) => {
              const currentGroupSongs = group.songs.filter((_, i) => i !== songIndex);
              const wouldFitBetter = calculateGroupFit(song, currentSong, group.rule, currentGroupSongs);
              
              if (wouldFitBetter > 0.3) {
                allOtherSongs.push({
                  ...song,
                  sourceGroup: gIndex,
                  sourceSong: sIndex,
                  groupFitScore: wouldFitBetter,
                  source: 'group_mining'
                });
              }
            });
          }
        });
        
        const smartSuggestions = allOtherSongs
          .sort((a, b) => b.groupFitScore - a.groupFitScore)
          .slice(0, 3 - allSuggestions.length);
        
        allSuggestions.push(...smartSuggestions);
      }
    }
    
    return allSuggestions;
  };

  // Group songs by rules (enhanced to handle combined rules)
  const groupSongsByRules = (songs, rules, avoidSameArtist) => {
    const groups = [];
    const used = new Set();
    const shuffledSongs = [...songs].sort(() => Math.random() - 0.5);
    const remainingSongs = [...shuffledSongs];
    
    while (remainingSongs.length > 0 && used.size < songs.length) {
      let bestGroup = null;
      let bestRule = null;
      
      for (const rule of rules) {
        for (let i = 0; i < remainingSongs.length; i++) {
          const song = remainingSongs[i];
          if (used.has(song.id)) continue;
          
          const group = [song];
          const candidates = remainingSongs.filter(s => {
            if (used.has(s.id) || s.id === song.id) return false;
            
            // Handle combined rules
            if (rule === 'genre+era') {
              if (s.genre !== song.genre || s.era !== song.era) return false;
            } else if (rule === 'pace+era') {
              if (s.pace !== song.pace || s.era !== song.era) return false;
            } else {
              // Single rule
              if (s[rule] !== song[rule]) return false;
            }
            
            if (avoidSameArtist) {
              const wouldCreateSameArtistInRow = group.some(groupSong => 
                groupSong.artist === s.artist
              );
              if (wouldCreateSameArtistInRow) return false;
            }
            
            return true;
          });
          
          const selectedCandidates = candidates.slice(0, 2);
          const potentialGroup = [song, ...selectedCandidates];
          
          if (potentialGroup.length > (bestGroup?.length || 0)) {
            bestGroup = potentialGroup;
            bestRule = rule;
          }
          
          if (potentialGroup.length === 3) {
            break;
          }
        }
        
        if (bestGroup?.length === 3) {
          break;
        }
      }
      
      if (bestGroup && bestGroup.length > 0) {
        bestGroup.forEach(song => {
          used.add(song.id);
          const index = remainingSongs.findIndex(s => s.id === song.id);
          if (index > -1) {
            remainingSongs.splice(index, 1);
          }
        });
        
        // Generate rule value for display
        let ruleValue;
        if (bestRule === 'genre+era') {
          ruleValue = `${bestGroup[0].genre} + ${bestGroup[0].era}`;
        } else if (bestRule === 'pace+era') {
          ruleValue = `${bestGroup[0].pace} + ${bestGroup[0].era}`;
        } else {
          ruleValue = bestGroup[0][bestRule];
        }
        
        groups.push({
          id: groups.length + 1,
          songs: bestGroup,
          rule: bestRule,
          ruleValue: ruleValue
        });
      } else {
        break;
      }
    }
    
    return groups;
  };

  const organizePlaylist = async () => {
    if (songs.length === 0 || selectedReorderOptions.length === 0) return;
    
    setIsProcessing(true);
    await new Promise(resolve => setTimeout(resolve, 1500));
    
    const groups = groupSongsByRules(songs, selectedReorderOptions, avoidSameArtist);
    setOrganizedGroups(groups);
    setIsProcessing(false);
  };

  const openReplacementModal = async (groupIndex, songIndex, includeInternet = false) => {
    try {
      console.log('Opening replacement modal for group', groupIndex, 'song', songIndex, 'with internet:', includeInternet);
      
      if (includeInternet) {
        setIsLoadingInternetSuggestions(true);
      }
      
      const suggestions = await suggestSongReplacement(groupIndex, songIndex, includeInternet);
      console.log('Got suggestions:', suggestions);
      
      setReplacementData({ groupIndex, songIndex, suggestions });
      setShowReplacementModal(true);
      setIsLoadingInternetSuggestions(false);
    } catch (error) {
      console.error('Error opening replacement modal:', error);
      setIsLoadingInternetSuggestions(false);
      alert('Error getting song suggestions. Please try again.');
    }
  };

  const handleSongReplacement = (newSong) => {
    const newGroups = [...organizedGroups];
    newGroups[replacementData.groupIndex].songs[replacementData.songIndex] = newSong;
    setOrganizedGroups(newGroups);
    setShowReplacementModal(false);
    setReplacementData({ groupIndex: -1, songIndex: -1, suggestions: [] });
  };

  // Edit modal functions
  const openEditModal = (groupIndex, songIndex) => {
    const song = organizedGroups[groupIndex].songs[songIndex];
    setEditSongData({
      groupIndex,
      songIndex,
      title: song.title || '',
      artist: song.artist || '',
      album: song.album || '',
      genre: song.genre || '',
      era: song.era || '',
      pace: song.pace || '',
      tempo: song.tempo || 120,
      key: song.key || 0
    });
    setShowEditModal(true);
  };

  const closeEditModal = () => {
    setShowEditModal(false);
    setEditSongData({ 
      groupIndex: -1, 
      songIndex: -1, 
      title: '', 
      artist: '', 
      album: '', 
      genre: '', 
      era: '', 
      pace: '', 
      tempo: 120,
      key: 0 
    });
  };

  const handleManualSongEdit = () => {
    const updatedSong = {
      ...organizedGroups[editSongData.groupIndex].songs[editSongData.songIndex],
      title: toSentenceCase(editSongData.title),
      artist: toSentenceCase(editSongData.artist),
      album: toSentenceCase(editSongData.album),
      genre: editSongData.genre,
      era: editSongData.era,
      pace: editSongData.pace,
      tempo: parseFloat(editSongData.tempo) || 120,
      key: parseInt(editSongData.key) || 0,
      keyName: getKeyName(parseInt(editSongData.key) || 0),
      durationFormatted: formatDuration((parseFloat(editSongData.tempo) || 120) * 1000)
    };
    
    const newGroups = [...organizedGroups];
    newGroups[editSongData.groupIndex].songs[editSongData.songIndex] = updatedSong;
    setOrganizedGroups(newGroups);
    closeEditModal();
  };

  // Group movement functions
  const moveGroup = (groupIndex, direction) => {
    const newGroups = [...organizedGroups];
    const targetIndex = direction === 'up' ? groupIndex - 1 : groupIndex + 1;
    
    if (targetIndex >= 0 && targetIndex < newGroups.length) {
      [newGroups[groupIndex], newGroups[targetIndex]] = [newGroups[targetIndex], newGroups[groupIndex]];
      setOrganizedGroups(newGroups);
    }
  };

  // Export functions
  const exportToCSV = () => {
    if (organizedGroups.length === 0) {
      alert('Please organize your playlist first before exporting!');
      return;
    }
    
    try {
      // Create CSV in a format compatible with playlist import services like Soundiiz
      const headers = ['Track', 'Artist', 'Album', 'Duration', 'Group Info'];
      const rows = [];
      
      organizedGroups.forEach((group, groupIndex) => {
        group.songs.forEach((song, songIndex) => {
          rows.push([
            song.title || '',
            song.artist || '',
            song.album || '',
            song.durationFormatted || '',
            `Group ${groupIndex + 1} (${group.rule}: ${group.ruleValue}) - Position ${songIndex + 1}`
          ]);
        });
      });
      
      const csvContent = [headers, ...rows].map(row => 
        row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(',')
      ).join('\n');
      
      // Copy to clipboard
      navigator.clipboard.writeText(csvContent).then(() => {
        alert('CSV content copied to clipboard! This format is compatible with Soundiiz and other playlist import services.');
      }).catch(() => {
        // Fallback: create download link
        const blob = new Blob([csvContent], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'organized-playlist.csv';
        a.click();
        window.URL.revokeObjectURL(url);
      });
      
    } catch (error) {
      console.error('Error exporting CSV:', error);
      alert('Error exporting CSV. Please check the console for details.');
    }
  };

  const exportToDetailedCSV = () => {
    if (organizedGroups.length === 0) {
      alert('Please organize your playlist first before exporting!');
      return;
    }
    
    try {
      // Detailed CSV with all metadata for DJ analysis
      const headers = ['Group', 'Position', 'Track Name', 'Artist Name(s)', 'Album Name', 'Genre', 'Era', 'Pace', 'Duration', 'Tempo', 'Key', 'Energy', 'Danceability', 'Valence'];
      const rows = [];
      
      organizedGroups.forEach((group, groupIndex) => {
        group.songs.forEach((song, songIndex) => {
          rows.push([
            `Group ${groupIndex + 1} (${group.rule}: ${group.ruleValue})`,
            songIndex + 1,
            song.title || '',
            song.artist || '',
            song.album || '',
            song.genre || '',
            song.era || '',
            song.pace || '',
            song.durationFormatted || '',
            Math.round(song.tempo) || '',
            song.keyName || '',
            song.energy?.toFixed(2) || '',
            song.danceability?.toFixed(2) || '',
            song.valence?.toFixed(2) || ''
          ]);
        });
      });
      
      const csvContent = [headers, ...rows].map(row => 
        row.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(',')
      ).join('\n');
      
      // Copy to clipboard
      navigator.clipboard.writeText(csvContent).then(() => {
        alert('Detailed CSV copied to clipboard! This includes all DJ metadata and audio features.');
      }).catch(() => {
        // Fallback: create download link
        const blob = new Blob([csvContent], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'detailed-organized-playlist.csv';
        a.click();
        window.URL.revokeObjectURL(url);
      });
      
    } catch (error) {
      console.error('Error exporting detailed CSV:', error);
      alert('Error exporting CSV. Please check the console for details.');
    }
  };

  const exportToSpotify = () => {
    if (organizedGroups.length === 0) {
      alert('Please organize your playlist first before exporting!');
      return;
    }
    
    try {
      // Create a simplified playlist format that could be used with Spotify API
      const playlistData = {
        name: `DJ Organized Playlist - ${new Date().toLocaleDateString()}`,
        description: `Organized using the Group of Three DJ rule with ${selectedReorderOptions.join(', ')} grouping${avoidSameArtist ? ' and no same artist in a row' : ''}`,
        groups: organizedGroups.length,
        tracks: []
      };
      
      organizedGroups.forEach((group, groupIndex) => {
        group.songs.forEach((song, songIndex) => {
          playlistData.tracks.push({
            groupNumber: groupIndex + 1,
            positionInGroup: songIndex + 1,
            trackName: song.title,
            artistName: song.artist,
            albumName: song.album,
            groupRule: group.rule,
            groupValue: group.ruleValue
          });
        });
      });
      
      const jsonContent = JSON.stringify(playlistData, null, 2);
      
      // Copy to clipboard
      navigator.clipboard.writeText(jsonContent).then(() => {
        alert('Spotify playlist data copied to clipboard! You can paste it into a JSON file for API integration.');
      }).catch(() => {
        // Fallback: create download link
        const blob = new Blob([jsonContent], { type: 'application/json' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'spotify-playlist-data.json';
        a.click();
        window.URL.revokeObjectURL(url);
      });
      
    } catch (error) {
      console.error('Error exporting to Spotify format:', error);
      alert('Error exporting playlist. Please check the console for details.');
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-900 via-black to-green-800 text-white p-4">
      <div className="max-w-7xl mx-auto">
        <header className="text-center mb-8">
          <div className="flex items-center justify-center gap-3 mb-4">
            <Music className="w-10 h-10 text-green-400" />
            <h1 className="text-4xl font-bold bg-gradient-to-r from-green-400 to-green-600 bg-clip-text text-transparent">
              DJ playlist organizer
            </h1>
          </div>
          <p className="text-gray-300 text-lg">Reorganize your Spotify playlists using the "group of three" DJ rule</p>
        </header>

        {/* Upload Section */}
        <div className="bg-gray-800 rounded-xl p-6 mb-8 border border-gray-700">
          <h2 className="text-2xl font-semibold mb-4 flex items-center gap-2">
            <Upload className="w-6 h-6" />
            Upload playlist
          </h2>
          <div className="flex flex-col sm:flex-row gap-4">
            <label className="flex-1 border-2 border-dashed border-gray-600 rounded-lg p-4 text-center cursor-pointer hover:border-green-400 transition-colors">
              <input
                type="file"
                accept=".csv"
                onChange={handleFileUpload}
                className="hidden"
              />
              <div className="flex flex-col items-center gap-2">
                <FileText className="w-8 h-8 text-gray-400" />
                <span className="text-gray-300">
                  {uploadedFile ? uploadedFile.name : 'Click to upload your Spotify CSV file'}
                </span>
              </div>
            </label>
            <button
              onClick={loadSampleData}
              className="px-6 py-3 bg-purple-600 hover:bg-purple-700 rounded-lg transition-colors font-medium flex items-center gap-2"
            >
              Try sample data
            </button>
          </div>
          {songs.length > 0 && (
            <p className="mt-3 text-green-400">
              ✓ {songs.length} songs loaded
            </p>
          )}
        </div>

        {/* Reorder Options */}
        {songs.length > 0 && (
          <div className="bg-gray-800 rounded-xl p-6 mb-8 border border-gray-700">
            <h2 className="text-2xl font-semibold mb-4 flex items-center gap-2">
              <Shuffle className="w-6 h-6" />
              Reorder options
            </h2>
            
            <div className="grid grid-cols-1 md:grid-cols-5 gap-4 mb-6">
              {[
                { value: 'genre', label: 'By genre', desc: 'Group similar music styles together' },
                { value: 'era', label: 'By era', desc: 'Group songs from same time period' },
                { value: 'pace', label: 'By pace', desc: 'Group by energy and tempo' },
                { value: 'genre+era', label: 'By genre + era', desc: 'Group by both music style and time period' },
                { value: 'pace+era', label: 'By pace + era', desc: 'Group by both energy and time period' }
              ].map(option => (
                <label key={option.value} className="cursor-pointer">
                  <input
                    type="checkbox"
                    value={option.value}
                    checked={selectedReorderOptions.includes(option.value)}
                    onChange={(e) => {
                      if (e.target.checked) {
                        setSelectedReorderOptions([...selectedReorderOptions, option.value]);
                      } else {
                        setSelectedReorderOptions(selectedReorderOptions.filter(opt => opt !== option.value));
                      }
                    }}
                    className="sr-only"
                  />
                  <div className={`p-4 rounded-lg border-2 transition-all ${
                    selectedReorderOptions.includes(option.value)
                      ? 'border-green-400 bg-green-400/10'
                      : 'border-gray-600 hover:border-gray-500'
                  }`}>
                    <div className="flex items-center gap-2 mb-2">
                      <div className={`w-4 h-4 rounded border-2 flex items-center justify-center ${
                        selectedReorderOptions.includes(option.value)
                          ? 'border-green-400 bg-green-400'
                          : 'border-gray-500'
                      }`}>
                        {selectedReorderOptions.includes(option.value) && (
                          <span className="text-black text-xs">✓</span>
                        )}
                      </div>
                      <h3 className="font-semibold">{option.label}</h3>
                    </div>
                    <p className="text-sm text-gray-400">{option.desc}</p>
                  </div>
                </label>
              ))}
            </div>
            
            <button
              onClick={organizePlaylist}
              disabled={isProcessing || selectedReorderOptions.length === 0}
              className="w-full px-6 py-3 bg-green-600 hover:bg-green-700 disabled:bg-gray-600 rounded-lg transition-colors font-medium flex items-center justify-center gap-2"
            >
              {isProcessing ? (
                <>
                  <RefreshCw className="w-5 h-5 animate-spin" />
                  Organizing playlist...
                </>
              ) : (
                <>
                  <Play className="w-5 h-5" />
                  Organize playlist
                </>
              )}
            </button>
          </div>
        )}

        {/* Organized Groups */}
        {organizedGroups.length > 0 && (
          <div className="bg-gray-800 rounded-xl p-6 mb-8 border border-gray-700">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-semibold flex items-center gap-2">
                <Music className="w-6 h-6" />
                Organized playlist ({organizedGroups.length} groups)
              </h2>
              <div className="flex gap-3">
                <button
                  onClick={organizePlaylist}
                  disabled={isProcessing || selectedReorderOptions.length === 0}
                  className="px-4 py-2 bg-purple-600 hover:bg-purple-700 disabled:bg-gray-600 rounded-lg transition-colors flex items-center gap-2"
                >
                  <RefreshCw className="w-4 h-4" />
                  Refresh order
                </button>
                <button
                  onClick={exportToCSV}
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg transition-colors flex items-center gap-2"
                >
                  <Download className="w-4 h-4" />
                  Export simple CSV
                </button>
                <button
                  onClick={exportToDetailedCSV}
                  className="px-4 py-2 bg-blue-500 hover:bg-blue-600 rounded-lg transition-colors flex items-center gap-2"
                >
                  <FileText className="w-4 h-4" />
                  Export detailed CSV
                </button>
                <button
                  onClick={exportToSpotify}
                  className="px-4 py-2 bg-green-600 hover:bg-green-700 rounded-lg transition-colors flex items-center gap-2"
                >
                  <Save className="w-4 h-4" />
                  Export to Spotify
                </button>
              </div>
            </div>

            <div className="space-y-6">
              {organizedGroups.map((group, groupIndex) => (
                <div key={group.id} className="bg-gray-700 rounded-lg p-4 border border-gray-600">
                  <div className="flex items-center justify-between mb-4">
                    <h3 className="text-lg font-semibold text-green-400">
                      Group {groupIndex + 1}: {group.rule} - {group.ruleValue}
                    </h3>
                    <div className="flex gap-2">
                      <button
                        onClick={() => moveGroup(groupIndex, 'up')}
                        disabled={groupIndex === 0}
                        className="p-1 bg-gray-600 hover:bg-gray-500 disabled:bg-gray-800 disabled:text-gray-500 rounded transition-colors"
                        title="Move group up"
                      >
                        <ChevronUp className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => moveGroup(groupIndex, 'down')}
                        disabled={groupIndex === organizedGroups.length - 1}
                        className="p-1 bg-gray-600 hover:bg-gray-500 disabled:bg-gray-800 disabled:text-gray-500 rounded transition-colors"
                        title="Move group down"
                      >
                        <ChevronDown className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                  
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    {group.songs.map((song, songIndex) => (
                      <div key={song.id} className="bg-gray-600 rounded p-3 border border-gray-500">
                        <div className="flex items-start justify-between mb-2">
                          <div className="flex-1 min-w-0">
                            <h4 className="font-medium truncate">{song.title}</h4>
                            <p className="text-sm text-gray-300 truncate">{song.artist}</p>
                          </div>
                          <span className="text-xs text-green-400 ml-2">#{songIndex + 1}</span>
                        </div>
                        <div className="text-xs text-gray-400 space-y-1">
                          <div className="flex justify-between">
                            <span>{song.genre}</span>
                            <span>{song.era}</span>
                          </div>
                          <div className="flex justify-between">
                            <span>{song.pace} pace</span>
                            <span>{Math.round(song.tempo)} BPM</span>
                          </div>
                        </div>
                        <div className="flex gap-1 mt-3">
                          <button
                            onClick={() => openReplacementModal(groupIndex, songIndex, false)}
                            className="flex-1 px-2 py-1 bg-gray-500 hover:bg-gray-400 text-xs rounded transition-colors flex items-center justify-center gap-1"
                          >
                            <Brain className="w-3 h-3" />
                            Existing
                          </button>
                          <button
                            onClick={() => openReplacementModal(groupIndex, songIndex, true)}
                            disabled={isLoadingInternetSuggestions}
                            className="flex-1 px-2 py-1 bg-blue-500 hover:bg-blue-400 disabled:bg-blue-600 text-xs rounded transition-colors flex items-center justify-center gap-1"
                          >
                            {isLoadingInternetSuggestions ? (
                              <RefreshCw className="w-3 h-3 animate-spin" />
                            ) : (
                              <Globe className="w-3 h-3" />
                            )}
                            Internet AI
                          </button>
                          <button
                            onClick={() => openEditModal(groupIndex, songIndex)}
                            className="flex-1 px-2 py-1 bg-green-500 hover:bg-green-400 text-xs rounded transition-colors flex items-center justify-center gap-1"
                          >
                            <FileText className="w-3 h-3" />
                            Edit
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Replacement Modal */}
        {showReplacementModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-gray-800 rounded-xl max-w-2xl w-full max-h-[80vh] overflow-y-auto border border-gray-700">
              <div className="p-6">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-xl font-semibold text-white">
                    Replace song - suggestions
                  </h3>
                  <button
                    onClick={() => setShowReplacementModal(false)}
                    className="text-gray-400 hover:text-white text-2xl"
                  >
                    ×
                  </button>
                </div>
                
                {replacementData.groupIndex >= 0 && (
                  <div className="mb-4 p-3 bg-gray-700 rounded-lg">
                    <h4 className="font-medium text-green-400 mb-2">Current song:</h4>
                    <div className="text-white">
                      <div className="font-medium">
                        {organizedGroups[replacementData.groupIndex]?.songs[replacementData.songIndex]?.title}
                      </div>
                      <div className="text-gray-300 text-sm">
                        by {organizedGroups[replacementData.groupIndex]?.songs[replacementData.songIndex]?.artist}
                      </div>
                    </div>
                  </div>
                )}
                
                <div className="space-y-3">
                  {replacementData.suggestions.length > 0 ? (
                    replacementData.suggestions.map((suggestion, index) => (
                      <div key={suggestion.id} className={`p-4 rounded-lg border-2 transition-colors ${
                        suggestion.source === 'internet_ai'
                          ? 'bg-blue-900/30 border-blue-400 hover:border-blue-300' 
                          : suggestion.source === 'ai_knowledge'
                          ? 'bg-purple-900/30 border-purple-400 hover:border-purple-300'
                          : suggestion.source === 'group_mining'
                          ? 'bg-orange-900/30 border-orange-400 hover:border-orange-300'
                          : 'bg-gray-700 border-gray-600 hover:border-green-400'
                      }`}>
                        {/* Source Badge */}
                        <div className="flex items-center justify-between mb-2">
                          <div className={`px-2 py-1 rounded-full text-xs font-semibold ${
                            suggestion.source === 'internet_ai'
                              ? 'bg-blue-500 text-white' 
                              : suggestion.source === 'ai_knowledge'
                              ? 'bg-purple-500 text-white'
                              : suggestion.source === 'group_mining'
                              ? 'bg-orange-500 text-white'
                              : 'bg-green-500 text-white'
                          }`}>
                            {suggestion.source === 'internet_ai'
                              ? '🌐 Internet AI suggestion' 
                              : suggestion.source === 'ai_knowledge'
                              ? '🧠 AI knowledge'
                              : suggestion.source === 'group_mining'
                              ? `📁 From group ${suggestion.sourceGroup + 1}`
                              : '🎵 From your playlist'
                            }
                          </div>
                          <button
                            onClick={() => handleSongReplacement(suggestion)}
                            className={`px-4 py-2 rounded-lg transition-colors font-medium ${
                              suggestion.source === 'internet_ai'
                                ? 'bg-blue-600 hover:bg-blue-700 text-white' 
                                : suggestion.source === 'ai_knowledge'
                                ? 'bg-purple-600 hover:bg-purple-700 text-white'
                                : suggestion.source === 'group_mining'
                                ? 'bg-orange-600 hover:bg-orange-700 text-white'
                                : 'bg-green-600 hover:bg-green-700 text-white'
                            }`}
                          >
                            {suggestion.source === 'internet_ai' ? 'Add to playlist' : 'Use this song'}
                          </button>
                        </div>

                        <div className="flex items-center justify-between">
                          <div className="flex-1">
                            <h5 className="font-medium text-white mb-1">{suggestion.title}</h5>
                            <p className="text-gray-300 text-sm mb-2">by {suggestion.artist}</p>
                            
                            {suggestion.album && (
                              <p className="text-gray-400 text-xs mb-2">Album: {suggestion.album}</p>
                            )}
                            
                            <div className="grid grid-cols-2 gap-2 text-xs text-gray-400 mb-2">
                              <div>Genre: {suggestion.genre}</div>
                              <div>Era: {suggestion.era}</div>
                              <div>Pace: {suggestion.pace}</div>
                              <div>Tempo: {Math.round(suggestion.tempo)} BPM</div>
                            </div>
                            
                            {/* Source-specific information */}
                            <div className="text-xs">
                              {suggestion.source === 'internet_ai' ? (
                                <div className="bg-blue-800/50 p-2 rounded border border-blue-500">
                                  <div className="text-blue-300 font-semibold mb-1">
                                    ✨ AI Confidence: {(suggestion.similarity * 100).toFixed(0)}%
                                  </div>
                                  <div className="text-blue-200 italic text-xs">
                                    💡 {suggestion.reasoning}
                                  </div>
                                  <div className="text-blue-400 text-xs mt-1">
                                    This song comes from internet AI suggestions and would be a great addition to your playlist!
                                  </div>
                                </div>
                              ) : suggestion.source === 'ai_knowledge' ? (
                                <div className="bg-purple-800/50 p-2 rounded border border-purple-500">
                                  <div className="text-purple-300 font-semibold mb-1">
                                    ✨ AI Confidence: {(suggestion.similarity * 100).toFixed(0)}%
                                  </div>
                                  <div className="text-purple-200 italic text-xs">
                                    💡 {suggestion.aiReasoning}
                                  </div>
                                  <div className="text-purple-400 text-xs mt-1">
                                    This song comes from Claude's music knowledge and would be a great addition to your playlist!
                                  </div>
                                </div>
                              ) : suggestion.source === 'group_mining' ? (
                                <div className="bg-orange-800/50 p-2 rounded border border-orange-500">
                                  <div className="text-orange-300 font-semibold">
                                    📊 Group fit score: {(suggestion.groupFitScore * 100).toFixed(0)}%
                                  </div>
                                  <div className="text-orange-400 text-xs mt-1">
                                    This song is currently in group {suggestion.sourceGroup + 1} but would fit better here
                                  </div>
                                </div>
                              ) : (
                                <div className="bg-green-800/50 p-2 rounded border border-green-500">
                                  <div className="text-green-300 font-semibold">
                                    🎯 Similarity score: {(suggestion.similarity * 100).toFixed(0)}%
                                  </div>
                                  <div className="text-green-400 text-xs mt-1">
                                    This song is already in your playlist but not yet organized
                                  </div>
                                </div>
                              )}
                            </div>
                          </div>
                        </div>
                      </div>
                    ))
                  ) : (
                    <div className="text-center py-8 text-gray-400">
                      <p>No suitable replacement suggestions found.</p>
                      <p className="text-sm mt-2">Try adjusting your grouping rules or adding more songs to your playlist.</p>
                    </div>
                  )}
                </div>
                
                <div className="mt-6 flex justify-end">
                  <button
                    onClick={() => setShowReplacementModal(false)}
                    className="px-4 py-2 bg-gray-600 hover:bg-gray-500 text-white rounded-lg transition-colors"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Edit Song Modal */}
        {showEditModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-gray-800 rounded-xl max-w-md w-full border border-gray-700">
              <div className="p-6">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-xl font-semibold text-white">
                    Edit song details
                  </h3>
                  <button
                    onClick={closeEditModal}
                    className="text-gray-400 hover:text-white text-2xl"
                  >
                    ×
                  </button>
                </div>
                
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-1">Song title</label>
                    <input
                      type="text"
                      value={editSongData.title}
                      onChange={(e) => setEditSongData({...editSongData, title: e.target.value})}
                      className="w-full px-3 py-2 bg-gray-700 text-white rounded-lg border border-gray-600 focus:border-green-400 focus:outline-none"
                    />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-1">Artist name</label>
                    <input
                      type="text"
                      value={editSongData.artist}
                      onChange={(e) => setEditSongData({...editSongData, artist: e.target.value})}
                      className="w-full px-3 py-2 bg-gray-700 text-white rounded-lg border border-gray-600 focus:border-green-400 focus:outline-none"
                    />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-300 mb-1">Album name</label>
                    <input
                      type="text"
                      value={editSongData.album}
                      onChange={(e) => setEditSongData({...editSongData, album: e.target.value})}
                      className="w-full px-3 py-2 bg-gray-700 text-white rounded-lg border border-gray-600 focus:border-green-400 focus:outline-none"
                    />
                  </div>
                  
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="block text-sm font-medium text-gray-300 mb-1">Genre</label>
                      <select
                        value={editSongData.genre}
                        onChange={(e) => setEditSongData({...editSongData, genre: e.target.value})}
                        className="w-full px-3 py-2 bg-gray-700 text-white rounded-lg border border-gray-600 focus:border-green-400 focus:outline-none"
                      >
                        <option value="Pop">Pop</option>
                        <option value="Rock/Alternative">Rock/Alternative</option>
                        <option value="Hip Hop/Rap">Hip Hop/Rap</option>
                        <option value="Electronic">Electronic</option>
                        <option value="R&B/Soul">R&B/Soul</option>
                        <option value="Country">Country</option>
                        <option value="Jazz">Jazz</option>
                        <option value="Classical">Classical</option>
                      </select>
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium text-gray-300 mb-1">Era</label>
                      <select
                        value={editSongData.era}
                        onChange={(e) => setEditSongData({...editSongData, era: e.target.value})}
                        className="w-full px-3 py-2 bg-gray-700 text-white rounded-lg border border-gray-600 focus:border-green-400 focus:outline-none"
                      >
                        <option value="60s">60s</option>
                        <option value="70s">70s</option>
                        <option value="80s">80s</option>
                        <option value="90s">90s</option>
                        <option value="2000s">2000s</option>
                        <option value="2010s">2010s</option>
                        <option value="2020s">2020s</option>
                        <option value="Classic">Classic</option>
                      </select>
                    </div>
                  </div>
                  
                  <div className="grid grid-cols-3 gap-3">
                    <div>
                      <label className="block text-sm font-medium text-gray-300 mb-1">Pace</label>
                      <select
                        value={editSongData.pace}
                        onChange={(e) => setEditSongData({...editSongData, pace: e.target.value})}
                        className="w-full px-3 py-2 bg-gray-700 text-white rounded-lg border border-gray-600 focus:border-green-400 focus:outline-none"
                      >
                        <option value="Low">Low</option>
                        <option value="Medium">Medium</option>
                        <option value="High">High</option>
                      </select>
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium text-gray-300 mb-1">Tempo (BPM)</label>
                      <input
                        type="number"
                        value={editSongData.tempo}
                        onChange={(e) => setEditSongData({...editSongData, tempo: e.target.value})}
                        className="w-full px-3 py-2 bg-gray-700 text-white rounded-lg border border-gray-600 focus:border-green-400 focus:outline-none"
                        min="60"
                        max="200"
                      />
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium text-gray-300 mb-1">Key</label>
                      <select
                        value={editSongData.key}
                        onChange={(e) => setEditSongData({...editSongData, key: e.target.value})}
                        className="w-full px-3 py-2 bg-gray-700 text-white rounded-lg border border-gray-600 focus:border-green-400 focus:outline-none"
                      >
                        {['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'].map((key, index) => (
                          <option key={index} value={index}>{key}</option>
                        ))}
                      </select>
                    </div>
                  </div>
                </div>
                
                <div className="mt-6 flex justify-end gap-3">
                  <button
                    onClick={closeEditModal}
                    className="px-4 py-2 bg-gray-600 hover:bg-gray-500 text-white rounded-lg transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handleManualSongEdit}
                    className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors"
                  >
                    Save changes
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Instructions */}
        <div className="bg-gray-800 rounded-xl p-6 border border-gray-700">
          <h2 className="text-xl font-semibold mb-4">How it works</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-sm text-gray-300">
            <div>
              <h3 className="font-semibold text-white mb-2">The "group of three" rule</h3>
              <ul className="space-y-1">
                <li>• Songs are grouped into sets of 3 based on similarity</li>
                <li>• Groups can be by genre, era, or pace/energy</li>
                <li>• AI suggests alternatives when exact matches aren't available</li>
                <li>• Groups are distributed evenly throughout the playlist</li>
              </ul>
            </div>
            <div>
              <h3 className="font-semibold text-white mb-2">Enhanced suggestions</h3>
              <ul className="space-y-1">
                <li>• <strong>Existing suggestions:</strong> From your playlist and AI knowledge</li>
                <li>• <strong>Internet AI suggestions:</strong> Fresh recommendations from the web</li>
                <li>• Smart transitions analyze tempo, key, and energy</li>
                <li>• Color-coded suggestions show different sources</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SpotifyPlaylistOrganizer;