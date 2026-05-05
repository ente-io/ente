#[derive(Clone, Debug, PartialEq)]
pub struct Dimensions {
    pub width: u32,
    pub height: u32,
}

#[derive(Clone, Debug)]
pub struct DecodedImage {
    pub dimensions: Dimensions,
    pub rgb: Vec<u8>,
}
