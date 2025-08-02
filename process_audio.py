import note_seq
from mt3 import configs
import tensorflow as tf
import librosa
import numpy as np

CONFIG = configs.CONFIG_MAP['mt3']
MODEL = CONFIG.get_model()
MODEL.load_weights('checkpoints/mt3/ckpt-384000').expect_partial()

def transcribe_audio_to_midi(wav_path):
    audio, sr = librosa.load(wav_path, sr=CONFIG.sample_rate, mono=True)
    spec = CONFIG.input_transform(audio, CONFIG.sample_rate)
    inputs = tf.convert_to_tensor(spec[np.newaxis, ...], dtype=tf.float32)
    logits = MODEL(inputs, training=False)
    token_ids = tf.argmax(logits, axis=-1).numpy()[0]
    ns = CONFIG.vocab.decode(token_ids)
    midi_path = wav_path.replace(".wav", ".mid")
    note_seq.sequence_proto_to_midi_file(ns, midi_path)
    return midi_path
