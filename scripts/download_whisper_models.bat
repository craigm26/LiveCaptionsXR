@echo off
echo 🎤 Downloading Whisper GGML models...

REM Create models directory if it doesn't exist
if not exist "assets\models" mkdir "assets\models"

echo 📥 Downloading whisper_base.bin (139 MB)...
curl -L -o "assets\models\whisper_base.bin" "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin"

echo 📥 Downloading whisper_small.bin (461 MB)...
curl -L -o "assets\models\whisper_small.bin" "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin"

echo 📥 Downloading whisper_medium.bin (1.42 GB)...
curl -L -o "assets\models\whisper_medium.bin" "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin"

echo 📥 Downloading whisper_large.bin (2.87 GB)...
curl -L -o "assets\models\whisper_large.bin" "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large.bin"

echo 🎉 Whisper model download complete!
echo 📁 Models are now available in: assets\models

echo.
echo 📋 Available models:
dir "assets\models\whisper_*.bin"

pause 