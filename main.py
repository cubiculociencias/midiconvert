from flask import Flask, request, jsonify
import os
import logging
import tempfile
from utils.tflite_model import Model
from flask_cors import CORS
import librosa
import numpy as np
import pretty_midi

app = Flask(__name__)
CORS(app)

# Configuración de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Carga del modelo
MODEL_PATH = "models/onsets_frames_wavinput.tflite"
model = Model(MODEL_PATH)

@app.route('/transcribe', methods=['POST'])
def transcribe():
    if 'file' not in request.files:
        return jsonify({"error": "No file provided"}), 400
    
    audio_file = request.files['file']
    
    try:
        # Guardar temporalmente el archivo
        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
            audio_file.save(tmp.name)
            
            # Procesamiento del audio (similar al Colab)
            audio, sr = librosa.load(tmp.name, sr=16000, mono=True)
            
            # Asegurar que la duración sea múltiplo de hop_size (como en el Colab)
            hop_size = 512
            expected_length = (len(audio) // hop_size) * hop_size
            audio = audio[:expected_length]
            
            # Normalización (como en el Colab)
            audio = audio / np.max(np.abs(audio))
            
            # Realizar la transcripción
            sequence_prediction = model.transcribe(audio)
            
            # Convertir a PrettyMIDI
            midi_data = sequence_prediction.to_pretty_midi()
            
            # Guardar a archivo MIDI temporal
            with tempfile.NamedTemporaryFile(suffix='.mid', delete=True) as midi_tmp:
                midi_data.write(midi_tmp.name)
                with open(midi_tmp.name, 'rb') as f:
                    midi_bytes = f.read()
            
            return midi_bytes, 200, {'Content-Type': 'application/octet-stream'}
    
    except Exception as e:
        logger.error(f"Error during transcription: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
