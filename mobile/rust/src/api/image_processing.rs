use resize::{px::RGB, Pixel::RGB8, Type::Lanczos3, Type::Mitchell};
use rgb::FromSlice;

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
