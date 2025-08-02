FROM python:3.9-slim

WORKDIR /app

# 1. Primero actualiza los repositorios y instala dependencias disponibles
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git curl ffmpeg libsndfile1 unzip \
    build-essential libasound2-dev libjack-dev && \
    rm -rf /var/lib/apt/lists/*

# 2. Instala libfluidsynth desde una fuente alternativa
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget ca-certificates && \
    wget http://ftp.de.debian.org/debian/pool/main/f/fluidsynth/libfluidsynth2_2.1.1-1_amd64.deb && \
    dpkg -i libfluidsynth2_2.1.1-1_amd64.deb || apt-get install -yf && \
    rm libfluidsynth2_2.1.1-1_amd64.deb && \
    rm -rf /var/lib/apt/lists/*

# 3. Instala Gunicorn primero para evitar problemas
RUN pip install --no-cache-dir gunicorn==20.1.0

# 4. Copia e instala los requirements de Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Resto de tu configuración...
# (Aquí va tu configuración para MT3, copia de archivos, etc.)

# 5. Comando de inicio mejorado
CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:${PORT:-8080} --workers 1 --threads 4 --timeout 120 main:app"]
