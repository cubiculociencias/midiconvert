from flask import Flask, request, send_file
import tempfile
import os
from process_audio import transcribe_audio_to_midi

app = Flask(__name__)

@app.route('/transcribe', methods=['POST'])
def transcribe():
    audio = request.files['file']
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_audio:
        audio.save(tmp_audio.name)
        midi_path = transcribe_audio_to_midi(tmp_audio.name)

    return send_file(midi_path, mimetype='audio/midi', as_attachment=True, download_name='output.mid')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
