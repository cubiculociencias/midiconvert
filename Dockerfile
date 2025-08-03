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

# 3. Copiar requirements e instalar dependencias (¡en minúsculas!)
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 4. Instalar T5X y MT3 manualmente
RUN pip install "jax[cpu]==0.3.25" && \
    pip install "flax==0.5.1" && \
    git clone https://github.com/google-research/t5x.git && \
    sed -i 's/flax @ git+https:\/\/github.com\/google\/flax#egg=flax/flax==0.5.1/g' t5x/setup.py && \
    cd t5x && pip install -e . && cd .. && \
    rm -rf t5x

RUN git clone --depth 1 --branch=main https://github.com/magenta/mt3.git && \
    pip install --no-deps ./mt3 && \
    rm -rf mt3

# 5. Copiar aplicación
COPY . .

# 6. Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# 7. Comando de inicio (para Cloud Run)
CMD ["gunicorn", "--bind", ":8080", "--workers", "1", "--threads", "4", "--timeout", "120", "app:app"]
