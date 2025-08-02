from flask import Flask, jsonify, request, send_file
import os
import logging
from flask_cors import CORS
import tempfile
from utils.mt3_model import MT3Model

app = Flask(__name__)
CORS(app)

# Configuración de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Carga del modelo (con manejo robusto de errores)
CHECKPOINT_DIR = os.path.join("checkpoints", "ismir2021")
model = None

try:
    logger.info(f"Cargando modelo MT3 desde: {CHECKPOINT_DIR}")
    model = MT3Model(CHECKPOINT_DIR)
    logger.info("Modelo cargado exitosamente")
except Exception as e:
    logger.error(f"Error al cargar el modelo: {str(e)}", exc_info=True)

@app.route('/')
def home():
    return jsonify({
        "status": "ready" if model else "error",
        "message": "MT3 Transcription Service" if model else "Model failed to load"
    }), 200 if model else 500

@app.route('/_health')
def health_check():
    if model:
        return jsonify({"status": "healthy"}), 200
    return jsonify({
        "status": "unhealthy",
        "message": "Model not loaded"
    }), 503

@app.route('/transcribe', methods=['POST'])
def transcribe():
    if not model:
        return jsonify({"error": "Model not ready"}), 503

    if 'file' not in request.files:
        return jsonify({"error": "No file uploaded"}), 400

    try:
        with tempfile.NamedTemporaryFile(suffix=".wav") as tmp_audio:
            request.files['file'].save(tmp_audio.name)
            tmp_audio.seek(0)  # Rebobinar archivo
            
            midi_path = model.transcribe(tmp_audio.name)
            return send_file(
                midi_path,
                mimetype='audio/midi',
                as_attachment=True,
                download_name='transcription.mid'
            )
    except Exception as e:
        logger.error(f"Error en transcripción: {str(e)}", exc_info=True)
        return jsonify({"error": f"Transcription failed: {str(e)}"}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
