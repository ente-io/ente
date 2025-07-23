use image::ImageBuffer;
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
    // Load the image from the path (~200ms)
    let img: image::DynamicImage = image::open(image_path).expect("Failed to open image");

    // Process the image
    let results = process_image_ml(img);

    results
}

pub fn process_image_ml_from_data(
    rgba_data: Vec<u8>,
    width: u32,
    height: u32,
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
    // Load the image from the data
    let img = image::DynamicImage::from(
        ImageBuffer::<image::Rgb<u8>, _>::from_raw(width, height, rgba_data)
            .expect("Failed to create image buffer"),
    );

    // Process the image
    let results = process_image_ml(img);

    results
}

fn process_image_ml(
    img: image::DynamicImage,
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
