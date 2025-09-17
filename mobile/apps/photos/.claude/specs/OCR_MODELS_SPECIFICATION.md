# OCR Models Specification Document
## RapidOCR ONNX Models Integration Guide for Ente Photos

### Overview
This document provides comprehensive specifications for integrating RapidOCR's ONNX models into the Ente Photos app for on-device OCR functionality. The OCR pipeline consists of three sequential models: Detection → Classification → Recognition.

---

## Required Models

### 1. Text Detection Model
**Model**: `en_PP-OCRv3_det_infer.onnx`
**File Name**: `text_detection_rapidOCR_v1.onnx`
**Source URL**: `https://www.modelscope.cn/models/RapidAI/RapidOCR/resolve/v3.4.0/onnx/PP-OCRv4/det/en_PP-OCRv3_det_infer.onnx`
**Ente Photos App Download URL**: `https://models.ente.io/text_detection_rapidOCR_v1.onnx`
**SHA256**: `ea07c15d38ac40cd69da3c493444ec75b44ff23840553ff8ba102c1219ed39c2`
**Size**: ~4.2 MB

### 2. Text Orientation Classifier Model
**Model**: `ch_ppocr_mobile_v2.0_cls_infer.onnx`
**File Name**: `text_classifier_rapidOCR_v1.onnx`
**Source URL**: `https://www.modelscope.cn/models/RapidAI/RapidOCR/resolve/v3.4.0/onnx/PP-OCRv4/cls/ch_ppocr_mobile_v2.0_cls_infer.onnx`
**Ente Photos App Download URL**: `https://models.ente.io/text_classifier_rapidOCR_v1.onnx`
**SHA256**: `e47acedf663230f8863ff1ab0e64dd2d82b838fceb5957146dab185a89d6215c`
**Size**: ~1.4 MB

### 3. Text Recognition Model
**Model**: `en_PP-OCRv4_rec_infer.onnx`
**File Name**: `text_recognition_rapidOCR_v1.onnx`
**Source URL**: `https://www.modelscope.cn/models/RapidAI/RapidOCR/resolve/v3.4.0/onnx/PP-OCRv4/rec/en_PP-OCRv4_rec_infer.onnx`
**Ente Photos App Download URL**: `https://models.ente.io/text_recognition_rapidOCR_v1.onnx`
**SHA256**: `e8770c967605983d1570cdf5352041dfb68fa0c21664f49f47b155abd3e0e318`
**Size**: ~10 MB

### 4. Character Dictionary
**File**: `en_dict.txt`
**File Name**: `en_dict_rapidOCR_v1.txt`
**Source URL**: `https://www.modelscope.cn/models/RapidAI/RapidOCR/resolve/v3.4.0/paddle/PP-OCRv4/rec/en_PP-OCRv4_rec_infer/en_dict.txt`
**Ente Photos App Download URL**: `https://models.ente.io/en_dict_rapidOCR_v1.txt`
**Description**: Contains the character set for English text recognition (96 characters including special tokens)

---

## OCR Pipeline Architecture

```
Input Image → [Detection] → Text Regions → [Classification] → Oriented Regions → [Recognition] → Text Output
```

---

## Model Specifications

### 1. TEXT DETECTION MODEL

#### Purpose
Identifies and localizes all text regions in the input image.

#### Input Specifications
- **Input Name**: `x`
- **Shape**: `[1, 3, H, W]` where:
  - Batch size: 1
  - Channels: 3 (RGB)
  - H: Height (must be divisible by 32)
  - W: Width (must be divisible by 32)
- **Data Type**: float32

#### Input Preprocessing
```dart
// 1. Resize image
double ratio = 1.0;
if (min(height, width) < 736) {
  ratio = 736.0 / min(height, width);
}
int resizeH = (height * ratio).round();
int resizeW = (width * ratio).round();

// Round to nearest 32
resizeH = (resizeH / 32).round() * 32;
resizeW = (resizeW / 32).round() * 32;

// Ensure minimum dimensions
if (resizeH < 32) resizeH = 32;
if (resizeW < 32) resizeW = 32;

// 2. Normalize pixels
for each pixel (r, g, b):
  r = ((r / 255.0) - 0.5) / 0.5
  g = ((g / 255.0) - 0.5) / 0.5
  b = ((b / 255.0) - 0.5) / 0.5

// 3. Convert HWC to CHW format
// Original: [Height, Width, Channels]
// Result: [Channels, Height, Width]

// 4. Add batch dimension
// Shape becomes: [1, 3, Height, Width]
```

#### Output Specifications
- **Output Name**: `sigmoid_0.tmp_0`
- **Shape**: `[1, 1, H/4, W/4]`
- **Data Type**: float32
- **Value Range**: [0, 1] (probability map)

#### Output Post-processing
```dart
// 1. Extract probability map
// Remove batch dimension: [1, 1, H/4, W/4] → [H/4, W/4]

// 2. Threshold (default: 0.3)
binaryMap = probabilityMap > 0.3

// 3. Find contours using OpenCV-style contour detection

// 4. Approximate polygons for each contour

// 5. Unclip boxes (expand by factor 1.6)
for each box:
  area = calculateArea(box)
  length = calculatePerimeter(box)
  distance = area * unclipRatio / length
  expandedBox = expandPolygon(box, distance)

// 6. Filter boxes
- Remove boxes with score < boxThresh (0.5)
- Remove boxes with width < 3 or height < 3
- Sort boxes top-to-bottom, left-to-right
```

---

### 2. TEXT ORIENTATION CLASSIFIER MODEL

#### Purpose
Determines if detected text regions need to be rotated 180° for correct orientation.

#### Input Specifications
- **Input Name**: `x`
- **Shape**: `[N, 3, 48, 192]` where:
  - N: Number of text regions (batch)
  - Channels: 3 (RGB)
  - Height: 48 (fixed)
  - Width: 192 (fixed)
- **Data Type**: float32

#### Input Preprocessing
```dart
// For each detected text box:

// 1. Crop and rotate text region from original image
croppedImage = cropMinAreaRect(originalImage, boxPoints)

// 2. Resize to fixed dimensions
resizedImage = resize(croppedImage, width: 192, height: 48)

// 3. Normalize (same as detection)
for each pixel (r, g, b):
  r = ((r / 255.0) - 0.5) / 0.5
  g = ((g / 255.0) - 0.5) / 0.5
  b = ((b / 255.0) - 0.5) / 0.5

// 4. Convert HWC to CHW format

// 5. Stack all regions into batch
// Shape: [N, 3, 48, 192]
```

#### Output Specifications
- **Output Name**: `softmax_0.tmp_0`
- **Shape**: `[N, 2]`
- **Data Type**: float32
- **Values**: Softmax probabilities for [0°, 180°] orientations

#### Output Post-processing
```dart
for (int i = 0; i < N; i++) {
  float prob0 = output[i][0];   // Probability of 0° orientation
  float prob180 = output[i][1]; // Probability of 180° orientation

  if (prob180 > prob0 && prob180 > 0.9) {
    // Rotate image 180°
    textRegions[i] = rotate180(textRegions[i]);
  }
}
```

---

### 3. TEXT RECOGNITION MODEL

#### Purpose
Converts oriented text region images into text strings.

#### Input Specifications
- **Input Name**: `x`
- **Shape**: `[N, 3, 48, 320]` where:
  - N: Number of text regions
  - Channels: 3 (RGB)
  - Height: 48 (fixed)
  - Width: 320 (maximum, can be less)
- **Data Type**: float32

#### Input Preprocessing
```dart
// For each oriented text region:

// 1. Calculate resize ratio maintaining aspect ratio
double ratio = 48.0 / image.height;
int targetWidth = (image.width * ratio).round();

// 2. Limit maximum width
if (targetWidth > 320) {
  targetWidth = 320;
  ratio = 320.0 / image.width;
}

// 3. Resize image
resizedImage = resize(image,
  width: targetWidth,
  height: 48,
  interpolation: LINEAR
);

// 4. Pad to width 320 if needed (right padding with 0s)
if (targetWidth < 320) {
  paddedImage = padRight(resizedImage, targetWidth: 320, value: 0);
}

// 5. Normalize (same as previous models)
for each pixel (r, g, b):
  r = ((r / 255.0) - 0.5) / 0.5
  g = ((g / 255.0) - 0.5) / 0.5
  b = ((b / 255.0) - 0.5) / 0.5

// 6. Convert HWC to CHW
```

#### Output Specifications
- **Output Name**: `softmax_0.tmp_0`
- **Shape**: `[N, 80, 97]` where:
  - N: Batch size
  - 80: Sequence length (max characters)
  - 97: Vocabulary size (96 chars + blank token)
- **Data Type**: float32

#### Output Post-processing (CTC Decoding)
```dart
List<String> decodeBatch(float[][][] output, List<String> characterDict) {
  List<String> results = [];

  for (int b = 0; b < N; b++) {
    String text = "";
    int prevIndex = -1;

    // For each time step
    for (int t = 0; t < 80; t++) {
      // Find character with highest probability
      int maxIndex = 0;
      float maxProb = output[b][t][0];

      for (int c = 1; c < 97; c++) {
        if (output[b][t][c] > maxProb) {
          maxProb = output[b][t][c];
          maxIndex = c;
        }
      }

      // CTC decoding rules
      if (maxIndex > 0 && maxIndex != prevIndex) {
        // maxIndex 0 is blank token, skip it
        // Also skip repeated characters (CTC rule)
        text += characterDict[maxIndex - 1];
      }
      prevIndex = maxIndex;
    }

    results.add(text.trim());
  }

  return results;
}
```

---

## Complete OCR Pipeline Implementation

```dart
Future<List<TextResult>> performOCR(Uint8List imageBytes) async {
  // Load image
  final image = decodeImage(imageBytes);

  // Step 1: Text Detection
  final detectionInput = preprocessForDetection(image);
  final detectionOutput = await runONNX(detectionModel, detectionInput);
  final textBoxes = postprocessDetection(detectionOutput, image.width, image.height);

  if (textBoxes.isEmpty) {
    return [];
  }

  // Step 2: Crop text regions
  final textRegions = [];
  for (final box in textBoxes) {
    final cropped = cropAndRotateTextRegion(image, box);
    textRegions.add(cropped);
  }

  // Step 3: Text Orientation Classification
  final clsInput = preprocessForClassification(textRegions);
  final clsOutput = await runONNX(classifierModel, clsInput);
  final orientedRegions = applyOrientation(textRegions, clsOutput);

  // Step 4: Text Recognition
  final recInput = preprocessForRecognition(orientedRegions);
  final recOutput = await runONNX(recognitionModel, recInput);
  final texts = decodeText(recOutput, characterDict);

  // Step 5: Combine results
  List<TextResult> results = [];
  for (int i = 0; i < textBoxes.length; i++) {
    results.add(TextResult(
      text: texts[i],
      boundingBox: textBoxes[i],
      confidence: textBoxes[i].score,
    ));
  }

  return results;
}
```

---

## Performance Optimizations

### Batch Processing
- Process multiple text regions simultaneously in classification and recognition
- Maximum batch size: 6 (configurable based on device memory)

### Image Size Limits
- Maximum input image size: 2000px on longest side
- Minimum text height for detection: 10px
- Text regions smaller than 3x3 pixels are filtered out

### Memory Management
```dart
// Recommended limits for mobile devices:
const int MAX_IMAGE_SIZE = 2000;
const int MIN_TEXT_HEIGHT = 10;
const int BATCH_SIZE = 6;
const double TEXT_SCORE_THRESHOLD = 0.5;
```

---

## Error Handling

### Common Issues and Solutions

1. **Empty Detection Result**
   - Image might not contain text
   - Text too small (< 10px height)
   - Low contrast text

2. **Poor Recognition Quality**
   - Check if text region is blurry
   - Ensure proper orientation classification
   - Verify character dictionary matches language

3. **Memory Issues**
   - Reduce batch size
   - Downscale large images before processing
   - Process regions sequentially instead of batched

---

## Integration with Ente Photos

### Model Loading
```dart
class OCRService {
  late final OnnxSession detectionSession;
  late final OnnxSession classifierSession;
  late final OnnxSession recognitionSession;
  late final List<String> characterDict;

  Future<void> initialize() async {
    // Load models
    detectionSession = await OnnxSession.create('text_detection_rapidOCR_v1.onnx');
    classifierSession = await OnnxSession.create('text_classifier_rapidOCR_v1.onnx');
    recognitionSession = await OnnxSession.create('text_recognition_rapidOCR_v1.onnx');

    // Load character dictionary
    characterDict = await loadCharacterDict('en_dict_rapidOCR_v1.txt');
  }
}
```

### On-Demand Processing
Since this is for minimal, on-the-fly OCR:
- Load models only when user requests OCR
- Unload models after use to save memory
- No background indexing or caching

---

## Testing Checklist

- [ ] Test with various image sizes (small, medium, large)
- [ ] Test with different text orientations (0°, 90°, 180°, 270°)
- [ ] Test with multiple text regions in single image
- [ ] Test with different languages (initially English only)
- [ ] Test memory usage on low-end devices
- [ ] Test processing speed benchmarks
- [ ] Test with blurry/low-quality images
- [ ] Test with handwritten text (expected to fail)

---

## References

- RapidOCR GitHub: https://github.com/RapidAI/RapidOCR
- PaddleOCR (original models): https://github.com/PaddlePaddle/PaddleOCR
- ONNX Runtime: https://onnxruntime.ai/