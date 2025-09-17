# OCR MVP Implementation Plan

## Overview

Implement minimal on-the-fly OCR functionality for extracting text from images in the Ente Photos app. This will enable users to manually extract text from individual images through the photo viewer interface.

## Current State Analysis

The Ente Photos codebase is **fully prepared** for OCR implementation with:
- Mature ONNX runtime infrastructure (dual platform support)
- Model management system with auto-download from CDN
- Established ML patterns from face detection and CLIP models
- Feature flag system for gradual rollout
- Clear UI integration points in photo viewer

### Key Discoveries:

- ONNX models already uploaded to `https://models.ente.io/` (per spec)
- `MlModel` abstract class provides complete model lifecycle management (lib/services/machine_learning/ml_model.dart:11-194)
- Face detection service shows exact pattern to follow (lib/services/machine_learning/face_ml/face_detection/face_detection_service.dart:17-187)
- FileAppBar has established pattern for adding action buttons (lib/ui/viewer/file/file_app_bar.dart:157-384)
- Image preprocessing utilities with bilinear/bicubic interpolation ready (lib/utils/image_ml_util.dart:608-742)
- Android plugin supports adding new model types (plugins/onnx_dart/android/src/main/kotlin/io/ente/photos/onnx_dart/OnnxDartPlugin.kt:38-40)

## Desired End State

After implementation, users will be able to:
1. Open any image in the photo viewer
2. Tap an OCR button (visible only to internal users via feature flag)
3. See a loading indicator while processing
4. View extracted text in a dialog with copy functionality
5. Copy text to clipboard with one tap

### Verification:
- OCR models download automatically when first used
- Text extraction works for clear printed/typed English text
- Processing completes in < 2 seconds for typical images
- No UI jank during processing (direct processing for MVP)
- Feature properly gated behind internal user flag

## What We're NOT Doing

- **No isolate processing** - Direct processing in main thread for MVP
- **No result caching** - Text exists only during the session
- **No batch processing** - Single image only
- **No multi-language support** - English only with single dictionary
- **No search integration** - OCR remains separate from search
- **No background indexing** - Manual trigger only
- **No database storage** - No persistence of results

## Implementation Approach

Following the existing face detection pattern, we'll create four services:
1. Three model services extending `MlModel` (detection, classification, recognition)
2. Main OCR service orchestrating the pipeline
3. Direct integration with photo viewer UI
4. Feature flag for internal users

- [ ] Phase 1: Model Services & Core OCR Logic
- [ ] Phase 2: Image Preprocessing Functions
- [ ] Phase 3: Postprocessing & CTC Decoding
- [ ] Phase 4: Android Plugin Extension
- [ ] Phase 5: Feature Flag Setup
- [ ] Phase 6: UI Integration
- [ ] Phase 7: Final Integration & Testing

## Phase 1: Model Services & Core OCR Logic

### Overview

Create the three model services and main orchestration service following the established ML patterns.

### Changes Required:

- [ ] Create text detection model service
- [ ] Create text classification model service
- [ ] Create text recognition model service with dictionary loading
- [ ] Create main OCR service to orchestrate the pipeline
- [ ] Add data models for text boxes and results

#### 1. Text Detection Model Service

**File**: `lib/services/machine_learning/ocr/text_detection_service.dart`
**Changes**: Create new service extending MlModel

```dart
class TextDetectionService extends MlModel {
  static const kRemoteBucketModelPath = 'text_detection_rapidOCR_v1.onnx';
  static const _modelName = 'TextDetection';

  // Singleton pattern
  static final instance = TextDetectionService._privateConstructor();

  static Future<List<TextBox>> predict(
    Dimensions dimensions,
    Uint8List rawRgbaBytes,
    int sessionAddress,
  ) async {
    // Preprocess image
    final input = await preprocessImageTextDetection(dimensions, rawRgbaBytes);
    // Run inference
    final output = MlModel.usePlatformPlugin
        ? await _runPlatformPluginPredict(input)
        : _runFFIBasedPredict(sessionAddress, input);
    // Postprocess to get text boxes
    return postprocessTextDetection(output);
  }
}
```

#### 2. Text Classification Model Service

**File**: `lib/services/machine_learning/ocr/text_classification_service.dart`
**Changes**: Create service for orientation classification

```dart
class TextClassificationService extends MlModel {
  static const kRemoteBucketModelPath = 'text_classifier_rapidOCR_v1.onnx';
  static const _modelName = 'TextClassification';

  static Future<List<bool>> predict(
    List<Uint8List> textRegions,
    int sessionAddress,
  ) async {
    final input = await preprocessBatch(textRegions);
    // Returns true if needs 180° rotation
    return output.map((probs) => probs[1] > 0.9).toList();
  }
}
```

#### 3. Text Recognition Model Service

**File**: `lib/services/machine_learning/ocr/text_recognition_service.dart`
**Changes**: Create service with dictionary loading

```dart
class TextRecognitionService extends MlModel {
  static const kRemoteBucketModelPath = 'text_recognition_rapidOCR_v1.onnx';
  static const kDictRemotePath = 'en_dict_rapidOCR_v1.txt';

  late List<String> _characterDict;

  Future<void> loadDictionary() async {
    final dictPath = await RemoteAssetsService.instance.getAsset(
      kModelBucketEndpoint + kDictRemotePath,
    );
    _characterDict = await File(dictPath).readAsLines();
  }

  static Future<List<String>> predict(
    List<Uint8List> orientedRegions,
    int sessionAddress,
  ) async {
    // Preprocess, predict, and CTC decode
    return _ctcDecode(output, instance._characterDict);
  }
}
```

#### 4. Main OCR Service

**File**: `lib/services/machine_learning/ocr/ocr_service.dart`
**Changes**: Create orchestration service

```dart
class OCRService {
  static final OCRService instance = OCRService._internal();

  Future<String> extractText(Uint8List imageBytes, Dimensions dimensions) async {
    try {
      await _initializeIfNeeded();

      // Step 1: Detect text regions
      final textBoxes = await TextDetectionService.predict(
        dimensions, imageBytes, _detectionSession!,
      );

      // Step 2: Crop and classify orientation
      final textRegions = await _cropTextRegions(imageBytes, textBoxes);
      final needsRotation = await TextClassificationService.predict(
        textRegions, _classificationSession!,
      );

      // Step 3: Recognize text
      final orientedRegions = _applyRotations(textRegions, needsRotation);
      final texts = await TextRecognitionService.predict(
        orientedRegions, _recognitionSession!,
      );

      return texts.join('\n');
    } finally {
      await _unloadSessions(); // Free memory after use
    }
  }
}
```

#### 5. Data Models

**File**: `lib/models/ml/ocr/text_box.dart`
**Changes**: Create data model for text detection results

```dart
class TextBox {
  final List<List<double>> polygon;
  final double score;

  TextBox({required this.polygon, required this.score});

  List<double> getBoundingRect() {
    // Return [minX, minY, maxX, maxY]
  }
}
```

### Success Criteria:

#### Automated Verification:

- [ ] Dart format passes: `dart format lib/services/machine_learning/ocr/`
- [ ] Flutter analyze passes: `flutter analyze`
- [ ] All model services compile without errors
- [ ] Model paths correctly reference CDN endpoints

#### Manual Verification:

- Not needed at this phase, will test in later phases

---

## Phase 2: Image Preprocessing Functions

### Overview

Add OCR-specific preprocessing functions following RapidOCR specifications.

### Changes Required:

- [ ] Add text detection preprocessing (resize to multiple of 32, normalize)
- [ ] Add text classification preprocessing (resize to 192x48)
- [ ] Add text recognition preprocessing (resize to height 48, max width 320)
- [ ] Add helper functions for cropping text regions

#### 1. Text Detection Preprocessing

**File**: `lib/utils/image_ml_util.dart`
**Changes**: Add preprocessing function for detection model

```dart
Future<(Float32List, Dimensions)> preprocessImageTextDetection(
  Dimensions dim,
  Uint8List rawRgbaBytes,
) async {
  // Calculate resize dimensions
  double ratio = 1.0;
  if (min(dim.height, dim.width) < 736) {
    ratio = 736.0 / min(dim.height, dim.width);
  }

  int resizeH = (dim.height * ratio).round();
  int resizeW = (dim.width * ratio).round();

  // Round to nearest 32
  resizeH = (resizeH / 32).round() * 32;
  resizeW = (resizeW / 32).round() * 32;

  // Process pixels with normalization ((pixel/255 - 0.5)/0.5)
  // Store in CHW format

  return (processedBytes, Dimensions(width: resizeW, height: resizeH));
}
```

#### 2. Text Classification Preprocessing

**File**: `lib/utils/image_ml_util.dart`
**Changes**: Add batch preprocessing for orientation classifier

```dart
Future<Float32List> preprocessTextOrientationClassifier(
  List<Uint8List> textRegions,
) async {
  const int requiredWidth = 192;
  const int requiredHeight = 48;

  // Process each region:
  // 1. Resize to 192x48
  // 2. Normalize ((pixel/255 - 0.5)/0.5)
  // 3. Convert to CHW format
  // 4. Stack into batch [N, 3, 48, 192]

  return processedBytes;
}
```

#### 3. Text Recognition Preprocessing

**File**: `lib/utils/image_ml_util.dart`
**Changes**: Add preprocessing maintaining aspect ratio

```dart
Future<Float32List> preprocessTextRecognition(
  List<Uint8List> textRegions,
) async {
  const int targetHeight = 48;
  const int maxWidth = 320;

  // For each region:
  // 1. Calculate resize ratio maintaining aspect ratio
  // 2. Resize to height 48
  // 3. Pad to width 320 if needed
  // 4. Normalize and convert to CHW

  return preprocessedData;
}
```

#### 4. Image Cropping Utilities

**File**: `lib/services/machine_learning/ocr/ocr_image_utils.dart`
**Changes**: Create utilities for cropping detected text regions

```dart
Future<List<Uint8List>> cropTextRegions(
  Uint8List imageBytes,
  List<TextBox> textBoxes,
  Dimensions imageDim,
) async {
  final image = await decodeImageFromData(imageBytes);
  final croppedRegions = <Uint8List>[];

  for (final box in textBoxes) {
    // Calculate crop with padding
    // Handle rotation if needed
    // Crop using Canvas
    croppedRegions.add(croppedBytes);
  }

  return croppedRegions;
}
```

### Success Criteria:

#### Automated Verification:

- [ ] Dart format passes: `dart format lib/utils/`
- [ ] Flutter analyze passes: `flutter analyze`
- [ ] All preprocessing functions compile

#### Manual Verification:

- Not needed at this phase

---

## Phase 3: Postprocessing & CTC Decoding

### Overview

Implement detection postprocessing and CTC decoding for text recognition.

### Changes Required:

- [ ] Implement text detection postprocessing (threshold, contours, unclipping)
- [ ] Implement CTC decoding for text recognition
- [ ] Add helper functions for contour detection and polygon operations

#### 1. Text Detection Postprocessing

**File**: `lib/services/machine_learning/ocr/text_detection_postprocessing.dart`
**Changes**: Create postprocessing for detection model

```dart
List<TextBox> postprocessTextDetection(
  Float32List output,
  Dimensions originalImageSize,
  Dimensions preprocessedSize, {
  double threshold = 0.3,
  double boxThresh = 0.5,
  double unclipRatio = 1.6,
}) {
  // 1. Apply threshold to create binary map
  // 2. Find contours
  // 3. Unclip boxes by factor
  // 4. Filter by score and size
  // 5. Map coordinates back to original image

  return textBoxes;
}
```

#### 2. CTC Decoding

**File**: `lib/utils/image_ml_util.dart`
**Changes**: Add CTC decoding function

```dart
List<String> ctcDecode(
  Float32List output,
  List<String> characterDict, {
  int batchSize = 1,
  int sequenceLength = 80,
  int vocabSize = 97,
}) {
  final results = <String>[];

  for (int batchIndex = 0; batchIndex < batchSize; batchIndex++) {
    String decodedText = "";
    int previousIndex = -1;

    for (int timeStep = 0; timeStep < sequenceLength; timeStep++) {
      // Find max probability character
      // Apply CTC rules (skip blanks and repeats)
      if (maxIndex > 0 && maxIndex != previousIndex) {
        decodedText += characterDict[maxIndex - 1];
      }
      previousIndex = maxIndex;
    }

    results.add(decodedText.trim());
  }

  return results;
}
```

#### 3. Contour Detection Helpers

**File**: `lib/services/machine_learning/ocr/text_detection_postprocessing.dart`
**Changes**: Add helper functions for contour operations

```dart
List<List<List<int>>> _findContours(List<List<bool>> binaryMap) {
  // Connected components algorithm
  // 8-connectivity for finding text regions
}

double _calculateContourArea(List<List<int>> contour) {
  // Shoelace formula for polygon area
}

List<List<double>> _expandPolygon(List<List<int>> polygon, double distance) {
  // Expand polygon by offset distance
}
```

### Success Criteria:

#### Automated Verification:

- [ ] Dart format passes: `dart format lib/services/machine_learning/ocr/`
- [ ] Flutter analyze passes: `flutter analyze`
- [ ] Postprocessing functions compile

#### Manual Verification:

- Not needed at this phase

---

## Phase 4: Android Plugin Extension

### Overview

Add OCR model types to the Android ONNX plugin for platform-specific inference.

### Changes Required:

- [ ] Add OCR model types to ModelType enum
- [ ] Add OCR-specific input tensor shapes
- [ ] Handle OCR model initialization

#### 1. Update Model Type Enum

**File**: `plugins/onnx_dart/android/src/main/kotlin/io/ente/photos/onnx_dart/OnnxDartPlugin.kt`
**Changes**: Add OCR models to enum (around line 38)

```kotlin
enum class ModelType {
  ClipTextEncoder, ClipImageEncoder, YOLOv5Face, MobileFaceNet,
  TextDetection, TextClassification, TextRecognition  // Add these
}
```

#### 2. Update Input Tensor Shapes

**File**: `plugins/onnx_dart/android/src/main/kotlin/io/ente/photos/onnx_dart/OnnxDartPlugin.kt`
**Changes**: Add tensor shapes in predict method (around line 178)

```kotlin
when (modelType) {
  // Existing cases...
  ModelType.TextDetection -> {
    // Dynamic shape will be provided via inputShapeArray
    inputTensorShape = inputShapeArray?.map { it.toLong() }?.toLongArray()
        ?: longArrayOf(1, 3, 640, 640)
  }
  ModelType.TextClassification -> {
    val batchSize = inputDataFloat!!.size.toLong() / (3 * 48 * 192)
    inputTensorShape = longArrayOf(batchSize, 3, 48, 192)
  }
  ModelType.TextRecognition -> {
    val batchSize = inputDataFloat!!.size.toLong() / (3 * 48 * 320)
    inputTensorShape = longArrayOf(batchSize, 3, 48, 320)
  }
}
```

### Success Criteria:

#### Automated Verification:

- [ ] Kotlin code compiles: `cd plugins/onnx_dart && flutter build apk`
- [ ] No linting errors in plugin

#### Manual Verification:

- Not needed at this phase

---

## Phase 5: Feature Flag Setup

### Overview

Add OCR feature flag to enable gradual rollout to internal users.

### Changes Required:

- [ ] Add ocrEnabled getter to FlagService

#### 1. Add Feature Flag

**File**: `plugins/ente_feature_flag/lib/src/service.dart`
**Changes**: Add OCR flag getter (after line 71)

```dart
bool get ocrEnabled => internalUser;
```

### Success Criteria:

#### Automated Verification:

- [ ] Dart format passes: `dart format plugins/ente_feature_flag/`
- [ ] Flutter analyze passes: `flutter analyze`

#### Manual Verification:

- Not needed at this phase

---

## Phase 6: UI Integration

### Overview

Add OCR button to photo viewer and create result dialog.

### Changes Required:

- [ ] Add OCR menu item to FileAppBar
- [ ] Create OCR result dialog component
- [ ] Add loading indicator during processing
- [ ] Implement clipboard integration

#### 1. Add OCR Button to Photo Viewer

**File**: `lib/ui/viewer/file/file_app_bar.dart`
**Changes**: Add OCR menu item (around line 338)

```dart
// In _getActions() method, add before the PopupMenuButton:
if (flagService.ocrEnabled && widget.file.fileType == FileType.image) {
  items.add(
    EntePopupMenuItem(
      'Extract text',
      value: 11,
      icon: Icons.text_fields_outlined,
      iconColor: Theme.of(context).iconTheme.color,
    ),
  );
}

// In onSelected callback (around line 378):
else if (value == 11) {
  await _extractText();
}

// Add new method:
Future<void> _extractText() async {
  showLoadingDialog(context: context, message: 'Extracting text...');

  try {
    final fileData = await getFile(widget.file);
    if (fileData == null) throw Exception('Could not load image');

    final decodedImage = await decodeImageFromPath(
      widget.file.localID!,
      includeRgbaBytes: true,
      includeDartUiImage: false,
    );

    final text = await OCRService.instance.extractText(
      decodedImage.rawRgbaBytes!,
      decodedImage.dimensions,
    );

    Navigator.of(context).pop(); // Close loading

    if (text.isEmpty) {
      showToast(context, 'No text found in image');
      return;
    }

    await _showOCRResultDialog(text);
  } catch (e) {
    Navigator.of(context).pop();
    showToast(context, 'Failed to extract text');
    _logger.severe('OCR failed', e);
  }
}
```

#### 2. Create OCR Result Dialog

**File**: `lib/ui/viewer/file/ocr_result_dialog.dart`
**Changes**: Create new dialog component

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/dialog_widget.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';

Future<void> showOCRResultDialog(
  BuildContext context,
  String extractedText,
) async {
  final colorScheme = getEnteColorScheme(context);
  final textTheme = getEnteTextTheme(context);

  return showDialogWidget(
    context: context,
    title: 'Extracted Text',
    body: Container(
      constraints: BoxConstraints(maxHeight: 400),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.fillFaint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          extractedText,
          style: textTheme.body,
        ),
      ),
    ),
    buttons: [
      ButtonWidget(
        buttonType: ButtonType.secondary,
        labelText: 'Copy',
        icon: Icons.copy_outlined,
        isInAlert: true,
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: extractedText));
          showToast(context, 'Copied to clipboard');
        },
      ),
      ButtonWidget(
        buttonType: ButtonType.primary,
        labelText: 'Done',
        isInAlert: true,
        onTap: () => Navigator.of(context).pop(),
      ),
    ],
  );
}
```

#### 3. Add Required Imports

**File**: `lib/ui/viewer/file/file_app_bar.dart`
**Changes**: Add imports at the top

```dart
import 'package:photos/services/machine_learning/ocr/ocr_service.dart';
import 'package:photos/ui/viewer/file/ocr_result_dialog.dart';
import 'package:photos/utils/image_ml_util.dart';
```

### Success Criteria:

#### Automated Verification:

- [ ] Dart format passes: `dart format lib/ui/viewer/`
- [ ] Flutter analyze passes: `flutter analyze`
- [ ] No hardcoded colors or text styles

#### Manual Verification:

- [ ] OCR button appears for internal users only
- [ ] Loading dialog shows during processing
- [ ] Text displays correctly in dialog
- [ ] Copy button works correctly
- [ ] Dialog dismisses properly

---

## Phase 7: Final Integration & Testing

### Overview

Complete final integration, ensure all components work together, and validate the MVP requirements.

### Changes Required:

- [ ] Wire up all services
- [ ] Add error handling
- [ ] Validate performance
- [ ] Test edge cases

#### 1. Service Registration

**File**: `lib/services/machine_learning/ml_models_overview.dart`
**Changes**: Register OCR models (if this file exists)

```dart
enum MLModelsExtension {
  // Existing models...
  textDetection,
  textClassification,
  textRecognition,
}
```

#### 2. Error Handling

Ensure all error cases are handled:
- Model download failures
- Processing timeouts (10 second max)
- Empty text results
- Invalid image formats

### Success Criteria:

#### Automated Verification:

- [ ] Full project dart format: `dart format .`
- [ ] Full project analyze: `flutter analyze`

#### Manual Verification:

- [ ] OCR button visible for internal users only
- [ ] Models download automatically on first use
- [ ] Text extraction works for clear English text
- [ ] Processing time < 2 seconds for typical images
- [ ] Copy to clipboard works
- [ ] No UI jank during processing
- [ ] Memory properly released after use
- [ ] Feature flag properly gates functionality

---

## Testing Strategy

### Manual Testing Steps:

1. Enable debug mode or set as internal user
2. Open any image with text in photo viewer
3. Tap three-dot menu and select "Extract text"
4. Verify loading indicator appears
5. Verify text appears in dialog (for images with text)
6. Test copy button functionality
7. Test with images without text (should show toast)
8. Test with blurry/low quality images
9. Monitor memory usage in Android Studio
10. Verify models are downloaded only once

## Performance Considerations

- Models total ~16MB, downloaded on first use
- Direct processing without isolate (acceptable for MVP)
- Models unloaded after each use to save memory
- 10-second timeout for processing

## Migration Notes

Not applicable - this is a new feature with no existing data to migrate.

## References

- Original specification: `.claude/specs/ocr_mvp_implementation_spec.md`
- Model specifications: `.claude/specs/OCR_MODELS_SPECIFICATION.md`
- Research document: `.claude/research/research_ocr_mvp_implementation.md`
- Face detection reference: `lib/services/machine_learning/face_ml/face_detection/face_detection_service.dart:17-187`