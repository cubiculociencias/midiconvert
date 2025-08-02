FROM python:3.9-slim

WORKDIR /app

# 1. Instalar dependencias del sistema
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git curl ffmpeg libsndfile1 unzip \
    build-essential libasound2-dev libjack-dev \
    software-properties-common && \
    add-apt-repository non-free && \
    apt-get install -y fluidsynth && \
    rm -rf /var/lib/apt/lists/*

# 2. Instalar dependencias Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 3. Clonar e instalar MT3
RUN git clone https://github.com/magenta/mt3.git && \
    cd mt3 && pip install -e . && cd ..

# 4. Descargar checkpoints del modelo (PARTE CLAVE AÑADIDA)
RUN mkdir -p /app/checkpoints && \
    curl -L https://storage.googleapis.com/mt3/checkpoints.zip -o checkpoints.zip && \
    unzip checkpoints.zip -d /app/checkpoints && \
    rm checkpoints.zip

# 5. Configurar entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
COPY main.py utils/ /app/

ENTRYPOINT ["/entrypoint.sh"]
