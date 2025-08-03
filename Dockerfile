FROM python:3.9-slim

# 1. Instalar dependencias del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    libfluidsynth3 \
    build-essential \
    libasound2-dev \
    libjack-dev \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# 2. Configuración básica
ENV PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

WORKDIR /app

# 3. Instalar JAX/JAXlib COMPATIBLES desde repositorio alternativo
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir \
    "jax[cpu]==0.3.15" \
    "jaxlib==0.3.15" \
    -f https://storage.googleapis.com/jax-releases/libtpu_releases.html

# 4. Instalar T5X desde fuente
RUN pip install "flax==0.5.1" && \
    git clone https://github.com/google-research/t5x.git && \
    sed -i 's/flax @ git+https:\/\/github.com\/google\/flax#egg=flax/flax==0.5.1/g' t5x/setup.py && \
    cd t5x && pip install -e . && cd .. && \
    rm -rf t5x

# 5. Instalar MT3 sin dependencias conflictivas
RUN git clone --depth 1 --branch=main https://github.com/magenta/mt3.git && \
    pip install --no-deps ./mt3 && \
    rm -rf mt3

# 6. Copiar aplicación
COPY . .

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

CMD ["gunicorn", "--bind", ":8080", "--workers", "1", "--threads", "4", "--timeout", "120", "app:app"]
