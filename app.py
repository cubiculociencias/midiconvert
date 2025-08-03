from flask import Flask, request, send_file, jsonify
from transcriber import transcribe_audio_to_midi
import os
import tempfile

app = Flask(__name__)

@app.route('/')
def index():
    return jsonify({"message": "Transcripción de audio a MIDI lista."})

@app.route('/transcribe', methods=['POST'])
def transcribe():
    if 'file' not in request.files:
        return jsonify({'error': 'No se envió archivo de audio'}), 400

    file = request.files['file']

    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_audio:
        file.save(tmp_audio.name)

    try:
        midi_path = transcribe_audio_to_midi(tmp_audio.name)
        return send_file(midi_path, mimetype='audio/midi', as_attachment=True, download_name='output.mid')
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        os.remove(tmp_audio.name)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
