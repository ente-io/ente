# Ente Cast for tvOS

Source code for the Ente Cast tvOS app.

## Building from source

1. Install [Xcode](https://developer.apple.com/xcode/) and [Rust](https://www.rust-lang.org/tools/install). In Xcode install the tvOS platform.

2. Open `tv.xcodeproj` in Xcode and run the `cast` scheme.

> [!NOTE]
>
> The first build will install the Rust `nightly` toolchain and `rust-src`. They are needed for building Rust for tvOS targets.
