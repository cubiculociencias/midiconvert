FROM python:3.9-slim

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    libfluidsynth3 \
    build-essential \
    libasound2-dev \
    libjack-dev \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Configurar entorno Python
ENV PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

WORKDIR /app

# Instalar dependencias Python primero para caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Clonar MT3 mínimo
RUN git clone --depth 1 --branch=main https://github.com/magenta/mt3 && \
    mv mt3/mt3 ./mt3 && \
    rm -rf mt3

# Copiar aplicación
COPY . .

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

CMD ["gunicorn", "--bind", ":8080", "--workers", "1", "--threads", "4", "--timeout", "120", "app:app"]
