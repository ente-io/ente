export const CustomErrors = {
    WINDOWS_NATIVE_IMAGE_PROCESSING_NOT_SUPPORTED:
        "Windows native image processing is not supported",
    INVALID_OS: (os: string) => `Invalid OS - ${os}`,
    WAIT_TIME_EXCEEDED: "Wait time exceeded",
    UNSUPPORTED_PLATFORM: (platform: string, arch: string) =>
        `Unsupported platform - ${platform} ${arch}`,
    MODEL_DOWNLOAD_PENDING:
        "Model download pending, skipping clip search request",
    INVALID_FILE_PATH: "Invalid file path",
    INVALID_CLIP_MODEL: (model: string) => `Invalid Clip model - ${model}`,
};
