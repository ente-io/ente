/**
 * [Note: Custom errors across Electron/Renderer boundary]
 *
 * We need to use the `message` field to disambiguate between errors thrown by
 * the main process when invoked from the renderer process. This is because:
 *
 * > Errors thrown throw `handle` in the main process are not transparent as
 * > they are serialized and only the `message` property from the original error
 * > is provided to the renderer process.
 * >
 * > - https://www.electronjs.org/docs/latest/tutorial/ipc
 * >
 * > Ref: https://github.com/electron/electron/issues/24427
 */
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
