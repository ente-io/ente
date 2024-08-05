import type { Metadata } from "./file-metadata";

export const hasFileHash = (file: Metadata) =>
    !!file.hash || (!!file.imageHash && !!file.videoHash);
