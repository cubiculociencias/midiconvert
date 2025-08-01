# Usa una imagen base de Python con la versión específica que necesitas
FROM python:3.9-slim

# Configura variables de entorno para evitar buffering y para pip
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

# Crea el directorio de trabajo
WORKDIR /app

# Instala dependencias del sistema operativo necesarias
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    libsndfile1 \
    ffmpeg \
    libportaudio2 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

# Descarga el modelo durante el build
RUN mkdir -p /app/models && \
    curl -f -s -S --retry 5 -o /app/models/onsets_frames_wavinput.tflite \
    https://storage.googleapis.com/magentadata/models/onsets_frames_transcription/tflite/onsets_frames_wavinput.tflite

# Copia primero los requirements para aprovechar la caché de Docker
COPY requirements.txt .

# Instala las dependencias de Python
RUN pip install --no-cache-dir -r requirements.txt

# Copia el resto de los archivos
COPY . .

# Expone el puerto (aunque Cloud Run ignora esto, es buena práctica)
EXPOSE 8080

# Comando para iniciar la aplicación con Gunicorn
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app
