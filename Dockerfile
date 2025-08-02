# Usar una imagen base con Python
FROM python:3.9-slim

# 1. Instalar dependencias del sistema (incluyendo git)
RUN apt-get update && apt-get install -y \
    git \
    libsndfile1 \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# 2. Establecer el directorio de trabajo
WORKDIR /app

# 3. Copiar requirements primero para cachear la instalación
COPY requirements.txt .

# 4. Instalar dependencias de Python
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copiar el resto de los archivos
COPY . .

# 6. Puerto expuesto
EXPOSE 8080

# 7. Comando para ejecutar la aplicación
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "1", "--threads", "8", "app.main:app"]
