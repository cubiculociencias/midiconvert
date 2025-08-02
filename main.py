from flask import Flask, jsonify, request, send_file
import os
import logging
from flask_cors import CORS
import tempfile
from utils.mt3_model import MT3Model

app = Flask(__name__)
CORS(app)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

CHECKPOINT_DIR = "checkpoints/ismir2021"

logger.info(f"Attempting to load MT3 model from: {CHECKPOINT_DIR}")
try:
    model = MT3Model(CHECKPOINT_DIR)
    logger.info("MT3 model loaded successfully")
except Exception as e:
    logger.error(f"Error loading MT3 model: {e}")
    model = None

@app.route('/')
def home():
    return 'MT3 Transcription Service' if model else 'Model failed to load', 200 if model else 500

@app.route('/_health')
def health_check():
    if model:
        return jsonify({"status": "healthy"}), 200
    else:
        return jsonify({"status": "unhealthy", "message": "Model not loaded"}), 503

@app.route('/transcribe', methods=['POST'])
def transcribe():
    if not model:
        return 'Model not ready', 503

    if 'file' not in request.files:
        return 'No file uploaded', 400

    file = request.files['file']

    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_audio:
        file.save(tmp_audio.name)

        try:
            midi_path = model.transcribe(tmp_audio.name)
            return send_file(midi_path, mimetype='audio/midi', as_attachment=True, download_name='transcription.mid')
        except Exception as e:
            logger.error(f"Transcription error: {e}")
            return f"Transcription failed: {str(e)}", 500
