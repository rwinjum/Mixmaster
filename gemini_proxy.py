#!/usr/bin/env python3
"""
Flask proxy server for Claude (Anthropic) API to bypass CORS issues
"""

from flask import Flask, request, jsonify
import requests
import os

app = Flask(__name__)

# Anthropic API configuration
ANTHROPIC_API_KEY = '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'
ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages'

# Enable CORS
from flask_cors import CORS
CORS(app)

@app.route('/api/claude', methods=['POST'])
def claude_proxy():
    """Proxy endpoint for Anthropic Claude API calls"""
    try:
        data = request.get_json()
        prompt = data.get('prompt')
        
        if not prompt:
            return jsonify({'error': 'No prompt provided'}), 400
        
        # Call Claude API
        response = requests.post(
            ANTHROPIC_API_URL,
            headers={
                'Content-Type': 'application/json',
                'x-api-key': ANTHROPIC_API_KEY,
                'anthropic-version': '2023-06-01'
            },
            json={
                'model': 'claude-3-5-sonnet-20241022',
                'max_tokens': 1024,
                'messages': [{
                    'role': 'user',
                    'content': prompt
                }]
            },
            timeout=30
        )
        
        # Handle rate limiting gracefully
        if response.status_code == 429:
            return jsonify({
                'error': 'Rate limit exceeded',
                'message': 'API rate limit exceeded. Please try again later.',
                'success': False
            }), 429
        
        if response.status_code != 200:
            return jsonify({
                'error': f'Claude API error: {response.status_code}',
                'details': response.text,
                'success': False
            }), response.status_code
        
        data = response.json()
        result_text = data['content'][0]['text']
        
        return jsonify({
            'success': True,
            'result': result_text
        })
    
    except requests.exceptions.Timeout:
        return jsonify({'error': 'Request timeout', 'success': False}), 504
    except requests.exceptions.RequestException as e:
        return jsonify({'error': str(e), 'success': False}), 500
    except (KeyError, IndexError) as e:
        return jsonify({'error': 'Unexpected API response format', 'details': str(e), 'success': False}), 500
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'ok', 'service': 'Claude Proxy', 'provider': 'Anthropic'})

if __name__ == '__main__':
    print("🚀 Starting Claude (Anthropic) Proxy Server on http://localhost:5000")
    print(f"📡 Proxying to: {ANTHROPIC_API_URL}")
    app.run(debug=False, host='localhost', port=5000)
