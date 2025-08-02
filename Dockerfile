FROM python:3.9-slim

WORKDIR /app

# Instala dependencias del sistema
RUN apt-get update -qq && apt-get install -qq \
  git curl tar libfluidsynth3 build-essential libasound2-dev libjack-dev

# Copia los archivos del proyecto
COPY . .

# Da permisos al script de instalación
RUN chmod +x startup.sh

# Ejecuta la descarga del modelo y dependencias
RUN bash startup.sh

# Instala Python deps
RUN pip install --upgrade pip && pip install -r requirements.txt

EXPOSE 8080

# Ejecuta Flask directamente
CMD ["python", "app.py"]
