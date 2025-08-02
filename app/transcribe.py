import os
import tempfile
import note_seq
from mt3 import inference

# Configuración del modelo
MODEL = 'mt3'
CHECKPOINT_PATH = f'gs://mt3/checkpoints/{MODEL}'

# Cargar el modelo (se hace una vez al iniciar la aplicación)
inference_model = inference.InferenceModel(
    CHECKPOINT_PATH,
    model_type=MODEL
)

def audio_to_midi(audio_path):
    """Convierte un archivo de audio a MIDI usando MT3"""
    try:
        # Crear archivo temporal para el MIDI
        midi_fd, midi_path = tempfile.mkstemp(suffix='.mid')
        os.close(midi_fd)
        
        # Cargar audio y convertir a muestras
        samples = note_seq.audio_io.wav_data_to_samples_librosa(
            audio_path, sample_rate=16000)
        
        # Realizar la transcripción
        example = inference_model.samples_to_examples(samples, 'infer')
        inference_model.infer(example)
        
        # Guardar el resultado como MIDI
        note_seq.sequence_proto_to_midi_file(
            example['inference/sequence'], midi_path)
        
        return midi_path
    except Exception as e:
        # Limpiar archivo temporal si hay error
        if 'midi_path' in locals() and os.path.exists(midi_path):
            os.remove(midi_path)
        raise e
