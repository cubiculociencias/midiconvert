FROM python:3.9-slim

# 1. Dependencias del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    libfluidsynth3 build-essential libasound2-dev libjack-dev curl git \
    && rm -rf /var/lib/apt/lists/*

# 2. Variables de entorno
ENV PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

WORKDIR /app

# 3. Instalar dependencias básicas (sin t5x)
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 4. Instalar T5X compatible con Python 3.9 (MÉTODO OFICIAL)
RUN pip install "jax[cpu]==0.3.25" && \  # Versión ligeramente más nueva pero compatible
    pip install "flax==0.5.1" && \
    git clone https://github.com/google-research/t5x.git && \
    sed -i 's/flax @ git+https:\/\/github.com\/google\/flax#egg=flax/flax==0.5.1/g' t5x/setup.py && \
    cd t5x && pip install -e . && cd .. && \
    rm -rf t5x

# 5. Instalar MT3 correctamente
RUN git clone --depth 1 --branch=main https://github.com/magenta/mt3.git && \
    pip install ./mt3 && \
    rm -rf mt3

# 6. Copiar aplicación
COPY . .

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

CMD ["gunicorn", "--bind", ":8080", "--workers", "1", "--threads", "4", "--timeout", "120", "app:app"]
