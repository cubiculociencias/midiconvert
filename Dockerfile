FROM python:3.9-slim

WORKDIR /app

# Copia archivos primero
COPY . .

# Da permisos a script
RUN chmod +x startup.sh

# Ejecuta script de instalación estilo notebook
RUN bash startup.sh

EXPOSE 8080
CMD ["python", "app.py"]
