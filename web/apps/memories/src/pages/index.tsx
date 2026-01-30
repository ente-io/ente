import { keyframes } from "@emotion/react";
import { Box, Link, Typography, styled } from "@mui/material";
import { Stack100vhCenter } from "ente-base/components/containers";
import { CustomHead } from "ente-base/components/Head";
import { LoadingIndicator } from "ente-base/components/loaders";
import { isHTTPErrorWithStatus } from "ente-base/http";
import log from "ente-base/log";
import {
    downloadManager,
    type RenderableSourceURLs,
} from "ente-gallery/services/download";
import { extractCollectionKeyFromShareURL } from "ente-gallery/services/share";
import type { HLSPlaylistData } from "ente-gallery/services/video";
import type { EnteFile } from "ente-media/file";
import { fileCreationPhotoDate } from "ente-media/file-metadata";
import { FileType } from "ente-media/file-type";
import {
    decryptMemoryShareName,
    getPublicMemoryFiles,
    getPublicMemoryInfo,
} from "ente-new/albums/services/public-memory";
import "hls-video-element";
import Head from "next/head";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";

/**
 * Index page that handles both root redirect and memory share links
 *
 * - Root domain (/) redirects to ente.io/memories
 * - Share links (/TOKEN#key) render the memory viewer
 *
 * This page is served for all routes via:
 * - _redirects file for Cloudflare Pages
 * - Next.js rewrites for local development
 * - nginx try_files for Docker deployment
 */
export default function PublicMemoryPage() {
    const [memoryName, setMemoryName] = useState<string>("");
    const [files, setFiles] = useState<EnteFile[] | undefined>(undefined);
    const [errorMessage, setErrorMessage] = useState<string>("");
    const [loading, setLoading] = useState(true);
    const [currentIndex, setCurrentIndex] = useState(0);
    const [hideContent, setHideContent] = useState(false);

    useEffect(() => {
        const main = async () => {
            try {
                const currentURL = new URL(window.location.href);

                // Extract token from either:
                // - query param ?t=TOKEN (from server-generated URLs)
                // - pathname /TOKEN (direct links)
                let token = currentURL.searchParams.get("t");
                if (!token) {
                    const path = window.location.pathname.slice(1);
                    // Ignore /memory path prefix
                    if (path && path !== "memory") {
                        token = path;
                    }
                }

                // Root path → redirect to ente.io/memories (or show landing)
                if (!token) {
                    setHideContent(true);
                    window.location.href = "https://ente.io/memories";
                    return;
                }
                const shareKey =
                    await extractCollectionKeyFromShareURL(currentURL);

                if (!shareKey) {
                    setErrorMessage("Invalid memory link. Missing secret.");
                    setLoading(false);
                    return;
                }

                const info = await getPublicMemoryInfo(token);

                if (info.metadataCipher && info.metadataNonce) {
                    const name = await decryptMemoryShareName(
                        info.metadataCipher,
                        info.metadataNonce,
                        shareKey,
                    );
                    setMemoryName(name);
                }

                downloadManager.setPublicMemoryCredentials({
                    accessToken: token,
                });

                const enteFiles = await getPublicMemoryFiles(token, shareKey);

                // Preserve the order from the server (matches mobile app's intended order)
                setFiles(enteFiles);
            } catch (e) {
                if (
                    isHTTPErrorWithStatus(e, 401) ||
                    isHTTPErrorWithStatus(e, 410)
                ) {
                    setErrorMessage(
                        "This memory link has expired or is no longer available.",
                    );
                } else if (isHTTPErrorWithStatus(e, 429)) {
                    setErrorMessage(
                        "Too many requests. Please try again later.",
                    );
                } else {
                    log.error("Failed to load public memory share", e);
                    setErrorMessage(
                        "Something went wrong. Please try again later.",
                    );
                }
            } finally {
                setLoading(false);
            }
        };
        main();
        return () => downloadManager.setPublicMemoryCredentials(undefined);
    }, []);

    const goToNext = useCallback(() => {
        if (!files) return;
        setCurrentIndex((prev) => (prev < files.length - 1 ? prev + 1 : prev));
    }, [files]);

    const goToPrev = useCallback(() => {
        setCurrentIndex((prev) => (prev > 0 ? prev - 1 : prev));
    }, []);

    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            if (e.key === "ArrowRight") goToNext();
            else if (e.key === "ArrowLeft") goToPrev();
        };
        window.addEventListener("keydown", handleKeyDown);
        return () => window.removeEventListener("keydown", handleKeyDown);
    }, [goToNext, goToPrev]);

    // Render custom head for SSR
    if (hideContent) {
        return (
            <>
                <CustomHead title="Ente Memories" />
                <Head>
                    <meta name="robots" content="noindex, nofollow" />
                </Head>
            </>
        );
    }

    if (loading) {
        return (
            <>
                <CustomHead title="Ente Memories" />
                <Head>
                    <meta name="robots" content="noindex, nofollow" />
                </Head>
                <LoadingIndicator />
            </>
        );
    }

    if (errorMessage) {
        return (
            <>
                <CustomHead title="Ente Memories" />
                <Head>
                    <meta name="robots" content="noindex, nofollow" />
                </Head>
                <Stack100vhCenter>
                    <Typography sx={{ color: "critical.main" }}>
                        {errorMessage}
                    </Typography>
                </Stack100vhCenter>
            </>
        );
    }

    if (!files || files.length === 0) {
        return (
            <>
                <CustomHead title="Ente Memories" />
                <Head>
                    <meta name="robots" content="noindex, nofollow" />
                </Head>
                <Stack100vhCenter>
                    <Typography>No photos found in this memory.</Typography>
                </Stack100vhCenter>
            </>
        );
    }

    return (
        <>
            <CustomHead title="Ente Memories" />
            <Head>
                <meta name="robots" content="noindex, nofollow" />
            </Head>
            <MemoryViewer
                files={files}
                currentIndex={currentIndex}
                memoryName={memoryName}
                onNext={goToNext}
                onPrev={goToPrev}
            />
        </>
    );
}

interface MemoryViewerProps {
    files: EnteFile[];
    currentIndex: number;
    memoryName: string;
    onNext: () => void;
    onPrev: () => void;
}

const IMAGE_AUTO_PROGRESS_DURATION_MS = 5000;

const progressFillAnimation = keyframes`
    from { width: 0%; }
    to { width: 100%; }
`;

const MemoryViewer: React.FC<MemoryViewerProps> = ({
    files,
    currentIndex,
    memoryName,
    onNext,
    onPrev,
}) => {
    const currentFile = files[currentIndex]!;
    const [paused, setPaused] = useState(false);
    const [fileLoaded, setFileLoaded] = useState(false);
    // For videos, track if duration is known (prevents premature animation start).
    const [videoDurationKnown, setVideoDurationKnown] = useState(false);
    // For videos, we track the duration in ms; for images, use the constant.
    const [progressDuration, setProgressDuration] = useState(
        IMAGE_AUTO_PROGRESS_DURATION_MS,
    );

    const isVideo = currentFile.metadata.fileType === FileType.video;

    // Reset loaded state and duration when file changes.
    useEffect(() => {
        setFileLoaded(false);
        setVideoDurationKnown(false);
        // Reset to image duration; video will update this when it loads.
        setProgressDuration(IMAGE_AUTO_PROGRESS_DURATION_MS);
    }, [currentIndex]);

    const handleFullLoad = useCallback(() => {
        setFileLoaded(true);
    }, []);

    const handleVideoDuration = useCallback((durationSeconds: number) => {
        // Convert seconds to milliseconds for the progress bar.
        setProgressDuration(durationSeconds * 1000);
        setVideoDurationKnown(true);
    }, []);

    // Preload next file's thumbnail for smoother navigation.
    useEffect(() => {
        if (currentIndex < files.length - 1) {
            const nextFile = files[currentIndex + 1]!;
            void downloadManager.renderableThumbnailURL(nextFile);
        }
    }, [currentIndex, files]);

    const handleClick = (e: React.MouseEvent<HTMLDivElement>) => {
        const rect = e.currentTarget.getBoundingClientRect();
        const clickX = e.clientX - rect.left;
        if (clickX < rect.width * 0.2) {
            onPrev();
        } else {
            onNext();
        }
    };

    return (
        <ViewerRoot>
            <BackgroundImage file={currentFile} />
            <BackgroundOverlay />
            <ContentContainer>
                <HeaderSection>
                    <MemoryTitle variant="h6">
                        {memoryName || "Memory"}
                    </MemoryTitle>
                    <ProgressIndicator
                        total={files.length}
                        current={currentIndex}
                        paused={
                            paused ||
                            !fileLoaded ||
                            (isVideo && !videoDurationKnown)
                        }
                        duration={progressDuration}
                        onComplete={onNext}
                        isVideo={isVideo}
                    />
                </HeaderSection>
                <PhotoContainer
                    onMouseEnter={() => setPaused(true)}
                    onMouseLeave={() => setPaused(false)}
                    onClick={handleClick}
                >
                    {isVideo ? (
                        <VideoPlayer
                            file={currentFile}
                            onReady={handleFullLoad}
                            onDuration={handleVideoDuration}
                            onEnded={onNext}
                            paused={paused}
                            dateBadge={<DateBadge file={currentFile} />}
                        />
                    ) : (
                        <PhotoImage
                            file={currentFile}
                            onFullLoad={handleFullLoad}
                            dateBadge={<DateBadge file={currentFile} />}
                        />
                    )}
                </PhotoContainer>
                <Footer />
            </ContentContainer>
        </ViewerRoot>
    );
};

const ViewerRoot = styled("div")({
    position: "relative",
    width: "100vw",
    height: "100vh",
    overflow: "hidden",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
});

const BackgroundOverlay = styled("div")({
    position: "absolute",
    inset: 0,
    backgroundColor: "rgba(0, 0, 0, 0.72)",
    backdropFilter: "blur(7.3px)",
    zIndex: 1,
});

const ContentContainer = styled("div")({
    position: "relative",
    zIndex: 2,
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    gap: "21px",
    width: "100%",
    maxWidth: "1264px",
    height: "100vh",
    padding: "24px 24px",
    boxSizing: "border-box",
});

const HeaderSection = styled("div")({
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    gap: "24px",
    flexShrink: 0,
    width: "100%",
});

const MemoryTitle = styled(Typography)({
    color: "white",
    fontWeight: 700,
    fontSize: "24px",
    lineHeight: "17px",
    letterSpacing: "-0.48px",
    textAlign: "center",
});

interface ProgressIndicatorProps {
    total: number;
    current: number;
    paused: boolean;
    duration: number;
    onComplete: () => void;
    /** If true, the progress bar won't auto-advance (video handles its own end). */
    isVideo?: boolean;
}

const ProgressIndicator: React.FC<ProgressIndicatorProps> = ({
    total,
    current,
    paused,
    duration,
    onComplete,
    isVideo,
}) => {
    // Calculate the total width: 30px per bar + 12px gap between bars
    const totalWidth = total * 30 + (total - 1) * 12;

    return (
        <Box
            sx={{
                display: "flex",
                gap: "12px",
                alignItems: "center",
                height: "6px",
                width: `${totalWidth}px`,
                maxWidth: "100%",
            }}
        >
            {Array.from({ length: total }, (_, i) => (
                <ProgressBar
                    // Use a unique key for the active bar so it remounts
                    // (restarting the CSS animation) when navigating.
                    key={i === current ? `active-${current}-${duration}` : i}
                    state={
                        i < current
                            ? "past"
                            : i === current
                              ? "active"
                              : "future"
                    }
                    paused={paused}
                    duration={duration}
                    // For videos, don't trigger onComplete from animation - video's onEnded handles it.
                    onComplete={
                        i === current && !isVideo ? onComplete : undefined
                    }
                />
            ))}
        </Box>
    );
};

interface ProgressBarProps {
    state: "past" | "active" | "future";
    paused: boolean;
    duration: number;
    onComplete?: () => void;
}

const ProgressBar: React.FC<ProgressBarProps> = ({
    state,
    paused,
    duration,
    onComplete,
}) => {
    return (
        <Box
            sx={{
                position: "relative",
                width: "30px",
                flexShrink: 0,
                height: "6px",
                borderRadius: "14px",
                backgroundColor: "rgba(255, 255, 255, 0.45)",
                overflow: "hidden",
            }}
        >
            <Box
                onAnimationEnd={state === "active" ? onComplete : undefined}
                sx={{
                    position: "absolute",
                    top: 0,
                    left: 0,
                    height: "100%",
                    borderRadius: "14px",
                    backgroundColor: "white",
                    width:
                        state === "past"
                            ? "100%"
                            : state === "active"
                              ? "100%"
                              : "0%",
                    ...(state === "active" && {
                        animation: `${progressFillAnimation} ${duration}ms linear forwards`,
                        animationPlayState: paused ? "paused" : "running",
                    }),
                    ...(state === "past" && { transition: "none" }),
                }}
            />
        </Box>
    );
};

const PhotoContainer = styled("div")({
    position: "relative",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    flex: 1,
    minHeight: 0,
    width: "100%",
    cursor: "pointer",
    userSelect: "none",
    WebkitUserSelect: "none",
});

interface PhotoImageProps {
    file: EnteFile;
    onFullLoad?: () => void;
    dateBadge?: React.ReactNode;
}

const PhotoImage: React.FC<PhotoImageProps> = ({
    file,
    onFullLoad,
    dateBadge,
}) => {
    const [url, setUrl] = useState<string | undefined>(undefined);
    const [isLoading, setIsLoading] = useState(true);
    const onFullLoadRef = useRef(onFullLoad);
    onFullLoadRef.current = onFullLoad;

    useEffect(() => {
        let cancelled = false;
        setIsLoading(true);
        const load = async () => {
            try {
                const thumbnailURL =
                    await downloadManager.renderableThumbnailURL(file);
                if (!cancelled && thumbnailURL) {
                    setUrl(thumbnailURL);
                }
            } catch (e) {
                log.error("Failed to load thumbnail", e);
                setIsLoading(false);
            }
        };
        load();
        return () => {
            cancelled = true;
        };
    }, [file]);

    return (
        <Box
            sx={{
                position: "relative",
                display: "inline-block",
                maxWidth: "100%",
                maxHeight: "100%",
                borderRadius: "24px",
                overflow: "hidden",
            }}
        >
            {/* Loading overlay */}
            {isLoading && (
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
                    <LoadingIndicator />
                </Box>
            )}
            {/* Image */}
            {url && (
                <img
                    src={url}
                    alt=""
                    draggable={false}
                    onLoad={() => {
                        setIsLoading(false);
                        onFullLoadRef.current?.();
                    }}
                    style={{
                        display: "block",
                        maxWidth: "100%",
                        maxHeight: "100%",
                        objectFit: "contain",
                        userSelect: "none",
                        pointerEvents: "none",
                    }}
                />
            )}
            {/* Date badge positioned over the image */}
            {dateBadge}
        </Box>
    );
};

interface VideoPlayerProps {
    file: EnteFile;
    onReady?: () => void;
    onDuration?: (durationSeconds: number) => void;
    onEnded?: () => void;
    paused?: boolean;
    dateBadge?: React.ReactNode;
}

const VideoPlayer: React.FC<VideoPlayerProps> = ({
    file,
    onReady,
    onDuration,
    onEnded,
    paused,
    dateBadge,
}) => {
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

    // Load video URL (try HLS first, fallback to direct download)
    useEffect(() => {
        let cancelled = false;
        setIsLoading(true);
        setError(false);
        setVideoURL(undefined);
        setHlsData(undefined);

        const load = async () => {
            try {
                // First load thumbnail as poster
                const thumbURL =
                    await downloadManager.renderableThumbnailURL(file);
                if (!cancelled && thumbURL) {
                    setThumbnailURL(thumbURL);
                }

                // Try HLS streaming first (better quality, adaptive bitrate)
                const hlsPlaylistData =
                    await downloadManager.hlsPlaylistDataForPublicMemory(file);
                if (
                    !cancelled &&
                    typeof hlsPlaylistData === "object" &&
                    hlsPlaylistData?.playlistURL
                ) {
                    setHlsData(hlsPlaylistData);
                    return;
                }

                // Fallback to direct video download
                const sourceURLs: RenderableSourceURLs =
                    await downloadManager.renderableSourceURLs(file);
                if (!cancelled && sourceURLs.type === "video") {
                    setVideoURL(sourceURLs.videoURL);
                }
            } catch (e) {
                log.error("Failed to load video", e);
                if (!cancelled) {
                    setError(true);
                    setIsLoading(false);
                }
            }
        };
        load();
        return () => {
            cancelled = true;
        };
    }, [file]);

    // Handle pause/play state
    useEffect(() => {
        const video = videoRef.current;
        if (!video || (!videoURL && !hlsData)) return;

        if (paused) {
            video.pause();
        } else {
            video.play().catch(() => {
                // Autoplay may be blocked; ignore
            });
        }
    }, [paused, videoURL, hlsData]);

    const handleLoadedMetadata = useCallback(() => {
        const video = videoRef.current;
        if (video && !isNaN(video.duration) && video.duration > 0) {
            onDurationRef.current?.(video.duration);
        }
    }, []);

    const handleCanPlay = useCallback(() => {
        setIsLoading(false);
        onReadyRef.current?.();
        // Auto-play when ready
        const video = videoRef.current;
        if (video) {
            video.play().catch(() => {
                // Autoplay may be blocked
            });
        }
    }, []);

    const handleEnded = useCallback(() => {
        onEndedRef.current?.();
    }, []);

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
                display: "inline-block",
                maxWidth: "100%",
                maxHeight: "100%",
                borderRadius: "24px",
                overflow: "hidden",
            }}
        >
            {/* Loading overlay */}
            {isLoading && (
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
                    <LoadingIndicator />
                </Box>
            )}
            {/* HLS video element (when HLS streaming is available) */}
            {hlsData && (
                <hls-video
                    ref={videoRef as React.RefObject<HTMLVideoElement>}
                    src={hlsData.playlistURL}
                    poster={thumbnailURL}
                    playsInline
                    onLoadedMetadata={handleLoadedMetadata}
                    onCanPlay={handleCanPlay}
                    onEnded={handleEnded}
                    style={{
                        display: "block",
                        maxWidth: "100%",
                        maxHeight: "100%",
                        objectFit: "contain",
                        userSelect: "none",
                    }}
                />
            )}
            {/* Regular video element (fallback when HLS is not available) */}
            {!hlsData && videoURL && (
                <video
                    ref={videoRef}
                    src={videoURL}
                    poster={thumbnailURL}
                    playsInline
                    muted={false}
                    onLoadedMetadata={handleLoadedMetadata}
                    onCanPlay={handleCanPlay}
                    onEnded={handleEnded}
                    style={{
                        display: "block",
                        maxWidth: "100%",
                        maxHeight: "100%",
                        objectFit: "contain",
                        userSelect: "none",
                    }}
                />
            )}
            {/* Show thumbnail while video loads */}
            {!videoURL && !hlsData && thumbnailURL && (
                <img
                    src={thumbnailURL}
                    alt=""
                    style={{
                        display: "block",
                        maxWidth: "100%",
                        maxHeight: "100%",
                        objectFit: "contain",
                        userSelect: "none",
                        pointerEvents: "none",
                    }}
                />
            )}
            {/* Date badge positioned over the video */}
            {dateBadge}
        </Box>
    );
};

interface FileImageProps {
    file: EnteFile;
}

const BackgroundImage: React.FC<FileImageProps> = ({ file }) => {
    const [url, setUrl] = useState<string | undefined>(undefined);

    useEffect(() => {
        let cancelled = false;
        const load = async () => {
            try {
                const thumbnailURL =
                    await downloadManager.renderableThumbnailURL(file);
                if (!cancelled && thumbnailURL) {
                    setUrl(thumbnailURL);
                }
            } catch (e) {
                // Silently fail for background
            }
        };
        load();
        return () => {
            cancelled = true;
        };
    }, [file]);

    if (!url) return null;

    return (
        <img
            src={url}
            alt=""
            style={{
                position: "absolute",
                inset: "-20px",
                width: "calc(100% + 40px)",
                height: "calc(100% + 40px)",
                objectFit: "cover",
                zIndex: 0,
            }}
        />
    );
};

interface DateBadgeProps {
    file: EnteFile;
}

const DateBadge: React.FC<DateBadgeProps> = ({ file }) => {
    const dateString = useMemo(() => {
        try {
            const date = fileCreationPhotoDate(file);
            return formatMemoryDate(date);
        } catch {
            return "";
        }
    }, [file]);

    if (!dateString) return null;

    return (
        <Box
            sx={{
                position: "absolute",
                top: "24px",
                left: "24px",
                backgroundColor: "rgba(0, 0, 0, 0.4)",
                border: "1px solid rgba(255, 255, 255, 0.18)",
                borderRadius: "42px",
                padding: "14px",
            }}
        >
            <Typography
                sx={{
                    color: "white",
                    fontSize: "13.728px",
                    fontWeight: 500,
                    lineHeight: "11.669px",
                }}
            >
                {dateString}
            </Typography>
        </Box>
    );
};

/**
 * Format a date in the style "12th Jan, 2022".
 */
const formatMemoryDate = (date: Date): string => {
    const day = date.getDate();
    const month = date.toLocaleString("en", { month: "short" });
    const year = date.getFullYear();
    const ordinal = getOrdinalSuffix(day);
    return `${day}${ordinal} ${month}, ${year}`;
};

const getOrdinalSuffix = (n: number): string => {
    const s = ["th", "st", "nd", "rd"];
    const v = n % 100;
    return s[(v - 20) % 10] || s[v] || s[0]!;
};

const Footer: React.FC = () => (
    <Box sx={{ flexShrink: 0, textAlign: "center", width: "100%" }}>
        <Link
            href="https://ente.io"
            target="_blank"
            underline="none"
            sx={{
                color: "rgba(255, 255, 255, 0.53)",
                "&:hover": { color: "rgba(255, 255, 255, 0.7)" },
            }}
        >
            <Typography
                sx={{
                    fontSize: "16px",
                    fontWeight: 600,
                    lineHeight: "12.741px",
                }}
            >
                Shared using{" "}
                <Typography
                    component="span"
                    sx={{
                        fontSize: "16px",
                        fontWeight: 600,
                        lineHeight: "12.741px",
                        color: "#08c225",
                    }}
                >
                    ente.io
                </Typography>
            </Typography>
        </Link>
    </Box>
);
