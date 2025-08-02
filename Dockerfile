FROM python:3.9-slim

WORKDIR /app

# Dependencias del sistema
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git curl ffmpeg libsndfile1 unzip libfluidsynth3 build-essential libasound2-dev libjack-dev && \
    rm -rf /var/lib/apt/lists/*

# Instalar dependencias Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Clonar MT3 y mover archivos
RUN git clone --branch=main https://github.com/magenta/mt3 && \
    mv mt3 mt3_tmp && mv mt3_tmp/* . && rm -r mt3_tmp

# Instalar MT3 y jax CPU
RUN pip install --no-cache-dir nest-asyncio pyfluidsynth==1.3.0 -e . \
    -f https://storage.googleapis.com/jax-releases/jax_releases.html

# Descargar y descomprimir checkpoints
RUN mkdir -p /app/checkpoints && \
    curl -L -o checkpoints.zip https://storage.googleapis.com/mt3/checkpoints.zip && \
    unzip checkpoints.zip -d /app/checkpoints && rm checkpoints.zip

# Copiar archivos de la app
COPY . .

CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app
