use resize::{px::RGB, Pixel::RGB8, Type::Lanczos3};
use rgb::FromSlice;

pub fn process_yolo_face(image_path: &str) -> (Vec<u8>, String) {
    let mut timing = String::new();
    let start = std::time::Instant::now();

    // Load the image
    let img = image::open(image_path).expect("Failed to open image");
    let load_time = start.elapsed().as_millis();
    timing.push_str(&format!("Load time: {}ms\n", load_time));

    // Get dimensions
    let (width, height) = (img.width() as usize, img.height() as usize);
    let (new_width, new_height) = (640, 640);
    let dimensions_time = start.elapsed().as_millis() - load_time;
    timing.push_str(&format!("Dimensions time: {}ms\n", dimensions_time));

    // Convert image to RGB8
    let rgb_img = img.to_rgb8();
    let convert_time = start.elapsed().as_millis() - dimensions_time;
    timing.push_str(&format!("Convert time: {}ms\n", convert_time));
    let rgb_vec = rgb_img.to_vec();
    let rgb_vec_time = start.elapsed().as_millis() - convert_time;
    timing.push_str(&format!("RGB Vec time: {}ms\n", rgb_vec_time));

    // Create resizer
    let mut resizer = resize::new(width, height, new_width, new_height, RGB8, Lanczos3).unwrap();

    // Create buffer for resized image
    let mut dst = vec![RGB::new(0, 0, 0); new_width * new_height];
    let buffer_time = start.elapsed().as_millis() - rgb_vec_time;
    timing.push_str(&format!("Buffer time: {}ms\n", buffer_time));

    // Create ImageBuffer from resized data
    resizer.resize(rgb_vec.as_rgb(), &mut dst).unwrap();
    let resize_time = start.elapsed().as_millis() - buffer_time;
    timing.push_str(&format!("Resize time: {}ms\n", resize_time));

    // Return dst as a Vec<u8>
    let mut result = Vec::new();
    for pixel in dst {
        result.push(pixel.r);
        result.push(pixel.g);
        result.push(pixel.b);
    }
    let result_time = start.elapsed().as_millis() - resize_time;
    timing.push_str(&format!("Result time: {}ms\n", result_time));
    (result, timing)
}
