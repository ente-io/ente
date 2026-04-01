import { Box, CircularProgress, Typography } from "@mui/material";
import log from "ente-base/log";
import {
    downloadManager,
    type RenderableSourceURLs,
} from "ente-gallery/services/download";
import type { HLSPlaylistData } from "ente-gallery/services/video";
import type { EnteFile } from "ente-media/file";
import type { PublicMemoryShareFrameCrop } from "ente-new/albums/services/public-memory";
import "hls-video-element";
import {
    type CSSProperties,
    type RefObject,
    useCallback,
    useEffect,
    useRef,
    useState,
} from "react";
import { computeMediaCropStyle } from "../utils/lane";

const DEFAULT_MEDIA_MAX_WIDTH_CSS = "min(1360px, calc(100vw - 32px))";
const DEFAULT_MEDIA_MAX_HEIGHT_CSS = "calc(100dvh - 184px)";

const buildMediaStyle = ({
    cropRect,
    cropContainerAspectRatio,
    fillFrame,
    mediaAspectRatio,
    objectFit,
}: {
    cropRect?: PublicMemoryShareFrameCrop;
    cropContainerAspectRatio?: number;
    fillFrame?: boolean;
    mediaAspectRatio?: number;
    objectFit: "contain" | "cover";
}): CSSProperties => {
    const cropStyle = computeMediaCropStyle({
        cropRect,
        mediaAspectRatio,
        containerAspectRatio: cropContainerAspectRatio,
    });

    return {
        display: "block",
        ...(cropStyle ?? {
            width: fillFrame ? "100%" : "auto",
            height: fillFrame ? "100%" : "auto",
            maxWidth: fillFrame ? "100%" : DEFAULT_MEDIA_MAX_WIDTH_CSS,
            maxHeight: fillFrame ? "100%" : DEFAULT_MEDIA_MAX_HEIGHT_CSS,
            objectFit,
        }),
        userSelect: "none",
        pointerEvents: "none",
    };
};

function MediaLoadingOverlay() {
    return (
        <Box
            sx={{
                position: "absolute",
                inset: 0,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                backgroundColor: "rgba(0, 0, 0, 0.5)",
                zIndex: 2,
            }}
        >
            <CircularProgress sx={{ color: "#08c225" }} size={32} />
        </Box>
    );
}

export interface PhotoImageProps {
    file: EnteFile;
    onFullLoad?: () => void;
    fillFrame?: boolean;
    objectFit?: "contain" | "cover";
    thumbnailOnly?: boolean;
    cropRect?: PublicMemoryShareFrameCrop;
    cropContainerAspectRatio?: number;
    mediaAspectRatio?: number;
    onAspectRatio?: (width: number, height: number) => void;
    showLoadingOverlay?: boolean;
}

export function PhotoImage({
    file,
    onFullLoad,
    fillFrame,
    objectFit = "contain",
    thumbnailOnly = false,
    cropRect,
    cropContainerAspectRatio,
    mediaAspectRatio,
    onAspectRatio,
    showLoadingOverlay = true,
}: PhotoImageProps) {
    const [thumbnailURL, setThumbnailURL] = useState<string | undefined>(
        undefined,
    );
    const [fullImageURL, setFullImageURL] = useState<string | undefined>(
        undefined,
    );
    const [isLoading, setIsLoading] = useState(true);
    const imageRef = useRef<HTMLImageElement | null>(null);
    const onFullLoadRef = useRef(onFullLoad);
    const onAspectRatioRef = useRef(onAspectRatio);
    const mediaReadyRef = useRef(false);
    const hasNotifiedDisplayReadyRef = useRef(false);

    onFullLoadRef.current = onFullLoad;
    onAspectRatioRef.current = onAspectRatio;

    const signalReady = useCallback(() => {
        mediaReadyRef.current = true;
        if (hasNotifiedDisplayReadyRef.current || !onFullLoadRef.current) {
            return;
        }
        hasNotifiedDisplayReadyRef.current = true;
        onFullLoadRef.current();
    }, []);

    useEffect(() => {
        let cancelled = false;
        setIsLoading(true);
        setThumbnailURL(undefined);
        setFullImageURL(undefined);
        mediaReadyRef.current = false;
        hasNotifiedDisplayReadyRef.current = false;

        const loadThumbnail = async () => {
            try {
                const nextThumbnailURL =
                    await downloadManager.renderableThumbnailURL(file);
                if (!cancelled && nextThumbnailURL) {
                    setThumbnailURL(nextThumbnailURL);
                } else if (!cancelled) {
                    setIsLoading(false);
                }
            } catch (error) {
                log.error("Failed to load thumbnail", error);
                if (!cancelled) {
                    setIsLoading(false);
                }
            }
        };

        const loadFullImage = async () => {
            if (thumbnailOnly) {
                return;
            }
            try {
                const sourceURLs =
                    await downloadManager.renderableSourceURLs(file);
                if (cancelled) {
                    return;
                }
                if (sourceURLs.type === "image") {
                    setFullImageURL(sourceURLs.imageURL);
                } else {
                    signalReady();
                }
            } catch (error) {
                log.error("Failed to load full image", error);
                if (!cancelled) {
                    signalReady();
                }
            }
        };

        void loadThumbnail();
        void loadFullImage();

        return () => {
            cancelled = true;
        };
    }, [file, signalReady, thumbnailOnly]);

    useEffect(() => {
        if (!onFullLoad) {
            hasNotifiedDisplayReadyRef.current = false;
            return;
        }
        if (mediaReadyRef.current && !hasNotifiedDisplayReadyRef.current) {
            hasNotifiedDisplayReadyRef.current = true;
            onFullLoad();
        }
    }, [onFullLoad]);

    useEffect(() => {
        if (thumbnailOnly || !fullImageURL) {
            return;
        }
        const image = imageRef.current;
        if (!image?.complete) {
            return;
        }
        if (image.naturalWidth > 0 && image.naturalHeight > 0) {
            onAspectRatioRef.current?.(image.naturalWidth, image.naturalHeight);
        }
    }, [fullImageURL, thumbnailOnly]);

    const displayURL = fullImageURL ?? thumbnailURL;
    const mediaStyle = buildMediaStyle({
        cropRect,
        cropContainerAspectRatio,
        fillFrame,
        mediaAspectRatio,
        objectFit,
    });

    return (
        <Box
            sx={{
                position: "relative",
                display: fillFrame ? "block" : "inline-block",
                width: fillFrame ? "100%" : "auto",
                height: fillFrame ? "100%" : "auto",
                overflow: "hidden",
            }}
        >
            {isLoading && showLoadingOverlay && <MediaLoadingOverlay />}

            {displayURL && (
                <img
                    ref={imageRef}
                    src={displayURL}
                    alt=""
                    draggable={false}
                    onLoad={(event) => {
                        const isFullImageLoad =
                            !thumbnailOnly &&
                            !!fullImageURL &&
                            event.currentTarget.src === fullImageURL;
                        if (isFullImageLoad) {
                            onAspectRatioRef.current?.(
                                event.currentTarget.naturalWidth,
                                event.currentTarget.naturalHeight,
                            );
                        }
                        setIsLoading(false);
                        if (thumbnailOnly || isFullImageLoad) {
                            signalReady();
                        }
                    }}
                    style={mediaStyle}
                />
            )}
        </Box>
    );
}

export interface VideoPlayerProps {
    file: EnteFile;
    onReady?: () => void;
    onDuration?: (durationSeconds: number) => void;
    onEnded?: () => void;
    paused?: boolean;
    mediaRef?: RefObject<HTMLVideoElement | null>;
    fillFrame?: boolean;
    objectFit?: "contain" | "cover";
    cropRect?: PublicMemoryShareFrameCrop;
    cropContainerAspectRatio?: number;
    mediaAspectRatio?: number;
    onAspectRatio?: (width: number, height: number) => void;
    showLoadingOverlay?: boolean;
}

export function VideoPlayer({
    file,
    onReady,
    onDuration,
    onEnded,
    paused,
    mediaRef,
    fillFrame,
    objectFit = "contain",
    cropRect,
    cropContainerAspectRatio,
    mediaAspectRatio,
    onAspectRatio,
    showLoadingOverlay = true,
}: VideoPlayerProps) {
    const [hlsData, setHlsData] = useState<HLSPlaylistData | undefined>(
        undefined,
    );
    const [videoURL, setVideoURL] = useState<string | undefined>(undefined);
    const [thumbnailURL, setThumbnailURL] = useState<string | undefined>(
        undefined,
    );
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState(false);
    const videoRef = useRef<HTMLVideoElement>(null);
    const onReadyRef = useRef(onReady);
    const onDurationRef = useRef(onDuration);
    const onEndedRef = useRef(onEnded);

    onReadyRef.current = onReady;
    onDurationRef.current = onDuration;
    onEndedRef.current = onEnded;

    const setVideoElementRef = useCallback(
        (node: HTMLVideoElement | null) => {
            videoRef.current = node;
            if (mediaRef) {
                mediaRef.current = node;
            }
        },
        [mediaRef],
    );

    useEffect(() => {
        let cancelled = false;
        setIsLoading(true);
        setError(false);
        setVideoURL(undefined);
        setHlsData(undefined);
        setThumbnailURL(undefined);

        const load = async () => {
            try {
                const nextThumbnailURL =
                    await downloadManager.renderableThumbnailURL(file);
                if (!cancelled && nextThumbnailURL) {
                    setThumbnailURL(nextThumbnailURL);
                }

                const nextHlsData =
                    await downloadManager.hlsPlaylistDataForPublicMemory(file);
                if (
                    !cancelled &&
                    typeof nextHlsData === "object" &&
                    nextHlsData.playlistURL
                ) {
                    setHlsData(nextHlsData);
                    return;
                }

                const sourceURLs: RenderableSourceURLs =
                    await downloadManager.renderableSourceURLs(file);
                if (!cancelled && sourceURLs.type === "video") {
                    setVideoURL(sourceURLs.videoURL);
                } else if (!cancelled) {
                    setIsLoading(false);
                }
            } catch (error) {
                log.error("Failed to load video", error);
                if (!cancelled) {
                    setError(true);
                    setIsLoading(false);
                }
            }
        };

        void load();

        return () => {
            cancelled = true;
        };
    }, [file]);

    useEffect(() => {
        const video = videoRef.current;
        if (!video || (!videoURL && !hlsData)) {
            return;
        }

        if (paused) {
            video.pause();
        } else {
            video.play().catch(() => {
                // Autoplay may be blocked; ignore.
            });
        }
    }, [hlsData, paused, videoURL]);

    const handleLoadedMetadata = useCallback(() => {
        const video = videoRef.current;
        if (video && !Number.isNaN(video.duration) && video.duration > 0) {
            onAspectRatio?.(video.videoWidth, video.videoHeight);
            onDurationRef.current?.(video.duration);
        }
    }, [onAspectRatio]);

    const handleCanPlay = useCallback(() => {
        setIsLoading(false);
        onReadyRef.current?.();
        const video = videoRef.current;
        if (video && !paused) {
            video.play().catch(() => {
                // Autoplay may be blocked.
            });
        }
    }, [paused]);

    const handleEnded = useCallback(() => {
        onEndedRef.current?.();
    }, []);

    const mediaStyle = buildMediaStyle({
        cropRect,
        cropContainerAspectRatio,
        fillFrame,
        mediaAspectRatio,
        objectFit,
    });

    if (error) {
        return (
            <Box
                sx={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    width: "100%",
                    height: "100%",
                }}
            >
                <Typography sx={{ color: "rgba(255,255,255,0.7)" }}>
                    Unable to play video
                </Typography>
            </Box>
        );
    }

    return (
        <Box
            sx={{
                position: "relative",
                display: fillFrame ? "block" : "inline-block",
                width: fillFrame ? "100%" : "auto",
                height: fillFrame ? "100%" : "auto",
                overflow: "hidden",
            }}
        >
            {isLoading && showLoadingOverlay && <MediaLoadingOverlay />}

            {hlsData && (
                <hls-video
                    ref={setVideoElementRef}
                    src={hlsData.playlistURL}
                    poster={thumbnailURL}
                    playsInline
                    onLoadedMetadata={handleLoadedMetadata}
                    onCanPlay={handleCanPlay}
                    onEnded={handleEnded}
                    style={mediaStyle}
                />
            )}

            {!hlsData && videoURL && (
                <video
                    ref={setVideoElementRef}
                    src={videoURL}
                    poster={thumbnailURL}
                    playsInline
                    muted={false}
                    onLoadedMetadata={handleLoadedMetadata}
                    onCanPlay={handleCanPlay}
                    onEnded={handleEnded}
                    style={mediaStyle}
                />
            )}

            {!videoURL && !hlsData && thumbnailURL && (
                <img src={thumbnailURL} alt="" style={mediaStyle} />
            )}
        </Box>
    );
}
