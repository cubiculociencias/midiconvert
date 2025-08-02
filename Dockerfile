FROM python:3.9-slim

WORKDIR /app

# Dependencias del sistema
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git curl ffmpeg libsndfile1 unzip libfluidsynth3 build-essential libasound2-dev libjack-dev && \
    rm -rf /var/lib/apt/lists/*

# Instalar dependencias Python incluyendo gunicorn explícitamente
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt gunicorn

# Resto de tu configuración...
# ... (mantén todo lo que ya tienes)

# Cambia el CMD a una forma más simple
CMD ["gunicorn", "--bind", "0.0.0.0:$PORT", "main:app"]
