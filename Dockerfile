FROM python:3.9-slim

WORKDIR /app

# 1. Instalar dependencias del sistema basadas en el Colab
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git curl ffmpeg libsndfile1 unzip \
    build-essential libasound2-dev libjack-dev \
    software-properties-common && \
    add-apt-repository non-free && \
    apt-get update && \
    apt-get install -y fluidsynth && \
    rm -rf /var/lib/apt/lists/*

# 2. Instalar JAX para CPU (como se hace en el Colab)
RUN pip install --upgrade pip && \
    pip install --no-cache-dir "jax[cpu]"==0.3.25 -f https://storage.googleapis.com/jax-releases/jax_releases.html

# 3. Instalar dependencias de Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Clonar MT3 (versión simplificada del proceso del Colab)
RUN git clone https://github.com/magenta/mt3.git && \
    cd mt3 && \
    pip install -e . && \
    cd ..

# 5. Descargar checkpoints (como en el Colab)
RUN mkdir -p /app/checkpoints && \
    curl -L https://storage.googleapis.com/mt3/checkpoints.zip -o checkpoints.zip && \
    unzip checkpoints.zip -d /app/checkpoints && \
    rm checkpoints.zip

# 6. Configurar la aplicación Flask
COPY . .

# 7. Comando de inicio optimizado
CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:${PORT:-8080} --workers 1 --threads 4 --timeout 120 main:app"]
