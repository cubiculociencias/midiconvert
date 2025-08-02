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

# 2. Instalar JAX para CPU (requerido por MT3)
RUN pip install --no-cache-dir "jax[cpu]"==0.3.25 -f https://storage.googleapis.com/jax-releases/jax_releases.html

# 3. Instalar dependencias Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Clonar MT3
RUN git clone https://github.com/magenta/mt3.git && \
    cd mt3 && pip install -e . && cd ..

# 5. Descargar checkpoints
RUN mkdir -p /app/checkpoints && \
    curl -L https://storage.googleapis.com/mt3/checkpoints.zip -o checkpoints.zip && \
    unzip checkpoints.zip -d /app/checkpoints && \
    rm checkpoints.zip

# 6. Copiar aplicación
COPY . .

# 7. Usar ENTRYPOINT para manejar PORT correctamente
ENTRYPOINT ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "1", "--threads", "4", "--timeout", "120", "main:app"]
