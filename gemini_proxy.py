#!/usr/bin/env python3
"""
Simple Flask proxy server for Gemini API to bypass CORS issues
"""

from flask import Flask, request, jsonify
import requests
import os

app = Flask(__name__)

# Gemini API configuration
GEMINI_API_KEY = 'AQ.Ab8RN6JHOAnaHpXtVJWPiNCIQc-unRsji2W9V750csk2Fx7jDw'
GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent'

# Enable CORS
from flask_cors import CORS
CORS(app)

@app.route('/api/gemini', methods=['POST'])
def gemini_proxy():
    """Proxy endpoint for Gemini API calls"""
    try:
        data = request.get_json()
        prompt = data.get('prompt')
        
        if not prompt:
            return jsonify({'error': 'No prompt provided'}), 400
        
        # Call Gemini API
        response = requests.post(
            f'{GEMINI_API_URL}?key={GEMINI_API_KEY}',
            headers={'Content-Type': 'application/json'},
            json={
                'contents': [{
                    'parts': [{
                        'text': prompt
                    }]
                }]
            },
            timeout=30
        )
        
        if response.status_code != 200:
            return jsonify({
                'error': f'Gemini API error: {response.status_code}',
                'details': response.text
            }), response.status_code
        
        data = response.json()
        result_text = data['candidates'][0]['content']['parts'][0]['text']
        
        return jsonify({
            'success': True,
            'result': result_text
        })
    
    except requests.exceptions.Timeout:
        return jsonify({'error': 'Request timeout'}), 504
    except requests.exceptions.RequestException as e:
        return jsonify({'error': str(e)}), 500
    except (KeyError, IndexError) as e:
        return jsonify({'error': 'Unexpected API response format', 'details': str(e)}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'ok', 'service': 'Gemini Proxy'})

if __name__ == '__main__':
    # Check if flask_cors is installed
    try:
        import flask_cors
    except ImportError:
        print("Installing flask-cors...")
        os.system('pip install flask-cors')
    
    print("🚀 Starting Gemini Proxy Server on http://localhost:5000")
    print(f"📡 Proxying to: {GEMINI_API_URL}")
    app.run(debug=False, host='localhost', port=5000)
