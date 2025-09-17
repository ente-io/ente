# OCR MVP Implementation Spec for Ente Photos

## Overview

Implement minimal on-the-fly OCR functionality for extracting text from images in the Ente Photos app.

## Scope

- **In Scope**: Single-image text extraction with manual trigger
- **Out of Scope**: Using isolate (add in future), Background indexing, batch processing, search integration

## User Flow

1. User opens image in photo viewer
2. Taps OCR button in toolbar
3. Loading indicator shows during processing
4. Text appears in dialog with copy button
5. User copies/dismisses dialog

## Technical Architecture

### Models & Pipeline

See [`OCR_MODELS_SPECIFICATION.md`](./OCR_MODELS_SPECIFICATION.md) for detailed specifications.

**Pipeline**: Detection → Classification → Recognition

- Text Detection: `text_detection_rapidOCR_v1.onnx` (4.2MB)
- Orientation Classifier: `text_classifier_rapidOCR_v1.onnx` (1.4MB)
- Text Recognition: `text_recognition_rapidOCR_v1.onnx` (10MB)
- Dictionary: `en_dict_rapidOCR_v1.txt`

### Implementation Components

#### 1. OCR Service (`lib/services/machine_learning/ocr_service.dart`)

- Singleton service for OCR operations
- Lazy model loading (on-demand)
- Model cleanup after use
- Leverages existing ONNX infrastructure
- Don't put inside isolate for now, we'll do that later

#### 2. UI Integration

- **Photo Viewer**: Add OCR button to `gallery_overlay_widget.dart`
- **Result Dialog**: New `ocr_result_dialog.dart` component
- **Design**: Use Ente theme system (no hardcoded colors)

#### 3. Model Management

- Download from `https://models.ente.io/[model_name]`
- Cache in app's internal storage using existing asset manager
- Total size: ~16MB for all models

## Feature Flag

```dart
// In plugins/ente_feature_flag/lib/src/service.dart
bool get ocrEnabled => internalUser;
```

## Performance Constraints

- Max image size: existing `maxFileDownloadSize` limit
- Min text height: 10px for detection
- Memory: Unload models after use

## Error Handling

- No text found → Show toast message
- Model load failure → Fallback message
- Processing timeout → 10 seconds max

## Testing Requirements

- [ ] Various image sizes
- [ ] Multiple text regions
- [ ] Low contrast images
- [ ] Memory usage on low-end devices
- [ ] English text only (MVP)

## Success Metrics

- Processing time < 2 seconds for typical locally-available image
- High accuracy on clear printed/typed text

## Future Enhancements (Post-MVP)

- Running it inside isolate to prevent jank
- Additional language support
- Indexing and search integration
- Handwriting recognition

## Dependencies

- ONNX Runtime (existing)
- Image processing utils (existing)
- No new package dependencies
