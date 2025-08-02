import os
import tempfile
import subprocess
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

def download_checkpoints():
    print("Descargando checkpoints...", flush=True)
    os.makedirs(CHECKPOINT_DIR, exist_ok=True)

    base_url = "https://storage.googleapis.com/magentadata/models/mt3/ismir2021/"
    files = ["checkpoint", "model.ckpt.data-00000-of-00001", "model.ckpt.index", "model.ckpt.meta"]

    for file in files:
        url = base_url + file
        dest = os.path.join(CHECKPOINT_DIR, file)
        if not os.path.exists(dest):
            print(f"Descargando {file}...", flush=True)
            subprocess.run(["curl", "-sSL", "-o", dest, url], check=True)

def initialize_model():
    global model
    if model is None:
        try:
            if not os.path.exists(os.path.join(CHECKPOINT_DIR, "model.ckpt.index")):
                download_checkpoints()
            print("Inicializando modelo...", flush=True)
            model = InferenceModel(CHECKPOINT_DIR, MODEL_TYPE)
            print("Modelo listo", flush=True)
        except Exception as e:
            print(f"Error al inicializar modelo: {str(e)}", flush=True)
            raise

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
        print(f"Error en transcripción: {str(e)}", flush=True)
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    initialize_model()
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
