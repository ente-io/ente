#!/bin/bash

# OCR Models Download Script for Ente Photos
# This script downloads the required ONNX models for OCR functionality

set -e

echo "========================================="
echo "OCR Models Download Script"
echo "========================================="

# Create models directory if it doesn't exist
MODELS_DIR="$(dirname "$0")"
cd "$MODELS_DIR"

echo "Downloading models to: $MODELS_DIR"
echo ""

# Function to download and verify file
download_file() {
    local URL=$1
    local OUTPUT=$2
    local SHA256=$3
    local DESC=$4

    echo "Downloading $DESC..."
    echo "  URL: $URL"
    echo "  Output: $OUTPUT"

    # Download file
    if command -v wget &> /dev/null; then
        wget -q -O "$OUTPUT" "$URL" || curl -L -o "$OUTPUT" "$URL"
    else
        curl -L -o "$OUTPUT" "$URL"
    fi

    # Verify SHA256 if provided
    if [ -n "$SHA256" ]; then
        echo "  Verifying SHA256..."
        if command -v sha256sum &> /dev/null; then
            echo "$SHA256  $OUTPUT" | sha256sum -c - > /dev/null 2>&1 || {
                echo "  ERROR: SHA256 verification failed!"
                rm -f "$OUTPUT"
                return 1
            }
        elif command -v shasum &> /dev/null; then
            echo "$SHA256  $OUTPUT" | shasum -a 256 -c - > /dev/null 2>&1 || {
                echo "  ERROR: SHA256 verification failed!"
                rm -f "$OUTPUT"
                return 1
            }
        else
            echo "  WARNING: Cannot verify SHA256 (no sha256sum or shasum found)"
        fi
    fi

    echo "  ✓ Downloaded successfully"
    echo ""
}

# Download Text Detection Model
download_file \
    "https://www.modelscope.cn/models/RapidAI/RapidOCR/resolve/v3.4.0/onnx/PP-OCRv4/det/en_PP-OCRv3_det_infer.onnx" \
    "text_detection_rapidOCR_v1.onnx" \
    "ea07c15d38ac40cd69da3c493444ec75b44ff23840553ff8ba102c1219ed39c2" \
    "Text Detection Model"

# Download Text Classifier Model
download_file \
    "https://www.modelscope.cn/models/RapidAI/RapidOCR/resolve/v3.4.0/onnx/PP-OCRv4/cls/ch_ppocr_mobile_v2.0_cls_infer.onnx" \
    "text_classifier_rapidOCR_v1.onnx" \
    "e47acedf663230f8863ff1ab0e64dd2d82b838fceb5957146dab185a89d6215c" \
    "Text Orientation Classifier Model"

# Download Text Recognition Model
download_file \
    "https://www.modelscope.cn/models/RapidAI/RapidOCR/resolve/v3.4.0/onnx/PP-OCRv4/rec/en_PP-OCRv4_rec_infer.onnx" \
    "text_recognition_rapidOCR_v1.onnx" \
    "e8770c967605983d1570cdf5352041dfb68fa0c21664f49f47b155abd3e0e318" \
    "Text Recognition Model"

# Download Character Dictionary
download_file \
    "https://www.modelscope.cn/models/RapidAI/RapidOCR/resolve/v3.4.0/paddle/PP-OCRv4/rec/en_PP-OCRv4_rec_infer/en_dict.txt" \
    "en_dict_rapidOCR_v1.txt" \
    "" \
    "English Character Dictionary"

echo "========================================="
echo "All models downloaded successfully!"
echo "========================================="
echo ""
echo "Files in directory:"
ls -lh *.onnx *.txt 2>/dev/null || true
echo ""
echo "Total size:"
du -sh . | cut -f1

echo ""
echo "Next steps:"
echo "1. Integrate these models into the Ente Photos app"
echo "2. Use the OCR_MODELS_SPECIFICATION.md for implementation details"
echo "3. Test OCR functionality with sample images"
