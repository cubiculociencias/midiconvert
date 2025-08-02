import os
import tempfile
from flask import Flask, request, send_file
import librosa
import note_seq
from mt3.inference import InferenceModel

app = Flask(__name__)

# Configuración
MODEL_TYPE = 'ismir2021'
CHECKPOINT_DIR = '/tmp/checkpoints/ismir2021/'
SAMPLE_RATE = 16000

# Cargar modelo al iniciar
model = InferenceModel(CHECKPOINT_DIR, MODEL_TYPE)

@app.route('/transcribe', methods=['POST'])
def transcribe():
    if 'audio' not in request.files:
        return {'error': 'No audio file provided'}, 400

    audio_file = request.files['audio']
    
    with tempfile.NamedTemporaryFile(suffix='.wav') as tmp_audio:
        audio_file.save(tmp_audio.name)
        audio, _ = librosa.load(tmp_audio.name, sr=SAMPLE_RATE, mono=True)
        
        # Transcripción
        ns = model(audio)
        
        # Guardar como MIDI
        midi_path = '/tmp/transcription.mid'
        note_seq.sequence_proto_to_midi_file(ns, midi_path)
        
        return send_file(midi_path, mimetype='audio/midi', as_attachment=True)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
