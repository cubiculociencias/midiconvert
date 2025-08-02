FROM python:3.9-slim

WORKDIR /app

# Instala dependencias del sistema incluyendo las necesarias para compilar Python packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git curl ffmpeg libsndfile1 unzip libfluidsynth3 build-essential \
    libasound2-dev libjack-dev python3-dev && \
    rm -rf /var/lib/apt/lists/*

# Instala pip y gunicorn primero, antes de otros paquetes
RUN python -m pip install --upgrade pip && \
    pip install --no-cache-dir gunicorn==20.1.0

# Copia requirements.txt e instala dependencias
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Resto de tu configuración...
# (Mantén todo lo que ya tienes para MT3)

# Comando final usando la forma exec para mejor manejo de señales
CMD ["gunicorn", "--bind", "0.0.0.0:${PORT:-8080}", "--workers", "1", "--threads", "4", "main:app"]
