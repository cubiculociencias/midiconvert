import numpy as np
import tensorflow as tf
from magenta.models.onsets_frames_transcription import audio_label_data_utils
from magenta.models.onsets_frames_transcription import infer_util
from magenta.music import sequences_lib
from magenta.protobuf import music_pb2

class Model:
    def __init__(self, model_path):
        self.interpreter = tf.lite.Interpreter(model_path=model_path)
        self.interpreter.allocate_tensors()
        
        self.input_details = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()
    
    def transcribe(self, audio_samples):
        # Preprocesamiento como en el Colab
        samples = np.reshape(audio_samples, [1, -1])
        
        # Configurar entradas del modelo
        self.interpreter.set_tensor(
            self.input_details[0]['index'], samples.astype(np.float32))
        
        # Ejecutar inferencia
        self.interpreter.invoke()
        
        # Obtener resultados
        outputs = {
            'onset_probs': self.interpreter.get_tensor(self.output_details[0]['index'])[0],
            'activation_probs': self.interpreter.get_tensor(self.output_details[1]['index'])[0],
            'frame_probs': self.interpreter.get_tensor(self.output_details[2]['index'])[0],
            'velocity_values': self.interpreter.get_tensor(self.output_details[3]['index'])[0]
        }
        
        # Procesar resultados como en el Colab
        sequence_prediction = infer_util.predict_sequence(
            outputs,
            min_pitch=infer_util.MIN_MIDI_PITCH,
            max_pitch=infer_util.MAX_MIDI_PITCH)
        
        return sequence_prediction
