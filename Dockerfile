FROM python:3.9-slim

# 1. Dependencias del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    libfluidsynth3 build-essential libasound2-dev libjack-dev curl git \
    && rm -rf /var/lib/apt/lists/*

# 2. Configuración básica
ENV PYTHONUNBUFFERED=1 PYTHONPATH=/app
WORKDIR /app

# 3. Instalar dependencias básicas
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 4. Instalar T5X desde GitHub (¡SOLUCIÓN CLAVE!)
RUN git clone https://github.com/google-research/t5x.git && \
    sed -i 's/flax @ git+https:\/\/github.com\/google\/flax#egg=flax/flax==0.5.1/g' t5x/setup.py && \
    cd t5x && pip install -e . && cd .. && \
    rm -rf t5x

# 5. Instalar MT3
RUN git clone --depth 1 --branch=main https://github.com/magenta/mt3.git && \
    pip install ./mt3 && \
    rm -rf mt3

COPY . .

CMD ["gunicorn", "--bind", ":8080", "--workers", "1", "--threads", "4", "--timeout", "120", "app:app"]
