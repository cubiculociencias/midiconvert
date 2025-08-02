FROM python:3.9-slim

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    libfluidsynth3 \
    build-essential \
    libasound2-dev \
    libjack-dev \
    wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiar e instalar dependencias Python primero
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Clonar solo el código necesario de MT3
RUN git clone --depth 1 --branch=main https://github.com/magenta/mt3 mt3_tmp && \
    mv mt3_tmp/mt3 ./mt3 && \
    rm -rf mt3_tmp

# Copiar archivos de la aplicación
COPY . .

# Descargar checkpoints al iniciar
CMD bash -c "python download_checkpoints.py && gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 app:app"
