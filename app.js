// --- FULL UI/UX update for context menu, modal, and Export CSV reliability ---
document.addEventListener('DOMContentLoaded', function() {
  const fileInput = document.getElementById('csvfile');
  const uploadLabel = document.getElementById('csv-label');
  const tip = document.getElementById('uploaded-file-tip');
  const btnSample = document.getElementById('btnSample');
  const uploadBoxContent = document.getElementById('dj-upload-box-content');
  const fileLabel = document.getElementById('dj-upload-file-label');
  const songCount = document.getElementById('dj-song-count');
  const reorderSection = document.getElementById('dj-reorder-section');
  const organizeBtn = document.getElementById('btnOrganize');

  let loadedSongs = [];
  let groups = [];
  let groupRules = [];
  let groupRuleNames = {
    'genre': 'By genre',
    'era': 'By era',
    'pace': 'By pace',
    'genre+era': 'By genre+era',
    'pace+era': 'By pace+era'
  };

  const genres = ["Pop", "Rock", "Hip-Hop", "Dance", "Electronic", "Soul"];
  const paces = ["Slow", "Medium", "High"];
  const eras = ["1960s", "1970s", "1980s", "1990s", "2000s", "2010s", "2020s"];
  const sampleSongs = [
    { title: "Bohemian Rhapsody", artist: "Queen", album: "A Night At The Opera", genre: "Rock", pace: "Medium", era: "1970s", bpm: 144 },
    { title: "Billie Jean", artist: "Michael Jackson", album: "Thriller", genre: "Pop", pace: "High", era: "1980s", bpm: 117 },
    { title: "Hey Ya!", artist: "OutKast", album: "Speakerboxxx/The Love Below", genre: "Hip-Hop", pace: "High", era: "2000s", bpm: 160 },
    { title: "Stairway To Heaven", artist: "Led Zeppelin", album: "Led Zeppelin IV", genre: "Rock", pace: "Medium", era: "1970s", bpm: 82 },
    { title: "Beat It", artist: "Michael Jackson", album: "Thriller", genre: "Pop", pace: "High", era: "1980s", bpm: 138 },
    { title: "Smells Like Teen Spirit", artist: "Nirvana", album: "Nevermind", genre: "Rock", pace: "High", era: "1990s", bpm: 116 }
  ];

  // --- Helpers ---
  function getEraFromYear(year) {
    if (!year) return "Unknown";
    if (year >= 2020) return "2020s";
    if (year >= 2010) return "2010s";
    if (year >= 2000) return "2000s";
    if (year >= 1990) return "1990s";
    if (year >= 1980) return "1980s";
    if (year >= 1970) return "1970s";
    if (year >= 1960) return "1960s";
    return "Classic";
  }
  function randomArr(arr) { return arr[Math.floor(Math.random()*arr.length)]; }
  function paceFromBPM(bpm) { if (!bpm) return "Medium"; if (bpm < 90) return "Slow"; if (bpm < 130) return "Medium"; return "High"; }
  function parseSpotifyCSV(text) {
    const lines = text.trim().split(/\r?\n/);
    if (!lines.length) return [];
    const headers = lines[0].split(',').map(h => h.replace(/^"|"$/g, '').trim());
    const colTrack = headers.findIndex(h => h.toLowerCase().includes("track name"));
    const colArtist = headers.findIndex(h => h.toLowerCase().includes("artist"));
    const colAlbum = headers.findIndex(h => h.toLowerCase().includes("album"));
    const colGenre = headers.findIndex(h => h.toLowerCase().includes("genre"));
    const colBPM = headers.findIndex(h => h.toLowerCase().includes("bpm") || h.toLowerCase().includes("tempo"));
    const colYear = headers.findIndex(h => h.toLowerCase().includes("release year") || h.toLowerCase().includes("year"));
    const colPace = headers.findIndex(h => h.toLowerCase().includes("pace"));
    return lines.slice(1).map((line, idx) => {
      let cells = [], cell = '', inQuotes = false;
      for (let i = 0; i < line.length; i++) {
        let c = line[i];
        if (c === '"' && line[i+1] === '"') { cell += '"'; i++; }
        else if (c === '"') inQuotes = !inQuotes;
        else if (c === ',' && !inQuotes) { cells.push(cell); cell = ''; }
        else cell += c;
      }
      cells.push(cell);
      let title = (cells[colTrack] || '').replace(/^"|"$/g, '');
      let artist = (cells[colArtist] || '').replace(/^"|"$/g, '');
      let album = (cells[colAlbum] || '').replace(/^"|"$/g, '');
      let genre = colGenre>=0 ? (cells[colGenre]||'') : '';
      let bpm = colBPM>=0 ? parseInt(cells[colBPM])||null : null;
      let year = colYear>=0 ? parseInt(cells[colYear])||null : null;
      let era = year ? getEraFromYear(year) : (randomArr(eras));
      let pace = colPace>=0 ? (cells[colPace]||'') : paceFromBPM(bpm);
      if (!genre) genre = randomArr(genres);
      if (!pace) pace = randomArr(paces);
      if (!bpm) bpm = 80 + ((idx * 23) % 100); // fallback
      return { title, artist, album, genre, pace, era, bpm };
    }).filter(s => s.title && s.artist);
  }
  function updateSongCount(count) { songCount.textContent = count; tip.innerHTML = `✓ <span id="dj-song-count">${count}</span> songs loaded`; }
  function updateUploadDisplay(file) {
    if(file) { fileLabel.textContent = file.name; uploadBoxContent.classList.add('file-loaded'); }
    else { fileLabel.textContent = 'Click to upload your Spotify CSV file'; uploadBoxContent.classList.remove('file-loaded'); loadedSongs = []; updateSongCount(0); }
  }
  function makeGroups(songs, rules) {
    const groups = [];
    let groupIdx = 0;
    for (let i = 0; i < songs.length; i += 3) {
      const groupRuleKey = (rules && rules.length) ? rules[groupIdx % rules.length] : '';
      groups.push({ rule: groupRuleKey, songs: songs.slice(i, i + 3) });
      groupIdx++;
    }
    return groups;
  }

  // --- context menu code ---
  let contextMenuEl = null;
  function closeContextMenu() {
  console.log('closeContextMenu called');
    if (contextMenuEl) { 
    contextMenuEl.remove(); 
    contextMenuEl = null; 
    console.log('Context menu closed');
  }
    document.removeEventListener('mouseup', clickOutsideContextMenu, true);
  }
  function openContextMenu(x, y, groupIdx, songIdx, sourceButtonEl) {
  closeContextMenu();
  const song = groups[groupIdx].songs[songIdx];
  const allSongs = [].concat(...groups.map(g => g.songs));
  let suggestions = allSongs.filter((s, i) => !(s.title === song.title && s.artist === song.artist));
  suggestions = suggestions.slice(0, 6);

  // Create modal overlay similar to existing modals
  const modal = document.createElement('div');
  modal.className = 'dj-modal-bg';
  modal.innerHTML = `
    <div class="dj-modal dj-modal-wide">
      <div class="modal-title-block"><span style="color:#96ff9c;font-weight:600">Current song:</span><br>
        <div style="color:#e2ffd8;font-size:1.17em;margin-bottom:.8em;">${song.title}</div>
        <div style="color:#b1f8c9;font-size:.99em">by ${song.artist}</div>
      </div>
      <h3>Suggestions from this playlist</h3>
      <div class="replacement-suggestions-container">
        ${suggestions.map((sug, i) => `
          <div class="suggestion-replacement-list">
            <div class="replacement-label">From this playlist</div>
            <div class="replacement-main-info">${sug.title}<div class="subartist">by ${sug.artist}</div></div>
            <div class="replacement-sub-info">Album: ${sug.album}<br>Genre: ${sug.genre} · Pace: ${sug.pace} · Era: ${sug.era} · BPM: ${sug.bpm}</div>
            <button class="replace-btn replacement-use-btn" data-i="${i}" style="float:right">Use this song</button>
          </div>
        `).join('')}
      </div>
      <div style="margin-top:2em;text-align:right"><button class="modal-btn cancel">Cancel</button></div>
    </div>
  `;
  document.body.appendChild(modal);
  modal.querySelector('.cancel').onclick = () => {
    modal.remove();
  };
  modal.querySelectorAll('.replacement-use-btn').forEach((btn, i) => {
    btn.onclick = () => {
      groups[groupIdx].songs[songIdx] = Object.assign({}, suggestions[i]);
      renderAll();
      modal.remove();
    };
  });
}
  closeContextMenu();
  console.log('openContextMenu called', {x, y, groupIdx, songIdx});
    const menu = document.createElement('div');
  menu.className = 'dj-cmenu';
  menu.innerHTML = `
    <div class="dj-cmenu-item dj-cmenu-title" tabindex="-1"><b>Suggest a replacement</b></div>
    <div class="dj-cmenu-item" tabindex="0" data-action="list">Another song from this list</div>
    <div class="dj-cmenu-item" tabindex="0" data-action="ai">From AI/Internet</div>
    <div class="dj-cmenu-sep"></div>
    <div class="dj-cmenu-item" tabindex="0" data-action="manual">Edit song details manually</div>
  `;
  document.body.appendChild(menu);
  // Position below the button if provided
  if (sourceButtonEl) {
    const rect = sourceButtonEl.getBoundingClientRect();
    x = rect.left + window.scrollX;
    y = rect.bottom + window.scrollY + 4;
  }
  let width = menu.offsetWidth || 220;
  let height = menu.offsetHeight || 180;
  let winW = window.innerWidth;
  let winH = window.innerHeight;
  if (x + width > winW) x = winW - width - 8;
  if (y + height > winH) y = winH - height - 8;
  if (x < 0) x = 0;
  if (y < 0) y = 0;
  menu.style.left = x + 'px';
  menu.style.top = y + 'px';
  menu.style.position = 'absolute';
  console.log('Context menu appended at', x, y);
    menu.style.left = x + 'px';
    menu.style.top = y + 'px';
    contextMenuEl = menu;
    // HANDLERS for new clickable .dj-cmenu-item
    menu.querySelectorAll('.dj-cmenu-item[data-action]').forEach(item => {
      item.addEventListener('click', function(e) {
        const action = item.getAttribute('data-action');
        if (action === 'list') { console.log('Same-list clicked'); closeContextMenu(); showListReplaceModal(groupIdx, songIdx); }
        else if (action === 'ai') { console.log('AI clicked'); closeContextMenu(); showAiReplaceModal(groupIdx, songIdx); }
        else if (action === 'manual') { console.log('Manual clicked'); closeContextMenu(); showEditSongDetailsModal(groupIdx, songIdx); }
      });
      item.addEventListener('keydown', function(e) {
        if (e.key === "Enter" || e.key === " ") item.click();
      });
    });
    setTimeout(function() {
      document.addEventListener('mouseup', clickOutsideContextMenu, true);
      menu.addEventListener('mouseup', function(e) {
        e.stopPropagation();
        console.log('Click inside menu');
      });
    }, 30);
  }
  function clickOutsideContextMenu(e) {
  console.log('Clicked outside context menu', e.target);
    if (contextMenuEl && !contextMenuEl.contains(e.target)) closeContextMenu();
  }

  // --- MODAL COMPONENTS ---
  // (Remains unchanged)
  function showListReplaceModal(groupIdx, songIdx) { /* ... as in previous version ... */
    closeModal();
    let song = groups[groupIdx].songs[songIdx];
    let all = [].concat(...groups.map(g=>g.songs));
    let suggestions = all.filter((s,i) => !(s.title===song.title && s.artist===song.artist));
    shuffle(suggestions);
    suggestions = suggestions.slice(0,3);
    let modal = document.createElement('div');
    modal.className = 'dj-modal-bg';
    modal.innerHTML = `
      <div class="dj-modal dj-modal-wide">
        <div class="modal-title-block"><span style="color:#96ff9c;font-weight:600">Current song:</span><br>
          <div style="color:#e2ffd8;font-size:1.17em;margin-bottom:.8em;">${song.title}</div>
          <div style="color:#b1f8c9;font-size:.99em">by ${song.artist}</div>
        </div>
        <h3>Suggestions from this playlist</h3>
        ${suggestions.map((sug,i)=>`
          <div class="suggestion-replacement-list">
            <div class="replacement-label">From this playlist</div>
            <div class="replacement-main-info">${sug.title}<div class="subartist">by ${sug.artist}</div></div>
            <div class="replacement-sub-info">Album: ${sug.album}<br>Genre: ${sug.genre} · Pace: ${sug.pace} · Era: ${sug.era} · BPM: ${sug.bpm}</div>
            <button class="replace-btn replacement-use-btn" data-i="${i}" style="float:right">Use this song</button>
          </div>
        `).join('')}
        <div style="margin-top:2em;text-align:right"><button class="modal-btn cancel">Cancel</button></div>
      </div>
    `;
    document.body.appendChild(modal);
    modal.querySelector('.cancel').onclick = closeModal;
    modal.querySelectorAll('.replacement-use-btn').forEach((btn,i)=>{
      btn.onclick = ()=>{
        groups[groupIdx].songs[songIdx] = Object.assign({}, suggestions[i]);
        renderAll();
        closeModal();
      };
    });
  }
  function showAiReplaceModal(groupIdx, songIdx) { /* ... unchanged ... */
    closeModal();
    let song = groups[groupIdx].songs[songIdx];
    let aiSuggestions = [
      {source:'AI Conf. 93%', title:'Shape of You', artist:'Ed Sheeran', album:'÷ (Divide)', genre:'Pop/Dance', pace:'Medium', era:'2010s', bpm:96, comment:'Modern pop hit with tropical house influences and mass appeal'},
      {source:'AI Conf. 91%', title:'Don\'t Stop Me Now', artist:'Queen', album:'Jazz', genre:'Pop/Dance', pace:'High', era:'70s', bpm:156, comment:'High-energy rock anthem with universal dance appeal'},
      {source:'AI Conf. 85%', title:'Bohemian Rhapsody', artist:'Queen', album:'A Night at the Opera', genre:'Rock/Alternative', pace:'Medium', era:'70s', bpm:144, comment:'Timeless rock epic that works in almost any context'}
    ];
    let modal = document.createElement('div');
    modal.className = 'dj-modal-bg';
    modal.innerHTML = `
      <div class="dj-modal dj-modal-wide">
        <div class="modal-title-block"><span style="color:#96ff9c;font-weight:600">Current song:</span><br>
          <div style="color:#e2ffd8;font-size:1.17em;margin-bottom:.8em;">${song.title}</div>
          <div style="color:#b1f8c9;font-size:.99em">by ${song.artist}</div>
        </div>
        <h3>AI/Internet Suggestions</h3>
        ${aiSuggestions.map((sug,i)=>`
          <div class="suggestion-replacement-ai">
            <div class="replacement-label replacement-label-ai">Internet AI suggestion</div>
            <div class="replacement-main-info">${sug.title}<div class="subartist">by ${sug.artist}</div></div>
            <div class="replacement-sub-info">Album: ${sug.album}<br>Genre: ${sug.genre} · Pace: ${sug.pace} · Era: ${sug.era} · BPM: ${sug.bpm}</div>
            <div class="ai-comment"><b>⚡ ${sug.source}:</b> <span class="ai-main-comment">${sug.comment}</span></div>
            <button class="replace-btn replacement-use-btn" data-i="${i}" style="float:right">Add to playlist</button>
          </div>
        `).join('')}
        <div style="margin-top:2em;text-align:right"><button class="modal-btn cancel">Cancel</button></div>
      </div>
    `;
    document.body.appendChild(modal);
    modal.querySelector('.cancel').onclick = closeModal;
    modal.querySelectorAll('.replacement-use-btn').forEach((btn,i)=>{
      btn.onclick = ()=>{
        groups[groupIdx].songs[songIdx] = Object.assign({}, aiSuggestions[i]);
        renderAll();
        closeModal();
      };
    });
  }
  function showEditSongDetailsModal(groupIdx, songIdx) { /* ... unchanged ... */
    closeModal();
    let song = groups[groupIdx].songs[songIdx];
    let modal = document.createElement('div');
    modal.className = 'dj-modal-bg';
    modal.innerHTML = `
      <div class="dj-modal dj-modal-edit">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:1em;">
          <h3 style="margin:0">Edit song details</h3>
          <button class="modal-btn close">×</button>
        </div>
        <label>Song title<input type="text" class="modal-title" value="${song.title}"></label>
        <label>Artist name<input type="text" class="modal-artist" value="${song.artist}"></label>
        <label>Album name<input type="text" class="modal-album" value="${song.album}"></label>
        <div style="display:flex;gap:1em;">
          <label style="flex:1;">Genre
            <input type="text" class="modal-genre" value="${song.genre}"></label>
          <label style="flex:1;">Era
            <input type="text" class="modal-era" value="${song.era}"></label>
        </div>
        <div style="display:flex;gap:1em;">
          <label style="flex:1;">Pace
            <input type="text" class="modal-pace" value="${song.pace}"></label>
          <label style="flex:1;">Tempo (BPM)
            <input type="number" class="modal-bpm" value="${song.bpm}"></label>
        </div>
        <div class="dj-modal-btnrow">
          <button class="modal-btn cancel">Cancel</button>
          <button class="modal-btn save save-green">Save changes</button>
        </div>
      </div>
    `;
    document.body.appendChild(modal);
    modal.querySelector('.cancel').onclick = closeModal;
    modal.querySelector('.close').onclick = closeModal;
    modal.querySelector('.save').onclick = function() {
      song.title = modal.querySelector('.modal-title').value.trim();
      song.artist = modal.querySelector('.modal-artist').value.trim();
      song.album = modal.querySelector('.modal-album').value.trim();
      song.genre = modal.querySelector('.modal-genre').value.trim();
      song.pace = modal.querySelector('.modal-pace').value.trim();
      song.era = modal.querySelector('.modal-era').value.trim();
      song.bpm = parseInt(modal.querySelector('.modal-bpm').value)||null;
      renderAll();
      closeModal();
    };
  }

  function closeModal() {
    let m = document.querySelector('.dj-modal-bg');
    if(m) m.remove();
  }

  // --- Update song card action to show context menu ---
  function renderAll() {
    let prevResults = document.querySelector('.dj-results');
    if (prevResults) prevResults.remove();
    if (!groups.length) return;
    const results = document.createElement('div');
    results.className = 'dj-results';
    const bar = document.createElement('div');
    bar.style.display = 'flex';
    bar.style.justifyContent = 'flex-end';
    bar.style.gap = '1em';
    bar.style.marginBottom = '1.4em';
    bar.innerHTML = `
      <button class="dj-btn-sample" id="btnRefreshOrder" title="Shuffle/re-order playlist">🔄 Refresh order</button>
      <button class="dj-btn-sample" id="btnExportCSV" title="Export for Soundiiz">⬇️ Export CSV</button>
    `;
    results.appendChild(bar);
    const h2 = document.createElement('h2');
    h2.textContent = 'Organized Playlist';
    results.appendChild(h2);
    groups.forEach((group, idx) => {
      const groupDiv = document.createElement('div');
      groupDiv.className = 'dj-group';
      const groupTitle = document.createElement('div');
      groupTitle.className = 'dj-group-title';
      groupTitle.innerHTML = `Group ${idx + 1} (rule: ${groupRuleNames[group.rule] || group.rule})`;
      const moveControls = document.createElement('div');
      moveControls.className = 'dj-group-move-controls';
      moveControls.innerHTML = `
        <span style="font-size:.99em;color:#b8f7d6;padding-right:.6em;">Move group up/down</span>
        <button class="dj-move-btn" title="Move up" data-group="${idx}" data-dir="up">⬆️</button>
        <button class="dj-move-btn" title="Move down" data-group="${idx}" data-dir="down">⬇️</button>
      `;
      groupTitle.appendChild(moveControls);
      groupDiv.appendChild(groupTitle);
      const songsDiv = document.createElement('div');
      songsDiv.className = 'dj-group-songs';
      group.songs.forEach((song, songIdx) => {
        const card = document.createElement('div');
        card.className = 'dj-song-card';
        card.setAttribute('data-group', idx);
        card.setAttribute('data-index', songIdx);
        card.innerHTML = `
          <div class='song-num'>${idx * 3 + songIdx + 1}.</div>
          <div class='dj-song-title'>${song.title}</div>
          <div class='dj-song-meta'>${song.artist} &mdash; <span class='dj-song-album'><i>${song.album}</i></span></div>
          <div class='dj-song-fields'>
            <span>${song.genre}</span>
            <span>${song.era}</span>
            <span>${song.pace} pace</span>
            <span>${song.bpm} BPM</span>
          </div>
          <div class="dj-song-actions"><button class="dj-song-edit-btn" title="Edit" data-group="${idx}" data-index="${songIdx}">Edit</button></div>
        `;
        // --- context menu logic ---
        card.querySelector('.dj-song-edit-btn').addEventListener('click', function(e) {
  e.stopPropagation();
  openContextMenu(0, 0, idx, songIdx, e.currentTarget);
});
        songsDiv.appendChild(card);
      });
      groupDiv.appendChild(songsDiv);
      results.appendChild(groupDiv);
    });
    document.querySelector('.dj-header-gradient').appendChild(results);
    // Attach Export/Refresh buttons robustly
    setTimeout(() => {
      let btnExport = document.getElementById('btnExportCSV');
      if (btnExport) btnExport.onclick = exportCSV;
      let btnRefresh = document.getElementById('btnRefreshOrder');
      if (btnRefresh) btnRefresh.onclick = refreshOrder;
      document.querySelectorAll('.dj-move-btn').forEach(btn => { btn.onclick = moveGroupHandler; });
    }, 50);
  }

  // --- Button handlers (unchanged) ---
  function refreshOrder() {
    if (!loadedSongs.length) return;
    shuffle(loadedSongs);
    groups = makeGroups(loadedSongs, groupRules);
    renderAll();
  }
  function shuffle(array) {
    for (let i = array.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [array[i], array[j]] = [array[j], array[i]];
    }
  }
  function exportCSV() {
    if (!groups.length) return;
    let header = ['Title','Artist','Album','Genre','Pace','Era','BPM'];
    let csv = [header.join(",")];
    let songList = [].concat(...groups.map(g => g.songs));
    songList.forEach(song => {
      let row = [song.title, song.artist, song.album, song.genre, song.pace, song.era, song.bpm]
        .map(val => '"'+(val||'')+'"').join(",");
      csv.push(row);
    });
    let blob = new Blob([csv.join("\r\n")], {type: "text/csv"});
    let link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = 'playlist_soundiiz.csv';
    document.body.appendChild(link);
    link.click();
    setTimeout(() => link.remove(), 100);
  }
  function moveGroupHandler(e) {
    let idx = parseInt(e.target.getAttribute('data-group'));
    let dir = e.target.getAttribute('data-dir');
    if (dir === 'up' && idx > 0) {
      [groups[idx], groups[idx-1]] = [groups[idx-1], groups[idx]];
    } else if (dir === 'down' && idx < groups.length-1) {
      [groups[idx], groups[idx+1]] = [groups[idx+1], groups[idx]];
    }
    renderAll();
  }

  // -- Only show file input dialog if not clicking on the hidden input
  uploadLabel.addEventListener('click', function(e) {
  console.log('Upload label clicked');
  if (e.target !== fileInput) {
    fileInput.value = '';
    fileInput.click();
    e.preventDefault();
  }
});
  fileInput.addEventListener('click', function(e) { e.stopPropagation(); });

  // -- CSV upload: parse, update song count, clear results
  fileInput.addEventListener('change', function(e) {
  const file = fileInput.files[0];
  updateUploadDisplay(file);
  let prevResults = document.querySelector('.dj-results');
  if (prevResults) prevResults.remove();
  loadedSongs = [];
  groups = [];
  if (file) {
    const reader = new FileReader();
    reader.onload = function(evt) {
      loadedSongs = parseSpotifyCSV(evt.target.result);
      updateSongCount(loadedSongs.length);
      // Automatically organize after loading
      const selectedBoxes = Array.from(document.querySelectorAll('.dj-reorder-option input[type=checkbox]:checked'));
      groupRules = selectedBoxes.map(x=>x.value);
      groups = makeGroups(loadedSongs, groupRules);
      renderAll();
    };
    reader.readAsText(file);
    reorderSection.style.display = 'block';
  } else {
    updateSongCount(0);
    loadedSongs = [];
    groups = [];
  }
});

  // -- Sample: load but don't organize yet
  btnSample.onclick = function() {
    updateUploadDisplay({ name: 'Sample_playlist.csv' });
    reorderSection.style.display = 'block';
    let prevResults = document.querySelector('.dj-results');
    if (prevResults) prevResults.remove();
    loadedSongs = sampleSongs.slice();
    groups = [];
    updateSongCount(loadedSongs.length);
  };

  // -- Organize playlist button action
  organizeBtn.addEventListener('click', function() {
    console.log('Organize playlist clicked');
    console.log('Loaded songs:', loadedSongs);
    const selectedBoxes = Array.from(document.querySelectorAll('.dj-reorder-option input[type=checkbox]:checked'));
    groupRules = selectedBoxes.map(x=>x.value);
    console.log('Selected groupRules:', groupRules);
    groups = makeGroups(loadedSongs, groupRules);
    console.log('Groups created:', groups);
    let prevResults = document.querySelector('.dj-results');
    if (prevResults) prevResults.remove();
    renderAll();
  });

  reorderSection.style.display = 'block';
  loadedSongs = [];
  updateSongCount(0);
});
