import os
import tempfile
from flask import Flask, request, send_file, jsonify
import librosa
import note_seq
from werkzeug.utils import secure_filename

# Importación específica para evitar conflictos
from mt3.inference import InferenceModel

app = Flask(__name__)

# Configuración
MODEL_TYPE = 'ismir2021'
CHECKPOINT_DIR = '/tmp/checkpoints/ismir2021/'
SAMPLE_RATE = 16000

# Inicialización diferida del modelo
model = None

def initialize_model():
    global model
    if model is None:
        if not os.path.exists(CHECKPOINT_DIR):
            os.makedirs(CHECKPOINT_DIR, exist_ok=True)
            # Descarga simulada - en producción usar Google Storage
            print("Descargando checkpoints...")
            
        print("Inicializando modelo...")
        model = InferenceModel(CHECKPOINT_DIR, MODEL_TYPE)
        print("Modelo listo")

@app.before_first_request
def before_first_request():
    initialize_model()

@app.route('/health')
def health_check():
    return jsonify({"status": "healthy"}), 200

@app.route('/transcribe', methods=['POST'])
def transcribe():
    if 'audio' not in request.files:
        return jsonify({'error': 'No audio file provided'}), 400

    try:
        audio_file = request.files['audio']
        filename = secure_filename(audio_file.filename)
        
        with tempfile.NamedTemporaryFile(suffix='.wav') as tmp_audio:
            audio_file.save(tmp_audio.name)
            audio, _ = librosa.load(tmp_audio.name, sr=SAMPLE_RATE, mono=True)
            
            initialize_model()
            ns = model(audio)
            
            midi_path = '/tmp/transcription.mid'
            note_seq.sequence_proto_to_midi_file(ns, midi_path)
            
            return send_file(
                midi_path,
                mimetype='audio/midi',
                as_attachment=True,
                download_name='transcription.mid'
            )
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
