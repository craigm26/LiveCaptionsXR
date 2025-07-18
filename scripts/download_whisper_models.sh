#!/bin/bash

# Bash script to download Whisper GGML models
# Run this script from the project root directory

echo "🎤 Downloading Whisper GGML models..."

# Create models directory if it doesn't exist
MODELS_DIR="assets/models"
mkdir -p "$MODELS_DIR"

# Define models to download (Hugging Face URLs)
declare -A models=(
    ["whisper_base.bin"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin"
    ["whisper_small.bin"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin"
    ["whisper_medium.bin"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin"
    ["whisper_large.bin"]="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large.bin"
)

# Download each model
for filename in "${!models[@]}"; do
    url="${models[$filename]}"
    filepath="$MODELS_DIR/$filename"
    
    if [ -f "$filepath" ]; then
        echo "✅ $filename already exists, skipping..."
        continue
    fi
    
    echo "📥 Downloading $filename..."
    echo "   URL: $url"
    
    if curl -L -o "$filepath" "$url"; then
        # Get file size
        size=$(stat -f%z "$filepath" 2>/dev/null || stat -c%s "$filepath" 2>/dev/null || echo "unknown")
        if [ "$size" != "unknown" ]; then
            size_mb=$(echo "scale=2; $size / 1048576" | bc 2>/dev/null || echo "unknown")
            echo "✅ Downloaded $filename ($size_mb MB)"
        else
            echo "✅ Downloaded $filename"
        fi
    else
        echo "❌ Failed to download $filename"
    fi
done

echo "🎉 Whisper model download complete!"
echo "📁 Models are now available in: $MODELS_DIR"

# Show available models
echo ""
echo "📋 Available models:"
for file in "$MODELS_DIR"/whisper_*.bin; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "unknown")
        if [ "$size" != "unknown" ]; then
            size_mb=$(echo "scale=2; $size / 1048576" | bc 2>/dev/null || echo "unknown")
            echo "   - $filename ($size_mb MB)"
        else
            echo "   - $filename"
        fi
    fi
done 