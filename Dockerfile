# Usa esta versión específica de Python que sabemos que funciona
FROM python:3.9.16-slim-bullseye

WORKDIR /app

# Instala dependencias del sistema primero
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git curl ffmpeg libsndfile1 unzip libfluidsynth3 \
    build-essential libasound2-dev libjack-dev && \
    rm -rf /var/lib/apt/lists/*

# Instala Gunicorn primero y por separado
RUN pip install --no-cache-dir gunicorn==20.1.0

# Copia requirements e instala dependencias
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Resto de tu configuración...
COPY . .

# Usa este comando para mejor manejo de variables de entorno
CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:${PORT:-8080} --workers 1 --threads 4 --timeout 120 main:app"]
