FROM python:3.9-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libfluidsynth3 \
    build-essential \
    libasound2-dev \
    libjack-dev \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Instalación manual de t5x (como en el foro)
RUN pip install "jax[cpu]==0.3.15" && \
    pip install git+https://github.com/google/flax.git@v0.5.1 && \
    git clone https://github.com/google-research/t5x.git && \
    sed -i 's/flax @ git+https:\/\/github.com\/google\/flax#egg=flax/flax==0.5.1/g' t5x/setup.py && \
    cd t5x && pip install -e . && cd .. && \
    rm -rf t5x

# Instalación de MT3
RUN git clone --depth 1 --branch=main https://github.com/magenta/mt3.git && \
    pip install ./mt3 && \
    rm -rf mt3

COPY . .

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

CMD ["gunicorn", "--bind", ":8080", "--workers", "1", "--threads", "4", "--timeout", "120", "app:app"]
