---
title: Detect Text (OCR)
description: Copy text from your photos on iOS and Android using on-device OCR in Ente Photos
---

# Detect Text (OCR)

Detect Text lets you pull text out of your photos without leaving Ente Photos. Recognition runs entirely on your device, so your images and the text you extract never leave your phone.

## Availability

- **Platforms**: iOS and Android mobile apps
- **Supported files**: Photos and Live Photos (videos are not supported)
- **Viewer contexts**: Available in the standard photo viewer; the button is hidden for Trash items, guest views, and photos without detectable text

> **Note**: On Android, the first scan downloads the OCR models. Keep a network connection for that download. Later scans work offline.

## Use Detect Text

**On mobile:**

1. Open a photo in the viewer.
2. Look for the **Detect Text** button near the share button. Ente only shows it when it finds text in the image.
3. Tap **Detect Text**.
4. Let the detection overlay finish scanning.
5. Drag the selection handles or double tap to highlight exactly what you need.
6. Tap **Copy** to copy the selection, or tap **Select all** to copy the full text.
7. Tap the back arrow to return to the photo viewer.

After copying, the text stays on your clipboard so you can paste it into messages, notes, or other apps.

## Tips

- Ente caches detection results, so revisiting the same photo makes the button appear immediately.
- If the button never appears, verify that the photo contains readable text and that the original file has finished downloading.
- When no text is found, the overlay shows **No text detected**. Close it to return to the photo.

## Limitations

Detect Text runs on demand and does not build a searchable index across your library, so searches still rely on metadata, machine learning tags, and descriptions. Magic search may occasionally surface photos with prominent text (thanks to CLIP embeddings), but it is not a dedicated "search by detected text" feature.

Not all languages are currently supported. It works well on Chinese, Japanese, English, and most languages with the Latin scripture.  

## Privacy

OCR processing happens completely on-device (Vision on iOS, offline models on Android). Ente never sees your images, detected text, or selections.

## Related topics

- [Search and Discovery overview](/photos/features/search-and-discovery/)
- [Machine learning overview](/photos/features/search-and-discovery/machine-learning)
