#!/usr/bin/env python3
"""
Flask proxy server for Ollama local LLM to bypass CORS issues
"""

from flask import Flask, request, jsonify
import requests
import os
import json

app = Flask(__name__)

# Ollama API configuration (default local port)
OLLAMA_API_URL = 'http://localhost:11434/api/generate'
OLLAMA_MODEL = 'llama2'  # Default model, can be changed to mistral, neural-chat, etc.

# Enable CORS
from flask_cors import CORS
CORS(app)

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
    print("🚀 Starting Ollama Proxy Server on http://localhost:5000")
    print(f"📡 Proxying to: {OLLAMA_API_URL}")
    print(f"🤖 Model: {OLLAMA_MODEL}")
    print("\n⚠️  Make sure Ollama is running!")
    print("   Run this in another terminal: ollama serve")
    app.run(debug=False, host='localhost', port=5000)
