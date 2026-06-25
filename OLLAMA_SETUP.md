# 🤖 MIXMASTER with Ollama - Complete Setup Guide

## What is Ollama?

Ollama is a free, open-source tool that runs large language models (like LLaMA) locally on your computer. This means:

✅ **Completely Free** - No API keys, no costs, no subscriptions
✅ **Unlimited Usage** - No rate limits
✅ **Works Offline** - Everything runs on your machine
✅ **Privacy** - Your data never leaves your computer
✅ **Fast** - Local inference is quick

## Installation Steps

### Step 1: Download Ollama

Download the Ollama installer for Windows from the official website:
https://ollama.ai

Or download directly from GitHub:
https://github.com/ollama/ollama/releases

**Note:** On Windows, it installs as a background service.

### Step 2: Start Ollama

After installation, Ollama runs automatically in the background. To verify it's running:

```powershell
# Check if Ollama service is running
Get-Service ollama -ErrorAction SilentlyContinue | Select-Object Status
```

### Step 3: Download a Model

Ollama needs models to run. The first time you use it, it will download the model automatically. The most popular options are:

**LLaMA 2** (Default - good balance of speed and quality)
```bash
ollama pull llama2
```

**Mistral** (Faster, lightweight)
```bash
ollama pull mistral
```

**Neural Chat** (Optimized for conversation)
```bash
ollama pull neural-chat
```

**To change the default model**, edit `gemini_proxy.py` and change:
```python
OLLAMA_MODEL = 'llama2'  # Change to 'mistral', 'neural-chat', etc.
```

### Step 4: Start the Proxy Server

Open a terminal and run:

```powershell
cd c:\Users\RandyWinjum\Mixmaster
python gemini_proxy.py
```

You should see:
```
🚀 Starting Ollama Proxy Server on http://localhost:5000
📡 Proxying to: http://localhost:11434/api/generate
🤖 Model: llama2

⚠️  Make sure Ollama is running!
   Run this in another terminal: ollama serve
```

### Step 5: Verify Everything is Working

In another PowerShell terminal:

```powershell
# Check proxy status
curl http://localhost:5000/health

# Check Ollama connection
curl http://localhost:5000/api/status
```

### Step 6: Start the App

In a third terminal:

```powershell
cd c:\Users\RandyWinjum\Mixmaster
python -m http.server 8000
```

Then open: **http://localhost:8000/mixmaster_complete.html**

## Terminal Setup Summary

You need **3 terminals** running:

1. **Terminal 1 - Ollama Service**
   - Ollama runs as a Windows service automatically
   - Or manually start: `ollama serve`

2. **Terminal 2 - Proxy Server**
   ```powershell
   cd c:\Users\RandyWinjum\Mixmaster
   python gemini_proxy.py
   ```

3. **Terminal 3 - Web Server**
   ```powershell
   cd c:\Users\RandyWinjum\Mixmaster
   python -m http.server 8000
   ```

## Troubleshooting

### Problem: "Cannot connect to Ollama"
**Solution:** Make sure Ollama is running. Ollama runs as a service on port 11434.

### Problem: App is slow
**Solution:** 
- LLaMA 2 can be slow on older machines
- Try `mistral` for faster responses (lightweight)
- Or wait for the first response (models cache after first use)

### Problem: Out of memory errors
**Solution:**
- Use a smaller model: `ollama pull mistral` (3.5B parameters)
- Reduce context window in `gemini_proxy.py`

### Problem: Cannot download model
**Solution:**
```powershell
# Check disk space - models are 5-10GB
Get-Volume

# Try downloading directly
ollama pull llama2
```

## Available Models

| Model | Size | Speed | Quality | Best For |
|-------|------|-------|---------|----------|
| `mistral` | 4GB | Fast | Good | Quick responses |
| `llama2` | 4GB | Medium | Better | Balanced |
| `neural-chat` | 4GB | Medium | Good | Conversation |
| `dolphin-mixtral` | 26GB | Slow | Excellent | High quality |

Start with `mistral` or `llama2`.

## Performance Tips

1. **First Run:** Model loading takes time. Be patient!
2. **Caching:** Responses get faster after first use
3. **GPU Support:** Ollama automatically uses GPU if available (NVIDIA/AMD)
4. **Memory:** Close other apps to free up RAM for better performance

## API Features

The proxy server at `http://localhost:5000` provides:

- **`GET /health`** - Check if proxy is running
- **`GET /api/status`** - Check Ollama connection and available models
- **`POST /api/ollama`** - Send prompts to Ollama
  ```json
  {
    "prompt": "Your question here"
  }
  ```

## Next Steps

1. ✅ Download Ollama from https://ollama.ai
2. ✅ Start Ollama (or it starts automatically)
3. ✅ Download a model: `ollama pull llama2`
4. ✅ Start proxy: `python gemini_proxy.py`
5. ✅ Start web server: `python -m http.server 8000`
6. ✅ Open http://localhost:8000/mixmaster_complete.html
7. ✅ Enjoy unlimited AI features! 🎵

## Resources

- Official Ollama: https://ollama.ai
- Models: https://ollama.ai/library
- GitHub: https://github.com/ollama/ollama
- Docs: https://github.com/ollama/ollama/blob/main/README.md

---

**Enjoy your free, unlimited AI-powered DJ playlist organizer!** 🎉
