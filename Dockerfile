# Usa una imagen base de Python 3.9
FROM python:3.9-slim

# Establece el directorio de trabajo
WORKDIR /app

# Copia los archivos de requerimientos e instálalos
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copia el resto del código de la aplicación
COPY . .

# Descarga el modelo TFLite desde la URL de GCS
RUN curl -o /app/onsets_frames_wavinput.tflite https://storage.googleapis.com/magentadata/models/onsets_frames_transcription/tflite/onsets_frames_wavinput.tflite

# Establece la variable de entorno para el puerto
ENV PORT 8080

# Inicia la aplicación cuando el contenedor se inicie
CMD ["python", "main.py"]
