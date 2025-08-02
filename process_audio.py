import note_seq
from mt3 import configs
from mt3 import spectrograms
from mt3 import vocabularies
from seqio import Vocabulary
import tensorflow as tf
import ddsp
import gin
import numpy as np
import librosa

# Carga modelo y configuración
CONFIG = configs.CONFIG_MAP['mt3']
MODEL = CONFIG.get_model()
MODEL.load_weights('models/mt3_ckpt/ckpt-???').expect_partial()  # ← reemplaza por el número correcto

def transcribe_audio_to_midi(wav_path):
    # Cargar audio y convertir a mono
    audio, sr = librosa.load(wav_path, sr=CONFIG.sample_rate, mono=True)
    assert audio.ndim == 1

    # Extraer espectrograma
    spec = CONFIG.input_transform(audio, CONFIG.sample_rate)

    # Expandir dimensiones para hacer batch=1
    inputs = tf.convert_to_tensor(spec[np.newaxis, ...], dtype=tf.float32)

    # Inferencia
    logits = MODEL(inputs, training=False)
    token_ids = tf.argmax(logits, axis=-1).numpy()[0]

    # Convertir a nota_seq
    ns = CONFIG.vocab.decode(token_ids)

    # Guardar como MIDI
    midi_path = wav_path.replace('.wav', '.mid')
    note_seq.sequence_proto_to_midi_file(ns, midi_path)

    return midi_path
