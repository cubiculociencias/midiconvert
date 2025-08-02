#!/bin/bash
set -e

apt-get update -qq && apt-get install -qq libfluidsynth3 build-essential libasound2-dev libjack-dev git

# Clona repo oficial de MT3
git clone --branch=main https://github.com/magenta/mt3
mv mt3/* . && rm -rf mt3

# Instala paquete en modo editable
pip install -e . -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html

# Descarga modelos y soundfont
gsutil -q -m cp -r gs://mt3/checkpoints .
gsutil -q -m cp gs://magentadata/soundfonts/SGM-v2.01-Sal-Guit-Bass-V1.3.sf2 .
