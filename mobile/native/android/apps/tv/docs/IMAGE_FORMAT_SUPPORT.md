# Image format support

This project uses a layered decode pipeline to maximize compatibility across local files and Ente images.

## Detection

`ImageFormatClassifier` is the central source of truth for:
- supported photo extensions,
- RAW extensions,
- MIME sniffing from file headers,
- format family classification (JPEG/PNG/APNG/GIF/WEBP/AVIF/JXL/RAW/etc).

## Slideshow load order

`SlideshowView.showNext()` dispatches by detected family:

1. **APNG / AVIF / animated WebP**
   - Special drawable path (`APNGDrawable`, `AVIFDrawable`, `WebPDrawable`)
   - Then Coil
   - Then Glide
   - Then Picasso

2. **JXL**
   - Direct JXL decode (`JxlAnimatedImage` / `JxlCoder`)
   - Then Coil
   - Then Glide
   - Then Picasso

3. **RAW**
   - Glide
   - Then Coil

4. **Other images**
   - Coil
   - Then special drawable pass
   - Then Glide
   - Then Picasso

## Ente-specific behavior

`EnteUriFetcher`:
- preserves original bytes for formats that should not be force-transcoded,
- avoids marking likely image formats as unsupported,
- sniffs MIME when needed,
- serves stale cache on failures where possible.

## Validation matrix (manual)

Use debug assets and/or sample albums to validate these extensions:

- jpg, jpeg, png, bmp, webp
- gif, svg
- apng, avif, jxl
- heic, heif
- dng, orf, nef, arw, rw2, cr2, cr3

For each sample, verify:
- image renders,
- slideshow transition succeeds,
- no repeated load-failure loop in diagnostics.
