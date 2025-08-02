from flask import Flask, jsonify, request, send_file
import os
import logging
from flask_cors import CORS
import tempfile

app = Flask(__name__)
CORS(app)

# Configuración mejorada de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.route('/')
def home():
    return jsonify({
        "status": "ready",
        "message": "MT3 Transcription Service"
    })

@app.route('/_health')
def health_check():
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
