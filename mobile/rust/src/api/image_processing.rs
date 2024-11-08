use image::ImageBuffer;
use libheif_rs::{ColorSpace, HeifContext, LibHeif, RgbChroma};
use resize::{px::RGB, Pixel::RGB8, Type::Lanczos3, Type::Mitchell};
use rgb::FromSlice;

pub fn process_image_ml_from_path(
    image_path: &str,
) -> (
    Vec<u8>,
    usize,
    usize,
    Vec<u8>,
    usize,
    usize,
    Vec<u8>,
    usize,
    usize,
) {
    // Check the image format by checking the file extension in the image_path string (~0ms)
    let format = image_path.split('.').last().unwrap().to_lowercase();

    let img = if format == "heic" || format == "heif" {
        let lib_heif = LibHeif::new();
        let ctx = HeifContext::read_from_file(image_path).expect("Failed to read HEIF file");
        let handle = ctx
            .primary_image_handle()
            .expect("Failed to get primary image handle");
        let decoded = lib_heif
            .decode(&handle, ColorSpace::Rgb(RgbChroma::Rgb), None)
            .expect("Failed to decode image");
        let plane = decoded
            .planes()
            .interleaved
            .expect("Failed to get interleaved plane");
        let rgb_data = plane.data.to_vec();
        let img = image::DynamicImage::from(
            ImageBuffer::<image::Rgb<u8>, _>::from_raw(decoded.width(), decoded.height(), rgb_data)
                .expect("Failed to create image buffer"),
        );
        img
    } else {
        let img = image::open(image_path).expect("Failed to open image");
        img
    };

    // Load the image (~200ms)
    // let img = image::open(image_path).expect("Failed to open image");

    // Get dimensions for resized images (0ms)
    let (width, height) = (img.width() as usize, img.height() as usize);
    let scale_face = f32::min(640.0 / width as f32, 640.0 / height as f32);
    let scale_clip = f32::max(256.0 / width as f32, 256.0 / height as f32);
    let (new_width_face, new_height_face) = (
        f32::round(width as f32 * scale_face) as usize,
        f32::round(height as f32 * scale_face) as usize,
    );
    let (new_width_clip, new_height_clip) = (
        f32::round(width as f32 * scale_clip) as usize,
        f32::round(height as f32 * scale_clip) as usize,
    );
    let mut interpolation_face = Lanczos3;
    if scale_face > 1.0 {
        interpolation_face = Mitchell;
    }
    let mut interpolation_clip = Lanczos3;
    if scale_clip > 1.0 {
        interpolation_clip = Mitchell;
    }

    // Convert image to RGB8 (~150ms)
    let rgba_decoded = img.to_rgba8().to_vec();
    let rgb_img = img.into_rgb8();

    // Convert RGB8 to Vec<RGB> (~30ms)
    let rgb_vec = rgb_img.to_vec();

    // Create resizer (~20ms)
    let mut resizer_face = resize::new(
        width,
        height,
        new_width_face,
        new_height_face,
        RGB8,
        interpolation_face,
    )
    .unwrap();
    let mut resizer_clip = resize::new(
        width,
        height,
        new_width_clip,
        new_height_clip,
        RGB8,
        interpolation_clip,
    )
    .unwrap();

    // Create buffer for resized image (~120ms)
    let mut dst_face = vec![RGB::new(0, 0, 0); new_width_face * new_height_face];
    let mut dst_clip = vec![RGB::new(0, 0, 0); new_width_clip * new_height_clip];

    // Resize the image (~120ms)
    resizer_face
        .resize(rgb_vec.as_rgb(), &mut dst_face)
        .unwrap();
    resizer_clip
        .resize(rgb_vec.as_rgb(), &mut dst_clip)
        .unwrap();

    // Return resized images as Vec<u8> (~120ms)
    let mut result_face = Vec::with_capacity(new_width_face * new_height_face * 3);
    for pixel in dst_face {
        result_face.push(pixel.r);
        result_face.push(pixel.g);
        result_face.push(pixel.b);
    }
    let mut result_clip = Vec::with_capacity(new_width_clip * new_height_clip * 3);
    for pixel in dst_clip {
        result_clip.push(pixel.r);
        result_clip.push(pixel.g);
        result_clip.push(pixel.b);
    }
    (
        rgba_decoded,
        height,
        width,
        result_face,
        new_height_face,
        new_width_face,
        result_clip,
        new_height_clip,
        new_width_clip,
    )
}

pub fn process_yolo_face(image_path: &str) -> (Vec<u8>, String, usize, usize) {
    let mut timing = String::new();
    timing.push_str("Yolo Face\n");
    let start = std::time::Instant::now();

    // Load the image (~200ms)
    let img = image::open(image_path).expect("Failed to open image");
    let load_time = start.elapsed().as_millis();
    timing.push_str(&format!("Load time: {}ms\n", load_time));

    // Get dimensions (0ms)
    let (width, height) = (img.width() as usize, img.height() as usize);
    let scale = f32::min(640.0 / width as f32, 640.0 / height as f32);
    let (new_width, new_height) = (
        f32::round(width as f32 * scale) as usize,
        f32::round(height as f32 * scale) as usize,
    );
    let mut interpolation = Lanczos3;
    if scale > 1.0 {
        interpolation = Mitchell;
    }

    // Convert image to RGB8 (~150ms)
    let rgb_img = img.into_rgb8();
    let convert_time = start.elapsed().as_millis() - load_time;
    timing.push_str(&format!("Convert time: {}ms\n", convert_time));

    // Convert RGB8 to Vec<RGB> (~30ms)
    // let rgb_vec = rgb_img.to_vec();
    let mut rgb_vec = Vec::with_capacity(width * height * 3);
    rgb_vec.extend_from_slice(rgb_img.as_raw());
    let rgb_vec_time = start.elapsed().as_millis() - convert_time;
    timing.push_str(&format!("RGB Vec time: {}ms\n", rgb_vec_time));

    // Create resizer (~20ms)
    let mut resizer =
        resize::new(width, height, new_width, new_height, RGB8, interpolation).unwrap();
    let resizer_time = start.elapsed().as_millis() - rgb_vec_time;
    timing.push_str(&format!("Resizer time: {}ms\n", resizer_time));

    // Create buffer for resized image (~120ms)
    let mut dst = vec![RGB::new(0, 0, 0); new_width * new_height];
    let buffer_time = start.elapsed().as_millis() - resizer_time;
    timing.push_str(&format!("Buffer time: {}ms\n", buffer_time));

    // Create ImageBuffer from resized data (~120ms)
    resizer.resize(rgb_vec.as_rgb(), &mut dst).unwrap();
    let resize_time = start.elapsed().as_millis() - buffer_time;
    timing.push_str(&format!("Resize time: {}ms\n", resize_time));

    // Return dst as a Vec<u8> (~120ms)
    let mut result = Vec::with_capacity(new_width * new_height * 3);
    for pixel in dst {
        result.push(pixel.r);
        result.push(pixel.g);
        result.push(pixel.b);
    }
    let result_time = start.elapsed().as_millis() - resize_time;
    timing.push_str(&format!("Result time: {}ms\n", result_time));
    (result, timing, new_width, new_height)
}

pub fn process_clip(image_path: &str) -> (Vec<u8>, String, usize, usize) {
    let mut timing = String::new();
    timing.push_str("Clip \n");
    let start = std::time::Instant::now();

    // Load the image (~200ms)
    let img = image::open(image_path).expect("Failed to open image");
    let load_time = start.elapsed().as_millis();
    timing.push_str(&format!("Load time: {}ms\n", load_time));

    // Get dimensions (0ms)
    let (width, height) = (img.width() as usize, img.height() as usize);
    let scale = f32::max(256.0 / width as f32, 256.0 / height as f32);
    let (new_width, new_height) = (
        f32::round(width as f32 * scale) as usize,
        f32::round(height as f32 * scale) as usize,
    );
    let mut interpolation = Lanczos3;
    if scale > 1.0 {
        interpolation = Mitchell;
    }

    // Convert image to RGB8 (~150ms)
    let rgb_img = img.into_rgb8();
    let convert_time = start.elapsed().as_millis() - load_time;
    timing.push_str(&format!("Convert time: {}ms\n", convert_time));

    // Convert RGB8 to Vec<RGB> (~30ms)
    // let rgb_vec = rgb_img.to_vec();
    let mut rgb_vec = Vec::with_capacity(width * height * 3);
    rgb_vec.extend_from_slice(rgb_img.as_raw());
    let rgb_vec_time = start.elapsed().as_millis() - convert_time;
    timing.push_str(&format!("RGB Vec time: {}ms\n", rgb_vec_time));

    // Create resizer (~20ms)
    let mut resizer =
        resize::new(width, height, new_width, new_height, RGB8, interpolation).unwrap();
    let resizer_time = start.elapsed().as_millis() - rgb_vec_time;
    timing.push_str(&format!("Resizer time: {}ms\n", resizer_time));

    // Create buffer for resized image (~120ms)
    let mut dst = vec![RGB::new(0, 0, 0); new_width * new_height];
    let buffer_time = start.elapsed().as_millis() - resizer_time;
    timing.push_str(&format!("Buffer time: {}ms\n", buffer_time));

    // Create ImageBuffer from resized data (~120ms)
    resizer.resize(rgb_vec.as_rgb(), &mut dst).unwrap();
    let resize_time = start.elapsed().as_millis() - buffer_time;
    timing.push_str(&format!("Resize time: {}ms\n", resize_time));

    // Return dst as a Vec<u8> (~120ms)
    let mut result = Vec::with_capacity(new_width * new_height * 3);
    for pixel in dst {
        result.push(pixel.r);
        result.push(pixel.g);
        result.push(pixel.b);
    }
    let result_time = start.elapsed().as_millis() - resize_time;
    timing.push_str(&format!("Result time: {}ms\n", result_time));
    (result, timing, new_width, new_height)
}
