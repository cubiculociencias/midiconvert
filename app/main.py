import os
from flask import Flask, request, jsonify, send_file, render_template
from werkzeug.utils import secure_filename
from transcribe import audio_to_midi

app = Flask(__name__)

# Configuración
UPLOAD_FOLDER = '/tmp/uploads'
ALLOWED_EXTENSIONS = {'wav', 'mp3'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/transcribe', methods=['POST'])
def transcribe_audio():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    
    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        audio_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(audio_path)
        
        try:
            # Convertir audio a MIDI
            midi_path = audio_to_midi(audio_path)
            
            # Devolver el archivo MIDI
            return send_file(
                midi_path,
                as_attachment=True,
                download_name='transcription.mid',
                mimetype='audio/midi'
            )
        except Exception as e:
            return jsonify({'error': str(e)}), 500
        finally:
            # Limpiar archivos temporales
            if os.path.exists(audio_path):
                os.remove(audio_path)
            if 'midi_path' in locals() and os.path.exists(midi_path):
                os.remove(midi_path)
    else:
        return jsonify({'error': 'File type not allowed'}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
