import note_seq
from magenta.models.mt3 import mt3
from magenta.models.mt3 import configs
from magenta.music import audio_io
import tensorflow as tf
import numpy as np
import tempfile
import os

class MT3Model:
    def __init__(self, checkpoint_dir):
        self.config = configs.CONFIG_MAP['mt3']
        self.model = mt3.MT3(self.config)
        self.model.load_weights(tf.train.latest_checkpoint(checkpoint_dir)).expect_partial()

    def transcribe(self, audio_path):
        # Load and preprocess audio
        audio = audio_io.load_audio(audio_path, sample_rate=self.config.sample_rate)
        audio = audio[:self.config.max_input_length * self.config.sample_rate]
        inputs = mt3.preprocess_audio(audio, self.config)

        # Run transcription
        outputs = self.model(inputs[None, :], training=False)
        seq = self.config.decode_fn(outputs)

        # Write MIDI file to temp file
        with tempfile.NamedTemporaryFile(suffix=".mid", delete=False) as tmp_midi:
            note_seq.sequence_proto_to_midi_file(seq, tmp_midi.name)
            return tmp_midi.name
