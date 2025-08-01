# Usamos una imagen oficial de TensorFlow con Python 3.9
# Esta imagen ya tiene todas las dependencias del sistema y tensorflow instalado.
FROM tensorflow/tensorflow:2.11.0

# Establece el directorio de trabajo
WORKDIR /app

# Copia solo los requerimientos para instalar las dependencias restantes
# Nota: TensorFlow ya está instalado, así que puedes quitarlo de requirements.txt si quieres.
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copia el resto del código de la aplicación
COPY . .

# Descarga el modelo TFLite desde la URL de GCS
RUN curl -o /app/onsets_frames_wavinput.tflite https://storage.googleapis.com/magentadata/models/onsets_frames_transcription/tflite/onsets_frames_wavinput.tflite

# Establece la variable de entorno para el puerto
ENV PORT 8080

# Inicia la aplicación usando Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "main:app"]
