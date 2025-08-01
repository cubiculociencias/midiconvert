import os
import tempfile
from flask import Flask, request, send_file
from magenta.models.transcription import audio_label_data_utils
from magenta.models.transcription import model as transcription_model
from magenta.models.transcription import constants
from magenta.music import midi_io
from note_seq.protobuf import music_pb2

app = Flask(__name__)

# Cargar el modelo de Magenta al inicio del servicio
# Este paso es intensivo, por eso se hace una sola vez
# Ahora usamos el archivo TFLite
tflite_path = os.path.join(os.getcwd(), 'onsets_frames_wavinput.tflite')

hparams = transcription_model.get_default_hparams()
# Pasamos la ruta del modelo TFLite en la configuración
hparams.parse(f'tflite_path={tflite_path}')

model = transcription_model.OnsetsFramesTranscriptionModel(
    hparams=hparams,
    session=None,
    checkpoint_path=None  # No se necesita un checkpoint, el TFLite está en hparams
)

@app.route('/transcribe', methods=['POST'])
def transcribe_audio():
    """
    Endpoint para transcribir un archivo de audio a MIDI.
    """
    if 'audio' not in request.files:
        return 'No se encontró el archivo de audio', 400

    audio_file = request.files['audio']

    # Guardar el archivo de audio temporalmente
    temp_audio_path = tempfile.NamedTemporaryFile(delete=False, suffix='.wav').name
    audio_file.save(temp_audio_path)

    try:
        # Preprocesar el audio y ejecutar la transcripción
        features = audio_label_data_utils.process_audio(
            temp_audio_path,
            hparams,
            constants.MIN_LENGTH,
            transcription_model.CHANNELS
        )
        transcribed_sequence = model.predict(features)
        
        # Guardar la transcripción como un archivo MIDI
        temp_midi_path = tempfile.NamedTemporaryFile(delete=False, suffix='.mid').name
        midi_io.sequence_proto_to_midi_file(transcribed_sequence, temp_midi_path)
        
        # Enviar el archivo MIDI al cliente
        return send_file(temp_midi_path, as_attachment=True, mimetype='audio/midi')

    except Exception as e:
        return f'Ocurrió un error en la transcripción: {e}', 500
    
    finally:
        # Limpiar los archivos temporales
        os.remove(temp_audio_path)
        if os.path.exists(temp_midi_path):
            os.remove(temp_midi_path)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
