import type { Metadata } from "./types/file";

export const hasFileHash = (file: Metadata) =>
    !!file.hash || (!!file.imageHash && !!file.videoHash);
