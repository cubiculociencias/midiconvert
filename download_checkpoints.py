import os
import subprocess
from google.cloud import storage

def download_checkpoints():
    os.makedirs('/tmp/checkpoints/ismir2021', exist_ok=True)
    
    print("Descargando checkpoints de Google Storage...")
    subprocess.run([
        'gsutil', '-m', 'cp', '-r',
        'gs://mt3/checkpoints/ismir2021/*',
        '/tmp/checkpoints/ismir2021/'
    ], check=True)

if __name__ == '__main__':
    download_checkpoints()
