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

1. Download OCR models using the provided script
2. Create **separate ML model services** for each OCR model (detection, classification, recognition)
3. Create main `OCRService` that orchestrates the three model services
4. Add simple OCR option to photo viewer app bar
5. Add feature flag for gradual rollout
6. Test with internal users first

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
class TextDetectionService extends MlModel {
  static const _modelName = 'text_detection_rapidOCR_v1.onnx';

  @override
  String get modelRemotePath => _modelName;

  @override
  Future<int> loadModel([int sessionIndex = 0]) async {
    final (name, path) = await getModelNameAndPath();
    return MlModel.loadModel(name, path, sessionIndex);
  }

  Future<List<TextBox>> detectText(Uint8List imageData) async {
    // Preprocess: resize to multiple of 32, normalize
    final input = _preprocessImage(imageData);

    // Run inference
    final output = await runModel(input);

    // Postprocess: threshold, find contours, unclip
    return _postprocessDetection(output);
  }
}
```

### 3. Text Classification Model Service
**File**: `lib/services/machine_learning/ocr/text_classification_service.dart`
```dart
class TextClassificationService extends MlModel {
  static const _modelName = 'text_classifier_rapidOCR_v1.onnx';

  Future<List<bool>> classifyOrientation(List<Uint8List> textRegions) async {
    // Batch process up to 6 regions
    final input = _preprocessBatch(textRegions, targetSize: Size(192, 48));
    final output = await runModel(input);

    // Return true if needs 180° rotation
    return output.map((probs) => probs[1] > probs[0] && probs[1] > 0.9).toList();
  }
}
```

### 4. Text Recognition Model Service
**File**: `lib/services/machine_learning/ocr/text_recognition_service.dart`
```dart
class TextRecognitionService extends MlModel {
  static const _modelName = 'text_recognition_rapidOCR_v1.onnx';
  late List<String> _characterDict;

  Future<void> initialize() async {
    await super.initialize();
    _characterDict = await _loadDictionary('en_dict_rapidOCR_v1.txt');
  }

  Future<List<String>> recognizeText(List<Uint8List> orientedRegions) async {
    final input = _preprocessBatch(orientedRegions, targetSize: Size(320, 48));
    final output = await runModel(input);  // [N, 80, 97]

    // CTC decode
    return _ctcDecode(output, _characterDict);
  }

  List<String> _ctcDecode(Float32List output, List<String> dict) {
    // Implement CTC decoding as per spec
    // Skip blanks and repeated characters
  }
}
```

### 5. Main OCR Service
**File**: `lib/services/machine_learning/ocr/ocr_service.dart`
```dart
class OCRService {
  static final OCRService _instance = OCRService._internal();
  static OCRService get instance => _instance;

  final _detection = TextDetectionService();
  final _classification = TextClassificationService();
  final _recognition = TextRecognitionService();
  bool _isInitialized = false;

  Future<String> extractText(Uint8List imageBytes) async {
    try {
      // Lazy load models on first use
      if (!_isInitialized) {
        await _initializeModels();
        _isInitialized = true;
      }

      // Step 1: Detect text regions
      final textBoxes = await _detection.detectText(imageBytes);
      if (textBoxes.isEmpty) return '';

      // Step 2: Crop regions from image
      final textRegions = _cropTextRegions(imageBytes, textBoxes);

      // Step 3: Classify orientation
      final needsRotation = await _classification.classifyOrientation(textRegions);
      final orientedRegions = _applyRotations(textRegions, needsRotation);

      // Step 4: Recognize text
      final texts = await _recognition.recognizeText(orientedRegions);

      return texts.join('\n');
    } finally {
      // Unload models after use to save memory
      await _unloadModels();
      _isInitialized = false;
    }
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

The extensive planning documents and mature infrastructure make this a well-scoped, achievable feature addition.