use resize::{px::RGB, Pixel::RGB8, Type::Lanczos3};
use rgb::FromSlice;

pub fn process_yolo_face(image_path: &str) -> Vec<u8> {
    // Load the image
    let img = image::open(image_path).expect("Failed to open image");

    // Get dimensions
    let (width, height) = (img.width() as usize, img.height() as usize);
    let (new_width, new_height) = (640, 640);

    // Convert image to RGB8
    let rgb_img = img.to_rgb8();
    let rgb_vec = rgb_img.to_vec();

    // Create resizer
    let mut resizer = resize::new(width, height, new_width, new_height, RGB8, Lanczos3).unwrap();

    // Create buffer for resized image
    let mut dst = vec![RGB::new(0, 0, 0); new_width * new_height];

    // Create ImageBuffer from resized data
    resizer.resize(rgb_vec.as_rgb(), &mut dst).unwrap();

    // Return dst as a Vec<u8>
    let mut result = Vec::new();
    for pixel in dst {
        result.push(pixel.r);
        result.push(pixel.g);
        result.push(pixel.b);
    }
    result
}
