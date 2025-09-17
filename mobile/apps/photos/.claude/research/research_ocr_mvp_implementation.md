---
date: 2025-09-17T10:45:00+00:00
topic: "OCR MVP Implementation - Current State and Requirements"
tags: [research, codebase, ocr, ml, onnx, rapidocr, photo-viewer, feature-flag]
status: complete
last_updated: 2025-09-17
---

# Research: OCR MVP Implementation - Current State and Requirements

## Research Question

Analyze the OCR MVP implementation spec and understand the current state of the codebase to determine what exists and what needs to be built for implementing on-the-fly OCR functionality in Ente Photos.

## Summary

The Ente Photos codebase is **well-prepared** for OCR implementation with a mature ONNX runtime infrastructure, sophisticated model management system, and comprehensive UI patterns. The OCR feature is currently in the **specification phase** with detailed planning documents but **no implementation yet**. All foundational components (ONNX runtime, model downloading, UI patterns, feature flags) exist and are production-ready. The implementation would primarily involve creating the OCR service, adding UI components, and integrating with the existing infrastructure.

## Detailed Findings

### ONNX Runtime and ML Infrastructure

The app has a **dual-platform ONNX runtime system** with excellent abstraction:

- **Custom ONNX Plugin** (`plugins/onnx_dart/`) - Native Kotlin implementation for Android
- **FFI-based Runtime** (`lib/services/machine_learning/onnx_env.dart`) - Direct ONNX binding for iOS
- **Unified Model Interface** (`lib/services/machine_learning/ml_model.dart`) - Abstract base class for all ML models
- **Platform Auto-Selection**: `Platform.isAndroid` determines runtime choice

**Current Production Models:**
- YOLOv5Face for face detection (`yolov5s_face_640_640_dynamic.onnx`)
- MobileFaceNet for face embedding
- CLIP Image/Text encoders for semantic search (`mobileclip_s2_*.onnx`)

**Key Infrastructure Components:**
- **MLService** (`lib/services/machine_learning/ml_service.dart`) - Main ML orchestrator
- **MLIndexingIsolate** (`lib/services/machine_learning/ml_indexing_isolate.dart`) - Isolate-based processing to prevent UI blocking
- **Session Management**: Concurrent ONNX sessions per model type

### Model Management System

Sophisticated asset management infrastructure ready for OCR models:

- **RemoteAssetsService** (`lib/services/remote_assets_service.dart`) - Downloads and caches models
- **Base URL**: `https://models.ente.io/` (ready for OCR models)
- **Storage**: Application support directory with automatic cleanup
- **Download Features**:
  - Progress tracking
  - Atomic operations with temp files
  - Size-based update detection
  - Bandwidth-aware downloads
- **Size Limits**: `maxFileDownloadSize = 100MB` for mobile indexing

### Photo Viewer UI Architecture

The photo viewer has clear integration points for OCR:

- **DetailPage** (`lib/ui/viewer/file/detail_page.dart`) - Main photo viewer with PageView
- **FileAppBar** (`lib/ui/viewer/file/file_app_bar.dart`) - **Target location for OCR button** (line 157-384)
- **FileBottomBar** (`lib/ui/viewer/file/file_bottom_bar.dart`) - Alternative button location
- **Dialog System** (`lib/utils/dialog_util.dart`) - Ready for OCR result display

**Current Button Pattern in FileAppBar:**
```dart
List<Widget> _getActions() {
  _actions.clear();
  // Conditional button addition
  if (widget.file.isLiveOrMotionPhoto) {
    _actions.add(IconButton(...));
  }
  // Add OCR button here following same pattern
}
```

### Feature Flag System

Complete feature flag infrastructure ready for OCR:

- **FlagService** (`plugins/ente_feature_flag/lib/src/service.dart`) - Central feature management
- **Internal User Support**: `bool get internalUser => flags.internalUser || kDebugMode`
- **Pattern for OCR**: Add `bool get ocrEnabled => internalUser`
- **UI Integration**: Conditional rendering based on flags

### Theme and UI Components

Strong design system for consistent UI:

- **Theme Access**: Always use `getEnteColorScheme(context)` and `getEnteTextTheme(context)`
- **Dialog Components**: `DialogWidget` and `showDialogWidget()` for result display
- **Button Components**: `ButtonWidget` with consistent styling
- **Never hardcode colors** - Use theme system exclusively

### OCR-Specific Planning

Comprehensive specifications exist in `.claude/specs/`:

**Primary Specification Documents:**
- `.claude/specs/ocr_mvp_implementation_spec.md` - Complete implementation specification
- `.claude/specs/OCR_MODELS_SPECIFICATION.md` - Detailed technical model specifications with preprocessing/postprocessing algorithms

**Planned Models (RapidOCR):**
1. **Text Detection**: `text_detection_rapidOCR_v1.onnx` (4.2MB)
   - Source: `en_PP-OCRv3_det_infer.onnx` from ModelScope
   - Input: `[1, 3, H, W]` (H/W divisible by 32)
   - Output: Probability map `[1, 1, H/4, W/4]`

2. **Orientation Classifier**: `text_classifier_rapidOCR_v1.onnx` (1.4MB)
   - Source: `ch_ppocr_mobile_v2.0_cls_infer.onnx`
   - Input: `[N, 3, 48, 192]` fixed dimensions
   - Output: `[N, 2]` softmax probabilities for 0°/180°

3. **Text Recognition**: `text_recognition_rapidOCR_v1.onnx` (10MB)
   - Source: `en_PP-OCRv4_rec_infer.onnx`
   - Input: `[N, 3, 48, 320]` (width can be less, padded)
   - Output: `[N, 80, 97]` CTC logits (80 timesteps, 97 vocab)

4. **Character Dictionary**: `en_dict_rapidOCR_v1.txt`
   - 96 English characters + blank token
   - Required for CTC decoding

**Processing Pipeline (from OCR_MODELS_SPECIFICATION.md):**
```
Input Image → [Detection] → Text Regions → [Classification] → Oriented Regions → [Recognition] → Text
```

**Detailed Processing Steps:**
1. **Detection**: Resize (min 736px, round to 32), normalize `((pixel/255 - 0.5)/0.5)`, threshold at 0.3
2. **Classification**: Crop regions, resize to 48x192, determine 0° or 180° rotation
3. **Recognition**: Resize to height 48 (max width 320), CTC decode with character dictionary

**Performance Constraints:**
- Processing time < 2 seconds for typical image
- Min text height: 10px for detection
- Max image size: 2000px longest side
- Batch size: 6 regions (configurable)
- Box filter: score > 0.5, dimensions > 3x3
- Timeout: 10 seconds max
- Memory: Unload models after use

## Code References

### Core Infrastructure
- `lib/services/machine_learning/ml_service.dart:89-112` - ML service initialization
- `lib/services/machine_learning/ml_model.dart:34-67` - Model download interface
- `lib/services/machine_learning/ml_indexing_isolate.dart:78-95` - Isolate processing pattern
- `plugins/onnx_dart/android/src/main/kotlin/io/ente/photos/onnx_dart/OnnxDartPlugin.kt:45-89` - ONNX session management

### UI Integration Points
- `lib/ui/viewer/file/file_app_bar.dart:157-384` - Action button addition location
- `lib/ui/viewer/file/detail_page.dart:234-289` - Main viewer widget structure
- `lib/utils/dialog_util.dart:45-78` - Dialog display utilities
- `lib/theme/ente_theme.dart:89-112` - Theme access patterns

### Model Management
- `lib/services/remote_assets_service.dart:34-67` - Asset download service
- `lib/services/machine_learning/ml_versions.dart:12-23` - Version constants
- `lib/utils/ml_util.dart:345-348` - File size validation

### Feature Flags
- `plugins/ente_feature_flag/lib/src/service.dart:45-56` - Flag service getters
- `lib/service_locator.dart:134` - Service registration

## Architecture Insights

### Strengths
1. **Mature Infrastructure**: All foundational components exist and are production-tested
2. **Clean Abstractions**: Well-defined interfaces for models, services, and UI
3. **Performance-Oriented**: Isolate-based processing, lazy loading, automatic cleanup
4. **Safety-First**: Feature flags, size limits, timeout handling

### Patterns to Follow
1. **Service Pattern**: Create `OCRService` extending `MlModel` abstract class
2. **Isolate Processing**: Use `MLIndexingIsolate` for OCR operations
3. **Progressive Loading**: Load OCR models only when needed
4. **UI Integration**: Follow existing button/dialog patterns in photo viewer

### Implementation Path
1. **Extend Android Plugin**: Add OCR model types to `OnnxDartPlugin.kt`
2. **Create OCR Service**: Implement following `MlModel` interface
3. **Add Feature Flag**: Simple getter in `FlagService`
4. **Build UI Components**: OCR button and result dialog
5. **Wire Everything**: Connect service to UI through existing patterns

## MVP Scope Clarifications

### What We're Building
- Single-image text extraction with manual trigger
- On-demand processing (user initiated)
- English-only support
- Simple copy-to-clipboard functionality
- Feature-flagged for internal users initially

### What We're NOT Building (Explicitly Out of Scope)

1. **No Result Caching/Storage**
   - No database tables for OCR results
   - No persistence of extracted text
   - Results exist only during the session

2. **No Batch Processing**
   - Single image processing only
   - Keep implementation simple and focused
   - No queue or batch optimization

3. **No Multi-Language Support**
   - English-only with `en_dict_rapidOCR_v1.txt`
   - No architecture for multiple dictionaries
   - Simplifies CTC decoding implementation

4. **No Search Integration**
   - OCR remains completely separate from semantic search
   - No indexing of extracted text
   - No integration with existing search infrastructure

5. **No Additional Privacy Controls**
   - Standard ML consent is sufficient
   - No special privacy settings for OCR
   - Same privacy model as other ML features

6. **No Isolate Processing (Initially)**
   - Direct processing in main thread for MVP
   - Isolate support can be added later
   - Simpler implementation and debugging

7. **No Background Processing**
   - No automatic OCR on photo library
   - No background indexing
   - Manual trigger only

## Next Steps

The codebase is **ready for OCR implementation** with all infrastructure in place. The implementation would be straightforward following existing patterns:

1. Create **separate ML model services** for each OCR model (models will auto-download from CDN)
2. Create main `OCRService` that orchestrates the three model services
3. Add simple OCR option to photo viewer app bar
4. Add feature flag for gradual rollout
5. Test with internal users first

**Note on Model Downloads**: The OCR models are **already uploaded** to `https://models.ente.io/`. The existing `MlModel` abstract class and `RemoteAssetsService` will automatically handle downloading and caching when the model services are initialized. No manual download is needed.

**Important**: Following the existing ML architecture, we need **four separate services**:
- `TextDetectionService` - Manages the detection model
- `TextClassificationService` - Manages the orientation classifier model
- `TextRecognitionService` - Manages the recognition model
- `OCRService` - Orchestrates the three models and handles the complete pipeline

## Key Implementation Code Snippets

### 1. Feature Flag Addition
**File**: `plugins/ente_feature_flag/lib/src/service.dart`
```dart
// Add to FlagService class
bool get ocrEnabled => internalUser;
```

### 2. Text Detection Model Service
**File**: `lib/services/machine_learning/ocr/text_detection_service.dart`
```dart
import "package:photos/services/machine_learning/ml_model.dart";

class TextDetectionService extends MlModel {
  static const kRemoteBucketModelPath = 'text_detection_rapidOCR_v1.onnx';
  static const _modelName = 'TextDetection';

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  @override
  String get modelName => _modelName;

  @override
  Logger get logger => _logger;
  static final _logger = Logger('TextDetectionService');

  // Singleton pattern
  TextDetectionService._privateConstructor();
  static final instance = TextDetectionService._privateConstructor();
  factory TextDetectionService() => instance;

  static Future<List<TextBox>> predict(
    Dimensions dimensions,
    Uint8List rawRgbaBytes,
    int sessionAddress,
  ) async {
    // Preprocess: resize to multiple of 32, normalize
    final input = await _preprocessImage(dimensions, rawRgbaBytes);

    // Run inference using platform plugin or FFI
    final output = MlModel.usePlatformPlugin
        ? await _runPlatformPluginPredict(input)
        : _runFFIBasedPredict(sessionAddress, input);

    // Postprocess: threshold, find contours, unclip
    return _postprocessDetection(output);
  }
}
```

### 3. Text Classification Model Service
**File**: `lib/services/machine_learning/ocr/text_classification_service.dart`
```dart
class TextClassificationService extends MlModel {
  static const kRemoteBucketModelPath = 'text_classifier_rapidOCR_v1.onnx';
  static const _modelName = 'TextClassification';

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  @override
  String get modelName => _modelName;

  // Singleton pattern
  TextClassificationService._privateConstructor();
  static final instance = TextClassificationService._privateConstructor();

  static Future<List<bool>> predict(
    List<Uint8List> textRegions,
    int sessionAddress,
  ) async {
    // Batch process up to 6 regions, resize to 192x48
    final input = await _preprocessBatch(textRegions);

    final output = MlModel.usePlatformPlugin
        ? await _runPlatformPluginPredict(input)
        : _runFFIBasedPredict(sessionAddress, input);

    // Return true if needs 180° rotation
    return output.map((probs) => probs[1] > probs[0] && probs[1] > 0.9).toList();
  }
}
```

### 4. Text Recognition Model Service
**File**: `lib/services/machine_learning/ocr/text_recognition_service.dart`
```dart
class TextRecognitionService extends MlModel {
  static const kRemoteBucketModelPath = 'text_recognition_rapidOCR_v1.onnx';
  static const kDictRemotePath = 'en_dict_rapidOCR_v1.txt';
  static const _modelName = 'TextRecognition';

  @override
  String get modelRemotePath => kModelBucketEndpoint + kRemoteBucketModelPath;

  @override
  String get modelName => _modelName;

  // Singleton pattern
  TextRecognitionService._privateConstructor();
  static final instance = TextRecognitionService._privateConstructor();

  late List<String> _characterDict;

  Future<void> loadDictionary() async {
    // Load dictionary from remote assets service
    final dictPath = await remoteAssetsService.getAsset(
      kModelBucketEndpoint + kDictRemotePath,
    );
    _characterDict = await File(dictPath).readAsLines();
  }

  static Future<List<String>> predict(
    List<Uint8List> orientedRegions,
    int sessionAddress,
  ) async {
    // Preprocess: resize to height 48, max width 320
    final input = await _preprocessBatch(orientedRegions);

    final output = MlModel.usePlatformPlugin
        ? await _runPlatformPluginPredict(input)
        : _runFFIBasedPredict(sessionAddress, input);

    // CTC decode with character dictionary
    return _ctcDecode(output, instance._characterDict);
  }

  static List<String> _ctcDecode(List<double> output, List<String> dict) {
    // Implement CTC decoding as per spec
    // Skip blanks and repeated characters
  }
}
```

### 5. Main OCR Service
**File**: `lib/services/machine_learning/ocr/ocr_service.dart`
```dart
class OCRService {
  static final OCRService instance = OCRService._internal();
  OCRService._internal();

  static final _logger = Logger('OCRService');

  int? _detectionSession;
  int? _classificationSession;
  int? _recognitionSession;

  Future<String> extractText(Uint8List imageBytes, Dimensions dimensions) async {
    try {
      // Initialize models and sessions if needed
      await _initializeIfNeeded();

      // Step 1: Detect text regions
      final textBoxes = await TextDetectionService.predict(
        dimensions,
        imageBytes,
        _detectionSession!,
      );
      if (textBoxes.isEmpty) return '';

      // Step 2: Crop regions from image
      final textRegions = await _cropTextRegions(imageBytes, textBoxes);

      // Step 3: Classify orientation
      final needsRotation = await TextClassificationService.predict(
        textRegions,
        _classificationSession!,
      );
      final orientedRegions = _applyRotations(textRegions, needsRotation);

      // Step 4: Recognize text
      final texts = await TextRecognitionService.predict(
        orientedRegions,
        _recognitionSession!,
      );

      return texts.join('\n');
    } catch (e, s) {
      _logger.severe('OCR extraction failed', e, s);
      rethrow;
    } finally {
      // Unload models after use to save memory
      await _unloadSessions();
    }
  }

  Future<void> _initializeIfNeeded() async {
    if (_detectionSession == null) {
      // Download models if needed (handled by MlModel)
      await TextDetectionService.instance.downloadModelSafe();
      await TextClassificationService.instance.downloadModelSafe();
      await TextRecognitionService.instance.downloadModelSafe();
      await TextRecognitionService.instance.loadDictionary();

      // Load models into sessions
      _detectionSession = await TextDetectionService.instance.loadModel();
      _classificationSession = await TextClassificationService.instance.loadModel();
      _recognitionSession = await TextRecognitionService.instance.loadModel();
    }
  }

  Future<void> _unloadSessions() async {
    // Unload models to free memory
    if (_detectionSession != null) {
      await TextDetectionService.instance.releaseModel(_detectionSession!);
      _detectionSession = null;
    }
    // Similar for other sessions...
  }
}
```

### 6. UI Integration - OCR Button
**File**: `lib/ui/viewer/file/file_app_bar.dart` (around line 200)
```dart
List<Widget> _getActions() {
  _actions.clear();

  // Existing actions...

  // Add OCR button for internal users
  if (flagService.ocrEnabled && widget.file.fileType == FileType.image) {
    _actions.add(
      IconButton(
        icon: Icon(Icons.text_fields_outlined,
          color: getEnteColorScheme(context).blurTextBase),
        onPressed: _extractText,
        tooltip: 'Extract text',
      ),
    );
  }

  // Existing popup menu...
}

Future<void> _extractText() async {
  final l10n = AppLocalizations.of(context)!;

  showLoadingDialog(context: context, message: 'Extracting text...');

  try {
    final fileData = await getFile(widget.file);
    if (fileData == null) throw Exception('Could not load image');

    final text = await OCRService.instance.extractText(fileData);

    Navigator.of(context).pop(); // Close loading dialog

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

### 7. OCR Result Dialog
**File**: `lib/ui/viewer/file/ocr_result_dialog.dart`
```dart
class OCRResultDialog extends StatelessWidget {
  final String extractedText;

  const OCRResultDialog({required this.extractedText});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return DialogWidget(
      title: 'Extracted Text',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
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
        ],
      ),
      buttons: [
        ButtonWidget(
          buttonType: ButtonType.secondary,
          labelText: 'Copy',
          onTap: () {
            Clipboard.setData(ClipboardData(text: extractedText));
            showToast(context, 'Copied to clipboard');
          },
        ),
        ButtonWidget(
          buttonType: ButtonType.primary,
          labelText: 'Done',
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
```

### 8. Android Plugin Extension
**File**: `plugins/onnx_dart/android/src/main/kotlin/.../OnnxDartPlugin.kt`
```kotlin
// Add to ModelType enum
enum class ModelType {
  ClipTextEncoder,
  ClipImageEncoder,
  YOLOv5Face,
  MobileFaceNet,
  TextDetection,      // Add
  TextClassification, // Add
  TextRecognition    // Add
}

// Add to when statement in relevant methods
when (modelType) {
  // Existing cases...
  ModelType.TextDetection -> processTextDetection(input)
  ModelType.TextClassification -> processTextClassification(input)
  ModelType.TextRecognition -> processTextRecognition(input)
}
```

### 9. Preprocessing Functions in image_ml_util.dart
**File**: `lib/utils/image_ml_util.dart`

```dart
/// Preprocesses an image for text detection.
/// Takes raw RGBA image data and:
/// 1. Resizes the image so minimum dimension is 736px, rounded to nearest 32
/// 2. Normalizes pixels using ((pixel/255 - 0.5)/0.5)
/// 3. Converts from HWC to CHW format
/// Returns a tuple of (preprocessedData, resizedDimensions).
Future<(Float32List, Dimensions)> preprocessImageTextDetection(
  Dimensions dim,
  Uint8List rawRgbaBytes,
) async {
  // Step 1: Calculate resize dimensions according to spec
  double ratio = 1.0;
  if (min(dim.height, dim.width) < 736) {
    ratio = 736.0 / min(dim.height, dim.width);
  }

  int resizeH = (dim.height * ratio).round();
  int resizeW = (dim.width * ratio).round();

  // Round to nearest 32
  resizeH = (resizeH / 32).round() * 32;
  resizeW = (resizeW / 32).round() * 32;

  // Ensure minimum dimensions
  if (resizeH < 32) resizeH = 32;
  if (resizeW < 32) resizeW = 32;

  const int channels = 3;
  final int totalSize = channels * resizeH * resizeW;
  final Float32List processedBytes = Float32List(totalSize);

  // Calculate scaling factors for resizing
  final double scaleX = resizeW / dim.width;
  final double scaleY = resizeH / dim.height;

  // Channel offsets for CHW format: [C, H, W]
  final int channelOffsetGreen = resizeH * resizeW;
  final int channelOffsetBlue = 2 * resizeH * resizeW;

  int pixelIndex = 0;

  // Step 2 & 3: Process each pixel, normalize, and store in CHW format
  for (int h = 0; h < resizeH; h++) {
    for (int w = 0; w < resizeW; w++) {
      // Map output coordinates back to original image coordinates
      final double originalX = w / scaleX;
      final double originalY = h / scaleY;

      // Get pixel using bilinear interpolation
      final RGB pixel = _getPixelBilinear(
        originalX,
        originalY,
        dim,
        rawRgbaBytes,
      );

      // Step 2: Normalize using ((pixel/255 - 0.5)/0.5)
      final double normalizedR = ((pixel.$1 / 255.0) - 0.5) / 0.5;
      final double normalizedG = ((pixel.$2 / 255.0) - 0.5) / 0.5;
      final double normalizedB = ((pixel.$3 / 255.0) - 0.5) / 0.5;

      // Step 3: Store in CHW format
      processedBytes[pixelIndex] = normalizedR;
      processedBytes[pixelIndex + channelOffsetGreen] = normalizedG;
      processedBytes[pixelIndex + channelOffsetBlue] = normalizedB;

      pixelIndex++;
    }
  }

  final resizedDimensions = Dimensions(width: resizeW, height: resizeH);
  return (processedBytes, resizedDimensions);
}

/// Preprocesses cropped text regions for text orientation classification.
/// Resizes each region to fixed 192x48 dimensions and normalizes pixels.
/// Returns Float32List in CHW format for [N, 3, 48, 192] input where N is batch size.
Future<Float32List> preprocessTextOrientationClassifier(
  List<Uint8List> textRegions,
) async {
  const int requiredWidth = 192;
  const int requiredHeight = 48;
  const int channels = 3;

  if (textRegions.isEmpty) {
    throw ArgumentError('textRegions cannot be empty');
  }

  final int batchSize = textRegions.length;
  final int totalSize = batchSize * channels * requiredHeight * requiredWidth;
  final Float32List processedBytes = Float32List(totalSize);

  for (int regionIndex = 0; regionIndex < batchSize; regionIndex++) {
    final Uint8List regionBytes = textRegions[regionIndex];

    // Decode the image from bytes
    final Image image = await decodeImageFromData(regionBytes);

    // Get raw RGBA bytes for processing
    final Uint8List rawRgbaBytes = await _getRawRgbaBytes(image);
    final Dimensions originalDim = Dimensions(width: image.width, height: image.height);

    // Calculate scaling factors for resizing to 192x48
    final double scaleX = requiredWidth / originalDim.width;
    final double scaleY = requiredHeight / originalDim.height;

    // Calculate the starting index for this region in the batch
    final int regionStartIndex = regionIndex * channels * requiredHeight * requiredWidth;

    // Channel offsets in CHW format: [N, C, H, W]
    const int channelOffsetGreen = requiredHeight * requiredWidth;
    const int channelOffsetBlue = 2 * requiredHeight * requiredWidth;

    int pixelIndex = 0;

    // Process each pixel in the resized 48x192 output
    for (int h = 0; h < requiredHeight; h++) {
      for (int w = 0; w < requiredWidth; w++) {
        // Map output coordinates back to original image coordinates
        final double originalX = w / scaleX;
        final double originalY = h / scaleY;

        // Get pixel using bilinear interpolation
        final RGB pixel = _getPixelBilinear(
          originalX,
          originalY,
          originalDim,
          rawRgbaBytes,
        );

        // Normalize: ((pixel/255 - 0.5)/0.5) = (pixel - 127.5) / 127.5
        final double normalizedR = (pixel.$1 - 127.5) / 127.5;
        final double normalizedG = (pixel.$2 - 127.5) / 127.5;
        final double normalizedB = (pixel.$3 - 127.5) / 127.5;

        // Store in CHW format: [N, C, H, W]
        processedBytes[regionStartIndex + pixelIndex] = normalizedR;
        processedBytes[regionStartIndex + pixelIndex + channelOffsetGreen] = normalizedG;
        processedBytes[regionStartIndex + pixelIndex + channelOffsetBlue] = normalizedB;

        pixelIndex++;
      }
    }
  }

  return processedBytes;
}

/// Preprocesses oriented text region images for text recognition model.
/// Takes a list of oriented text regions and returns preprocessed data in CHW format.
/// Output: Float32List in CHW format for [N, 3, 48, 320] input tensor
Future<Float32List> preprocessTextRecognition(
  List<Uint8List> textRegions,
) async {
  const int targetHeight = 48;
  const int maxWidth = 320;
  const int channels = 3;

  final int batchSize = textRegions.length;
  final Float32List preprocessedData =
      Float32List(batchSize * channels * targetHeight * maxWidth);

  for (int batchIndex = 0; batchIndex < batchSize; batchIndex++) {
    final Uint8List regionBytes = textRegions[batchIndex];

    // Decode the image from bytes
    final Image image = await decodeImageFromData(regionBytes);
    final int originalWidth = image.width;
    final int originalHeight = image.height;

    // Calculate resize ratio maintaining aspect ratio
    double ratio = targetHeight.toDouble() / originalHeight;
    int targetWidth = (originalWidth * ratio).round();

    // Limit maximum width
    if (targetWidth > maxWidth) {
      targetWidth = maxWidth;
      ratio = maxWidth.toDouble() / originalWidth;
    }

    // Get raw RGBA bytes for processing
    final Uint8List rawRgbaBytes = await _getRawRgbaBytes(image);
    final Dimensions originalDimensions =
        Dimensions(width: originalWidth, height: originalHeight);

    // Process each pixel for the resized and padded image
    final int batchOffset = batchIndex * channels * targetHeight * maxWidth;
    final int channelSize = targetHeight * maxWidth;

    for (int h = 0; h < targetHeight; h++) {
      for (int w = 0; w < maxWidth; w++) {
        late RGB pixel;

        if (w >= targetWidth) {
          // Right padding with black (0, 0, 0)
          pixel = const (0, 0, 0);
        } else {
          // Map back to original image coordinates
          final double originalX = w / ratio;
          final double originalY = h / ratio;

          // Get pixel using bilinear interpolation
          pixel = _getPixelBilinear(
            originalX,
            originalY,
            originalDimensions,
            rawRgbaBytes,
          );
        }

        // Normalize pixels: ((pixel/255 - 0.5)/0.5)
        final double normalizedR = ((pixel.$1 / 255.0) - 0.5) / 0.5;
        final double normalizedG = ((pixel.$2 / 255.0) - 0.5) / 0.5;
        final double normalizedB = ((pixel.$3 / 255.0) - 0.5) / 0.5;

        // Store in CHW format
        final int pixelIndex = h * maxWidth + w;
        preprocessedData[batchOffset + pixelIndex] = normalizedR; // R channel
        preprocessedData[batchOffset + channelSize + pixelIndex] = normalizedG; // G channel
        preprocessedData[batchOffset + 2 * channelSize + pixelIndex] = normalizedB; // B channel
      }
    }
  }

  return preprocessedData;
}
```

### 10. Postprocessing Functions
**File**: `lib/services/machine_learning/ocr/text_detection_postprocessing.dart`

```dart
/// Postprocesses text detection model output to extract text bounding boxes.
/// Takes model output [1, 1, H/4, W/4] probability map and:
/// 1. Applies threshold (0.3) to create binary map
/// 2. Finds contours and converts to text boxes
/// 3. Unclips boxes by factor 1.6
/// 4. Filters boxes (score > 0.5, size > 3x3)
/// 5. Maps coordinates back to original image dimensions
/// Returns list of TextBox objects with normalized coordinates.
List<TextBox> postprocessTextDetection(
  Float32List output,
  Dimensions originalImageSize,
  Dimensions preprocessedSize, {
  double threshold = 0.3,
  double boxThresh = 0.5,
  double unclipRatio = 1.6,
  int minSize = 3,
}) {
  // Extract dimensions - output is [1, 1, H/4, W/4]
  final int featureMapHeight = preprocessedSize.height ~/ 4;
  final int featureMapWidth = preprocessedSize.width ~/ 4;

  if (output.length != featureMapHeight * featureMapWidth) {
    throw ArgumentError(
      'Output size mismatch. Expected ${featureMapHeight * featureMapWidth}, got ${output.length}',
    );
  }

  // Step 1: Apply threshold to create binary map
  final List<List<bool>> binaryMap = List.generate(
    featureMapHeight,
    (y) => List.generate(featureMapWidth, (x) {
      final int index = y * featureMapWidth + x;
      return output[index] > threshold;
    }),
  );

  // Step 2: Find contours using a simple contour detection algorithm
  final List<List<List<int>>> contours = _findContours(binaryMap);

  final List<TextBox> textBoxes = [];

  // Process each contour
  for (final contour in contours) {
    if (contour.length < 4) continue; // Skip small contours

    // Step 3: Calculate contour properties for unclipping
    final double area = _calculateContourArea(contour);
    final double perimeter = _calculateContourPerimeter(contour);

    if (perimeter == 0) continue; // Avoid division by zero

    // Calculate confidence score (average probability in the contour region)
    final double score = _calculateContourScore(output, contour, featureMapWidth);

    if (score < boxThresh) continue; // Filter by score threshold

    // Step 4: Unclip the contour (expand by factor)
    final double distance = area * unclipRatio / perimeter;
    final List<List<double>> unclippedPolygon = _expandPolygon(contour, distance);

    // Step 5: Filter by size
    final boundingRect = _getBoundingRect(unclippedPolygon);
    final double width = boundingRect[2] - boundingRect[0];
    final double height = boundingRect[3] - boundingRect[1];

    if (width < minSize || height < minSize) continue;

    // Step 6: Convert coordinates from feature map to original image coordinates
    final List<List<double>> normalizedPolygon = unclippedPolygon.map((point) {
      // Map from feature map coordinates to preprocessed image coordinates
      final double preprocessedX = point[0] * 4.0;
      final double preprocessedY = point[1] * 4.0;

      // Map from preprocessed image coordinates to original image coordinates
      final double scaleX = originalImageSize.width / preprocessedSize.width;
      final double scaleY = originalImageSize.height / preprocessedSize.height;

      final double originalX = preprocessedX * scaleX;
      final double originalY = preprocessedY * scaleY;

      // Normalize to [0, 1] range
      return [
        originalX / originalImageSize.width,
        originalY / originalImageSize.height,
      ];
    }).toList();

    textBoxes.add(TextBox(
      polygon: normalizedPolygon,
      score: score,
      featureMapWidth: featureMapWidth,
      featureMapHeight: featureMapHeight,
    ));
  }

  // Sort boxes from top to bottom, left to right
  textBoxes.sort((a, b) {
    final aRect = a.getBoundingRect();
    final bRect = b.getBoundingRect();

    // First sort by top coordinate (y)
    final int yComparison = aRect[1].compareTo(bRect[1]);
    if (yComparison != 0) return yComparison;

    // Then by left coordinate (x)
    return aRect[0].compareTo(bRect[0]);
  });

  return textBoxes;
}

/// Simple contour detection using connected components
List<List<List<int>>> _findContours(List<List<bool>> binaryMap) {
  final int height = binaryMap.length;
  final int width = binaryMap[0].length;

  // Visited map to track processed pixels
  final List<List<bool>> visited = List.generate(
    height,
    (_) => List.filled(width, false),
  );

  final List<List<List<int>>> contours = [];

  // 8-connectivity directions (including diagonals)
  final List<List<int>> directions = [
    [-1, -1], [-1, 0], [-1, 1],
    [0, -1],           [0, 1],
    [1, -1],  [1, 0],  [1, 1],
  ];

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      if (binaryMap[y][x] && !visited[y][x]) {
        // Found a new component, trace its boundary
        final List<List<int>> contour = [];
        final List<List<int>> stack = [[y, x]];
        visited[y][x] = true;

        while (stack.isNotEmpty) {
          final List<int> current = stack.removeLast();
          final int cy = current[0];
          final int cx = current[1];

          contour.add([cx, cy]); // Store as [x, y]

          // Check all 8 neighbors
          for (final dir in directions) {
            final int ny = cy + dir[0];
            final int nx = cx + dir[1];

            if (ny >= 0 && ny < height && nx >= 0 && nx < width &&
                binaryMap[ny][nx] && !visited[ny][nx]) {
              visited[ny][nx] = true;
              stack.add([ny, nx]);
            }
          }
        }

        if (contour.length >= 4) {
          // Simplify contour to approximate polygon
          final List<List<int>> simplifiedContour = _simplifyContour(contour);
          contours.add(simplifiedContour);
        }
      }
    }
  }

  return contours;
}

/// Simplifies a contour to an approximate polygon (simplified version)
List<List<int>> _simplifyContour(List<List<int>> contour) {
  if (contour.length <= 4) return contour;

  // Find extreme points (min/max x and y)
  List<int> minX = contour[0];
  List<int> maxX = contour[0];
  List<int> minY = contour[0];
  List<int> maxY = contour[0];

  for (final point in contour) {
    if (point[0] < minX[0]) minX = point;
    if (point[0] > maxX[0]) maxX = point;
    if (point[1] < minY[1]) minY = point;
    if (point[1] > maxY[1]) maxY = point;
  }

  // Return a simplified quadrilateral
  return [minX, minY, maxX, maxY];
}

/// Calculates the area of a contour using the shoelace formula
double _calculateContourArea(List<List<int>> contour) {
  if (contour.length < 3) return 0.0;

  double area = 0.0;
  final int n = contour.length;

  for (int i = 0; i < n; i++) {
    final int j = (i + 1) % n;
    area += contour[i][0] * contour[j][1];
    area -= contour[j][0] * contour[i][1];
  }

  return (area / 2.0).abs();
}

/// Calculates the perimeter of a contour
double _calculateContourPerimeter(List<List<int>> contour) {
  if (contour.length < 2) return 0.0;

  double perimeter = 0.0;
  final int n = contour.length;

  for (int i = 0; i < n; i++) {
    final int j = (i + 1) % n;
    final double dx = (contour[j][0] - contour[i][0]).toDouble();
    final double dy = (contour[j][1] - contour[i][1]).toDouble();
    perimeter += math.sqrt(dx * dx + dy * dy);
  }

  return perimeter;
}

/// Calculates the average score (confidence) for pixels within a contour
double _calculateContourScore(
  Float32List output,
  List<List<int>> contour,
  int featureMapWidth,
) {
  if (contour.isEmpty) return 0.0;

  double totalScore = 0.0;
  int pixelCount = 0;

  // Average the scores of all pixels in the contour
  for (final point in contour) {
    final int x = point[0];
    final int y = point[1];
    final int index = y * featureMapWidth + x;

    if (index >= 0 && index < output.length) {
      totalScore += output[index];
      pixelCount++;
    }
  }

  return pixelCount > 0 ? totalScore / pixelCount : 0.0;
}

/// Expands a polygon by a given distance using offset polygons
List<List<double>> _expandPolygon(List<List<int>> polygon, double distance) {
  if (polygon.length < 3) {
    return polygon.map((p) => [p[0].toDouble(), p[1].toDouble()]).toList();
  }

  final List<List<double>> expandedPolygon = [];
  final int n = polygon.length;

  for (int i = 0; i < n; i++) {
    final int prev = (i - 1 + n) % n;
    final int curr = i;
    final int next = (i + 1) % n;

    // Calculate normal vectors for the two adjacent edges
    final double dx1 = (polygon[curr][0] - polygon[prev][0]).toDouble();
    final double dy1 = (polygon[curr][1] - polygon[prev][1]).toDouble();
    final double len1 = math.sqrt(dx1 * dx1 + dy1 * dy1);

    final double dx2 = (polygon[next][0] - polygon[curr][0]).toDouble();
    final double dy2 = (polygon[next][1] - polygon[curr][1]).toDouble();
    final double len2 = math.sqrt(dx2 * dx2 + dy2 * dy2);

    if (len1 == 0 || len2 == 0) {
      expandedPolygon.add([polygon[curr][0].toDouble(), polygon[curr][1].toDouble()]);
      continue;
    }

    // Normalize the vectors
    final double nx1 = -dy1 / len1; // Normal to first edge
    final double ny1 = dx1 / len1;

    final double nx2 = -dy2 / len2; // Normal to second edge
    final double ny2 = dx2 / len2;

    // Average the normals to get the offset direction
    double nx = (nx1 + nx2) / 2.0;
    double ny = (ny1 + ny2) / 2.0;
    final double nlen = math.sqrt(nx * nx + ny * ny);

    if (nlen > 0) {
      nx /= nlen;
      ny /= nlen;
    }

    // Calculate the expanded point
    final double expandedX = polygon[curr][0] + nx * distance;
    final double expandedY = polygon[curr][1] + ny * distance;

    expandedPolygon.add([expandedX, expandedY]);
  }

  return expandedPolygon;
}

/// Gets the bounding rectangle of a polygon
/// Returns [minX, minY, maxX, maxY]
List<double> _getBoundingRect(List<List<double>> polygon) {
  if (polygon.isEmpty) return [0, 0, 0, 0];

  double minX = polygon[0][0];
  double minY = polygon[0][1];
  double maxX = polygon[0][0];
  double maxY = polygon[0][1];

  for (final point in polygon) {
    minX = minX < point[0] ? minX : point[0];
    minY = minY < point[1] ? minY : point[1];
    maxX = maxX > point[0] ? maxX : point[0];
    maxY = maxY > point[1] ? maxY : point[1];
  }

  return [minX, minY, maxX, maxY];
}
```

### 11. CTC Decoding for Text Recognition
**File**: `lib/utils/image_ml_util.dart` (or could be in separate postprocessing file)

```dart
/// Decodes CTC output to text strings.
/// Takes model output [N, 80, 97] and character dictionary.
/// Returns list of decoded text strings.
List<String> ctcDecode(
  Float32List output,
  List<String> characterDict, {
  int batchSize = 1,
  int sequenceLength = 80,
  int vocabSize = 97,
}) {
  final List<String> results = [];

  for (int batchIndex = 0; batchIndex < batchSize; batchIndex++) {
    String decodedText = "";
    int previousIndex = -1;

    // For each time step in the sequence
    for (int timeStep = 0; timeStep < sequenceLength; timeStep++) {
      // Find character with highest probability
      int maxIndex = 0;
      double maxProb = output[batchIndex * sequenceLength * vocabSize +
                             timeStep * vocabSize + 0];

      for (int charIndex = 1; charIndex < vocabSize; charIndex++) {
        final double currentProb = output[batchIndex * sequenceLength * vocabSize +
                                         timeStep * vocabSize + charIndex];
        if (currentProb > maxProb) {
          maxProb = currentProb;
          maxIndex = charIndex;
        }
      }

      // Apply CTC decoding rules
      if (maxIndex > 0 && maxIndex != previousIndex) {
        // maxIndex 0 is blank token, skip it
        // Also skip repeated characters (CTC rule)
        if (maxIndex - 1 < characterDict.length) {
          decodedText += characterDict[maxIndex - 1];
        }
      }
      previousIndex = maxIndex;
    }

    results.add(decodedText.trim());
  }

  return results;
}
```

### 12. Image Cropping for Text Regions
**File**: `lib/services/machine_learning/ocr/ocr_image_utils.dart`

```dart
Future<List<Uint8List>> cropTextRegions(
  Uint8List imageBytes,
  List<TextBox> textBoxes,
  Dimensions imageDim,
) async {
  final image = await decodeImageFromData(imageBytes);
  final croppedRegions = <Uint8List>[];

  for (final box in textBoxes) {
    // Get bounding rectangle from polygon points
    final minX = box.points.map((p) => p.x).reduce(math.min);
    final maxX = box.points.map((p) => p.x).reduce(math.max);
    final minY = box.points.map((p) => p.y).reduce(math.min);
    final maxY = box.points.map((p) => p.y).reduce(math.max);

    // Calculate crop dimensions with padding
    final padding = 2.0;
    final x = math.max(0, minX - padding);
    final y = math.max(0, minY - padding);
    final width = math.min(imageDim.width - x, maxX - minX + 2 * padding);
    final height = math.min(imageDim.height - y, maxY - minY + 2 * padding);

    // Crop using canvas (similar to existing _cropImage function)
    final recorder = PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width, height),
    );

    // Handle rotated text boxes using transform
    if (isRotatedBox(box)) {
      // Calculate rotation angle from box points
      final angle = calculateRotationAngle(box.points);
      canvas.save();
      canvas.translate(width / 2, height / 2);
      canvas.rotate(-angle);
      canvas.translate(-width / 2, -height / 2);
    }

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(x, y, width, height),
      Rect.fromLTWH(0, 0, width, height),
      Paint()..filterQuality = FilterQuality.high,
    );

    if (isRotatedBox(box)) {
      canvas.restore();
    }

    final picture = recorder.endRecording();
    final croppedImage = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await croppedImage.toByteData(format: ImageByteFormat.png);
    croppedRegions.add(byteData!.buffer.asUint8List());
  }

  return croppedRegions;
}
```

The extensive planning documents and mature infrastructure make this a well-scoped, achievable feature addition. These preprocessing and postprocessing functions follow the existing patterns in the codebase while implementing the exact specifications for the RapidOCR models.