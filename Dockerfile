FROM python:3.9-slim

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    libfluidsynth3 \
    build-essential \
    libasound2-dev \
    libjack-dev \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Variables de entorno
ENV PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

WORKDIR /app

# Copiar requirements.txt e instalar dependencias principales
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Instalar t5x y flax desde sus repositorios (como en el foro)
RUN pip install --upgrade "jax[cpu]" && \
    pip install --upgrade git+https://github.com/google/flax.git && \
    git clone https://github.com/google-research/t5x.git && \
    sed -i 's!flax @ git+https://github.com/google/flax#egg=flax!flax!g' t5x/setup.py && \
    cd t5x && pip install -e . && cd .. && \
    rm -rf t5x

# Instalar mt3
RUN git clone --depth 1 --branch=main https://github.com/magenta/mt3.git && \
    pip install ./mt3 && \
    rm -rf mt3

# Copiar el resto del código de la app
COPY . .

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Comando para lanzar la app
CMD ["gunicorn", "--bind", ":8080", "--workers", "1", "--threads", "4", "--timeout", "120", "app:app"]
