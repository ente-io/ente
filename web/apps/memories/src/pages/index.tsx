import { keyframes } from "@emotion/react";
import { Box, Typography, styled } from "@mui/material";
import { Stack100vhCenter } from "ente-base/components/containers";
import { EnteLogo } from "ente-base/components/EnteLogo";
import { CustomHead } from "ente-base/components/Head";
import { LoadingIndicator } from "ente-base/components/loaders";
import { toB64 } from "ente-base/crypto";
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

const shortMemorySecretPattern = /^[0-9A-Za-z]{12}$/;

const extractMemoryShareKeyFromURL = async (
    url: URL,
): Promise<string | null> => {
    const fragment = url.hash.slice(1).trim();
    if (!fragment) return null;

    if (shortMemorySecretPattern.test(fragment)) {
        const digest = await globalThis.crypto.subtle.digest(
            "SHA-256",
            new TextEncoder().encode(fragment),
        );
        return await toB64(new Uint8Array(digest));
    }

    return await extractCollectionKeyFromShareURL(url);
};

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
                    // Ignore routing prefixes like /memory and pick the first
                    // non-empty path segment as token.
                    const tokenFromPath = currentURL.pathname
                        .split("/")
                        .find(
                            (segment) =>
                                segment.length > 0 && segment !== "memory",
                        );
                    if (tokenFromPath) {
                        token = tokenFromPath;
                    }
                }

                // Root path → redirect to ente.io/memories (or show landing)
                if (!token) {
                    setHideContent(true);
                    window.location.href = "https://ente.io/memories";
                    return;
                }
                const shareKey = await extractMemoryShareKeyFromURL(currentURL);

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
        void main();
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
const MOBILE_LAYOUT_BREAKPOINT_PX = 600;
const EDGE_NAV_TAP_ZONE_RATIO = 0.2;
const HOLD_TO_PAUSE_NAV_SUPPRESSION_MS = 250;
const MOBILE_MEDIA_RESERVED_VERTICAL_SPACE_PX = 280;
const DESKTOP_MEDIA_MAX_WIDTH_PX = 1264;
const DESKTOP_MEDIA_HORIZONTAL_PADDING_PX = 48;
const DESKTOP_MEDIA_VERTICAL_RESERVED_PX = 220;
const MEDIA_SWITCH_TRANSITION_DURATION_MS = 380;
const DESKTOP_PROGRESS_MAX_WIDTH_PX = 448;
const MOBILE_PROGRESS_MAX_WIDTH_PX = 326;
const DESKTOP_MEDIA_MAX_WIDTH_CSS = `min(${DESKTOP_MEDIA_MAX_WIDTH_PX}px, calc(100vw - ${DESKTOP_MEDIA_HORIZONTAL_PADDING_PX}px))`;
const DESKTOP_MEDIA_MAX_HEIGHT_CSS = `calc(min(100vh, 100dvh) - ${DESKTOP_MEDIA_VERTICAL_RESERVED_PX}px)`;
const DESKTOP_BACKGROUND_IMAGE_PATH = "/images/desktop-bg.svg";
const MOBILE_BACKGROUND_IMAGE_PATH = "/images/mobile-bg.svg";

const isInteractiveTapTarget = (target: EventTarget | null) => {
    if (!(target instanceof Element)) return false;
    return Boolean(
        target.closest(
            "button, a, input, textarea, select, [role='button'], [data-memory-control='true']",
        ),
    );
};

const progressFillAnimation = keyframes`
    from { width: 0%; }
    to { width: 100%; }
`;

const mediaSwitchInAnimation = keyframes`
    from {
        opacity: 0;
        transform: translateY(4px) scale(0.996);
    }
    to {
        opacity: 1;
        transform: translateY(0) scale(1);
    }
`;

const mediaSwitchOutAnimation = keyframes`
    from {
        opacity: 1;
        transform: translateY(0) scale(1);
    }
    to {
        opacity: 0;
        transform: translateY(-2px) scale(1.005);
    }
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
    const [mediaAspectRatio, setMediaAspectRatio] = useState<number>();
    const [viewport, setViewport] = useState({ width: 1280, height: 720 });
    const [outgoingFile, setOutgoingFile] = useState<EnteFile | null>(null);
    const [outgoingIsVideo, setOutgoingIsVideo] = useState(false);
    const [outgoingIndex, setOutgoingIndex] = useState<number | null>(null);
    const pressStartedAtRef = useRef<number | null>(null);
    const suppressTapNavigationRef = useRef(false);
    const previousFileRef = useRef(currentFile);
    const previousIndexRef = useRef(currentIndex);
    const outgoingClearTimeoutRef = useRef<number | null>(null);

    const isVideo = currentFile.metadata.fileType === FileType.video;
    const isMobileLayout = viewport.width <= MOBILE_LAYOUT_BREAKPOINT_PX;

    // Reset loaded state and duration when file changes.
    useEffect(() => {
        setPaused(false);
        setFileLoaded(false);
        setVideoDurationKnown(false);
        setMediaAspectRatio(undefined);
        // Reset to image duration; video will update this when it loads.
        setProgressDuration(IMAGE_AUTO_PROGRESS_DURATION_MS);
    }, [currentIndex]);

    useEffect(() => {
        const previousIndex = previousIndexRef.current;
        const previousFile = previousFileRef.current;
        if (previousIndex !== currentIndex) {
            setOutgoingFile(previousFile);
            setOutgoingIsVideo(
                previousFile.metadata.fileType === FileType.video,
            );
            setOutgoingIndex(previousIndex);

            if (outgoingClearTimeoutRef.current !== null) {
                window.clearTimeout(outgoingClearTimeoutRef.current);
            }
            outgoingClearTimeoutRef.current = window.setTimeout(() => {
                setOutgoingFile(null);
                setOutgoingIndex(null);
                outgoingClearTimeoutRef.current = null;
            }, MEDIA_SWITCH_TRANSITION_DURATION_MS);
        }

        previousIndexRef.current = currentIndex;
        previousFileRef.current = currentFile;
    }, [currentFile, currentIndex]);

    useEffect(
        () => () => {
            if (outgoingClearTimeoutRef.current !== null) {
                window.clearTimeout(outgoingClearTimeoutRef.current);
            }
        },
        [],
    );

    const handleFullLoad = useCallback(() => {
        setFileLoaded(true);
    }, []);

    const handleVideoDuration = useCallback((durationSeconds: number) => {
        // Convert seconds to milliseconds for the progress bar.
        setProgressDuration(durationSeconds * 1000);
        setVideoDurationKnown(true);
    }, []);

    const handleMediaAspectRatio = useCallback(
        (width: number, height: number) => {
            if (width <= 0 || height <= 0) return;
            setMediaAspectRatio(width / height);
        },
        [],
    );

    // Preload next file's thumbnail for smoother navigation.
    useEffect(() => {
        if (currentIndex < files.length - 1) {
            const nextFile = files[currentIndex + 1]!;
            void downloadManager.renderableThumbnailURL(nextFile);
        }
    }, [currentIndex, files]);

    useEffect(() => {
        const updateViewport = () =>
            setViewport({
                width: window.innerWidth,
                height: window.innerHeight,
            });

        updateViewport();
        window.addEventListener("resize", updateViewport);
        return () => window.removeEventListener("resize", updateViewport);
    }, []);

    const currentFileDate = useMemo(() => {
        try {
            return formatMemoryDate(fileCreationPhotoDate(currentFile));
        } catch {
            return "";
        }
    }, [currentFile]);

    const headerTitle = useMemo(() => {
        if (memoryName && currentFileDate)
            return `${memoryName} • ${currentFileDate}`;
        return memoryName || currentFileDate || "Memory";
    }, [memoryName, currentFileDate]);

    const handleScreenTap = (e: React.MouseEvent<HTMLDivElement>) => {
        if (suppressTapNavigationRef.current) {
            suppressTapNavigationRef.current = false;
            return;
        }
        if (isInteractiveTapTarget(e.target)) return;

        const screenWidth = viewport.width;
        const clickX = e.clientX;
        if (clickX <= screenWidth * EDGE_NAV_TAP_ZONE_RATIO) {
            onPrev();
        } else if (clickX >= screenWidth * (1 - EDGE_NAV_TAP_ZONE_RATIO)) {
            onNext();
        }
    };

    const resolvedMediaAspectRatio = useMemo(() => {
        if (typeof mediaAspectRatio === "number" && mediaAspectRatio > 0) {
            return mediaAspectRatio;
        }

        const width = currentFile.pubMagicMetadata?.data.w;
        const height = currentFile.pubMagicMetadata?.data.h;
        if (
            typeof width === "number" &&
            width > 0 &&
            typeof height === "number" &&
            height > 0
        ) {
            return width / height;
        }

        return undefined;
    }, [currentFile, mediaAspectRatio]);

    const mobileFrameSize = useMemo(() => {
        const availableWidth = Math.max(220, viewport.width - 48);
        const maxWidth = Math.min(326, availableWidth);
        const maxHeight = Math.max(
            180,
            viewport.height - MOBILE_MEDIA_RESERVED_VERTICAL_SPACE_PX,
        );
        const ratio = resolvedMediaAspectRatio ?? 4 / 3;

        let width = maxWidth;
        let height = width / ratio;

        if (height > maxHeight) {
            height = maxHeight;
            width = height * ratio;
        }

        return { width: Math.round(width), height: Math.round(height) };
    }, [resolvedMediaAspectRatio, viewport.height, viewport.width]);

    const desktopFrameSize = useMemo(() => {
        const availableWidth = Math.max(
            360,
            viewport.width - DESKTOP_MEDIA_HORIZONTAL_PADDING_PX,
        );
        const availableHeight = Math.max(
            240,
            viewport.height - DESKTOP_MEDIA_VERTICAL_RESERVED_PX,
        );
        const maxWidth = Math.min(DESKTOP_MEDIA_MAX_WIDTH_PX, availableWidth);
        const ratio =
            typeof resolvedMediaAspectRatio === "number"
                ? resolvedMediaAspectRatio
                : 4 / 3;

        let width = maxWidth;
        let height = width / ratio;

        if (height > availableHeight) {
            height = availableHeight;
            width = height * ratio;
        }

        return { width: Math.round(width), height: Math.round(height) };
    }, [resolvedMediaAspectRatio, viewport.height, viewport.width]);

    const mediaFrameStyle = isMobileLayout
        ? {
              width: `${mobileFrameSize.width}px`,
              aspectRatio: `${resolvedMediaAspectRatio ?? 4 / 3}`,
          }
        : {
              width: `${desktopFrameSize.width}px`,
              aspectRatio: `${resolvedMediaAspectRatio ?? 4 / 3}`,
          };

    return (
        <ViewerRoot onClick={handleScreenTap}>
            <BackgroundPattern />
            <ContentContainer
                style={
                    isMobileLayout
                        ? {
                              maxWidth: "375px",
                              padding: "24px 24px 26px",
                              gap: "16px",
                          }
                        : undefined
                }
            >
                {isMobileLayout ? (
                    <MobileHeaderSection>
                        <MobileTitle variant="h6">{headerTitle}</MobileTitle>
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
                            compact
                        />
                    </MobileHeaderSection>
                ) : (
                    <TopControls>
                        <PlaybackControl
                            type="button"
                            onClick={(event) => {
                                event.stopPropagation();
                                setPaused((state) => !state);
                            }}
                            aria-label={paused ? "Play" : "Pause"}
                            data-memory-control="true"
                        >
                            <PlaybackGlyph paused={paused} />
                        </PlaybackControl>

                        <HeaderSection>
                            <MemoryTitle variant="h6">
                                {headerTitle}
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

                        <TopRightActions>
                            <BrandLink
                                href="https://ente.io"
                                target="_blank"
                                rel="noreferrer"
                                data-memory-control="true"
                            >
                                <DesktopBrandFigma>
                                    <DesktopBrandWordmark>
                                        <EnteLogo height={16.4} />
                                    </DesktopBrandWordmark>
                                    <DesktopBrandTag>photos</DesktopBrandTag>
                                </DesktopBrandFigma>
                            </BrandLink>
                            <JoinNowButton
                                href="https://ente.io"
                                target="_blank"
                                rel="noreferrer"
                            >
                                Join now
                            </JoinNowButton>
                        </TopRightActions>
                    </TopControls>
                )}

                <PhotoContainer
                    onContextMenu={(event) => event.preventDefault()}
                    onDragStart={(event) => event.preventDefault()}
                    onPointerDown={
                        isMobileLayout
                            ? () => {
                                  pressStartedAtRef.current = Date.now();
                                  suppressTapNavigationRef.current = false;
                                  setPaused(true);
                              }
                            : undefined
                    }
                    onPointerUp={
                        isMobileLayout
                            ? () => {
                                  const startedAt = pressStartedAtRef.current;
                                  pressStartedAtRef.current = null;
                                  if (
                                      startedAt &&
                                      Date.now() - startedAt >
                                          HOLD_TO_PAUSE_NAV_SUPPRESSION_MS
                                  ) {
                                      suppressTapNavigationRef.current = true;
                                  }
                                  setPaused(false);
                              }
                            : undefined
                    }
                    onPointerCancel={
                        isMobileLayout
                            ? () => {
                                  pressStartedAtRef.current = null;
                                  setPaused(false);
                              }
                            : undefined
                    }
                    onPointerLeave={
                        isMobileLayout
                            ? () => {
                                  if (pressStartedAtRef.current !== null) {
                                      pressStartedAtRef.current = null;
                                      setPaused(false);
                                  }
                              }
                            : undefined
                    }
                >
                    <MediaFrame style={mediaFrameStyle}>
                        <MediaSwitchLayer
                            phase="in"
                            key={`memory-file-${currentIndex}`}
                        >
                            {isVideo ? (
                                <VideoPlayer
                                    file={currentFile}
                                    onReady={handleFullLoad}
                                    onDuration={handleVideoDuration}
                                    onEnded={onNext}
                                    paused={paused}
                                    fillFrame
                                    onAspectRatio={handleMediaAspectRatio}
                                />
                            ) : (
                                <PhotoImage
                                    file={currentFile}
                                    onFullLoad={handleFullLoad}
                                    fillFrame
                                    onAspectRatio={handleMediaAspectRatio}
                                />
                            )}
                        </MediaSwitchLayer>
                        {outgoingFile && (
                            <MediaSwitchLayer
                                phase="out"
                                key={`memory-file-out-${outgoingIndex ?? currentIndex}`}
                            >
                                {outgoingIsVideo ? (
                                    <VideoPlayer
                                        file={outgoingFile}
                                        paused
                                        fillFrame
                                        showLoadingOverlay={false}
                                    />
                                ) : (
                                    <PhotoImage
                                        file={outgoingFile}
                                        fillFrame
                                        showLoadingOverlay={false}
                                    />
                                )}
                            </MediaSwitchLayer>
                        )}
                    </MediaFrame>
                </PhotoContainer>

                {isMobileLayout && (
                    <MobileBottomBar>
                        <BrandLink
                            href="https://ente.io"
                            target="_blank"
                            rel="noreferrer"
                            data-memory-control="true"
                        >
                            <DesktopBrandFigma>
                                <DesktopBrandWordmark>
                                    <EnteLogo height={16.4} />
                                </DesktopBrandWordmark>
                                <DesktopBrandTag>photos</DesktopBrandTag>
                            </DesktopBrandFigma>
                        </BrandLink>
                        <MobileJoinNowButton
                            href="https://ente.io"
                            target="_blank"
                            rel="noreferrer"
                        >
                            Join now
                        </MobileJoinNowButton>
                    </MobileBottomBar>
                )}
            </ContentContainer>
        </ViewerRoot>
    );
};

const ViewerRoot = styled("div")({
    position: "relative",
    width: "100vw",
    minHeight: "100vh",
    height: "100dvh",
    overflow: "hidden",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
});

const BackgroundPattern = styled("div")({
    position: "fixed",
    inset: 0,
    backgroundColor: "#1f1f1f",
    backgroundImage: `url(${DESKTOP_BACKGROUND_IMAGE_PATH})`,
    backgroundRepeat: "no-repeat",
    backgroundSize: "cover",
    backgroundPosition: "center",
    zIndex: 1,
    [`@media (max-width: ${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        backgroundImage: `url(${MOBILE_BACKGROUND_IMAGE_PATH})`,
        backgroundRepeat: "no-repeat",
        backgroundSize: "cover",
        backgroundPosition: "center",
    },
});

const ContentContainer = styled("div")({
    position: "relative",
    zIndex: 2,
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    gap: "32px",
    width: "100%",
    maxWidth: `${DESKTOP_MEDIA_MAX_WIDTH_PX}px`,
    minHeight: "100vh",
    height: "100dvh",
    padding: "42px 24px 24px",
    boxSizing: "border-box",
});

const MobileHeaderSection = styled("div")({
    width: "100%",
    display: "flex",
    flexDirection: "column",
    alignItems: "flex-start",
    gap: "12px",
});

const MobileTitle = styled(Typography)({
    color: "white",
    fontWeight: 700,
    fontSize: "16px",
    lineHeight: "17px",
    letterSpacing: 0,
    textAlign: "left",
    maxWidth: "326px",
    whiteSpace: "normal",
    overflowWrap: "anywhere",
});

const TopControls = styled("div")({
    position: "relative",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    minHeight: "64px",
    width: "100%",
    boxSizing: "border-box",
    "@media (max-width: 900px)": { minHeight: "56px" },
});

const HeaderSection = styled("div")({
    width: "min(100%, 448px)",
    maxWidth: `${DESKTOP_PROGRESS_MAX_WIDTH_PX}px`,
    minWidth: 0,
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    gap: "24px",
});

const MemoryTitle = styled(Typography)({
    color: "white",
    fontWeight: 700,
    fontSize: "24px",
    lineHeight: 1.25,
    letterSpacing: "-0.48px",
    textAlign: "center",
    whiteSpace: "normal",
    overflowWrap: "anywhere",
    maxWidth: "100%",
    "@media (max-width: 900px)": { fontSize: "20px" },
    "@media (max-width: 700px)": { fontSize: "17px", lineHeight: 1.3 },
});

const PlaybackControl = styled("button")({
    position: "absolute",
    left: 0,
    top: "50%",
    transform: "translateY(-50%)",
    width: "64px",
    height: "64px",
    borderRadius: "19.2px",
    border: 0,
    cursor: "pointer",
    backgroundColor: "rgba(255, 255, 255, 0.2)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    color: "white",
    padding: 0,
    transition: "background-color 150ms ease",
    "&:hover": { backgroundColor: "rgba(255, 255, 255, 0.28)" },
    "@media (max-width: 900px)": {
        width: "56px",
        height: "56px",
        borderRadius: "16px",
    },
});

const JoinNowButton = styled("a")({
    backgroundColor: "#08c225",
    color: "white",
    textDecoration: "none",
    borderRadius: "39.459px",
    padding: "18px 32px",
    fontWeight: 700,
    fontSize: "16px",
    lineHeight: "14px",
    whiteSpace: "nowrap",
    transition: "filter 150ms ease",
    "&:hover": { filter: "brightness(1.08)" },
    "@media (max-width: 900px)": { padding: "14px 24px", fontSize: "14px" },
});

const TopRightActions = styled("div")({
    position: "absolute",
    right: "-72px",
    top: "50%",
    transform: "translateY(-50%)",
    display: "flex",
    alignItems: "center",
    gap: "16px",
    "@media (max-width: 1200px)": { right: "-36px" },
    "@media (max-width: 1000px)": { right: 0 },
    "@media (max-width: 900px)": { gap: "10px" },
});

const BrandLink = styled("a")({
    color: "inherit",
    textDecoration: "none",
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    flexShrink: 0,
});

const DesktopBrandFigma = styled("div")({
    position: "relative",
    width: "58px",
    height: "42px",
    lineHeight: 0,
    flexShrink: 0,
});

const DesktopBrandWordmark = styled("div")({
    position: "absolute",
    top: "0",
    left: "0",
    color: "white",
    transform: "rotate(-4.27deg)",
    transformOrigin: "left center",
});

const BrandTagBase = styled("div")({
    borderRadius: "999px",
    padding: "2px 8px",
    fontSize: "9px",
    lineHeight: "11px",
    fontWeight: 700,
    backgroundColor: "#08c225",
    color: "white",
    whiteSpace: "nowrap",
});

const DesktopBrandTag = styled(BrandTagBase)({
    position: "absolute",
    right: "0",
    top: "14px",
    transform: "rotate(-8.52deg)",
    transformOrigin: "right top",
});

const MobileBottomBar = styled("div")({
    width: "100%",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    gap: "10px",
    marginTop: "auto",
    paddingBottom: "2px",
});

const MobileJoinNowButton = styled("a")({
    backgroundColor: "#08c225",
    color: "white",
    textDecoration: "none",
    borderRadius: "32.836px",
    padding: "15.636px 28.145px",
    fontWeight: 700,
    fontSize: "14px",
    lineHeight: "12px",
    whiteSpace: "nowrap",
});

const PlaybackGlyph: React.FC<{ paused: boolean }> = ({ paused }) => {
    if (paused) {
        return (
            <Box
                sx={{
                    width: 0,
                    height: 0,
                    borderTop: "10px solid transparent",
                    borderBottom: "10px solid transparent",
                    borderLeft: "14px solid white",
                    ml: "3px",
                }}
            />
        );
    }

    return (
        <Box sx={{ display: "flex", gap: "6px" }}>
            <Box
                sx={{
                    width: "6px",
                    height: "18px",
                    borderRadius: "2px",
                    backgroundColor: "white",
                }}
            />
            <Box
                sx={{
                    width: "6px",
                    height: "18px",
                    borderRadius: "2px",
                    backgroundColor: "white",
                }}
            />
        </Box>
    );
};

interface ProgressIndicatorProps {
    total: number;
    current: number;
    paused: boolean;
    duration: number;
    onComplete: () => void;
    /** If true, the progress bar won't auto-advance (video handles its own end). */
    isVideo?: boolean;
    compact?: boolean;
}

const ProgressIndicator: React.FC<ProgressIndicatorProps> = ({
    total,
    current,
    paused,
    duration,
    onComplete,
    isVideo,
    compact,
}) => {
    const segments = useMemo(
        () => Array.from({ length: total }, (_, i) => i),
        [total],
    );
    const progressGap = total > 15 ? "4px" : "12px";

    return (
        <Box
            sx={{
                display: "flex",
                gap: progressGap,
                alignItems: "center",
                width: "100%",
                maxWidth: compact
                    ? `${MOBILE_PROGRESS_MAX_WIDTH_PX}px`
                    : `${DESKTOP_PROGRESS_MAX_WIDTH_PX}px`,
                minWidth: 0,
                height: "4px",
            }}
        >
            {segments.map((i) => (
                <ProgressBar
                    key={
                        i === current
                            ? `active-${current}-${duration}`
                            : `segment-${i}`
                    }
                    state={
                        i < current
                            ? "past"
                            : i === current
                              ? "active"
                              : "future"
                    }
                    paused={paused}
                    duration={duration}
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
                flex: 1,
                minWidth: 0,
                height: "4px",
                borderRadius: "14px",
                backgroundColor: "rgba(255, 255, 255, 0.45)",
                overflow: "hidden",
            }}
        >
            <Box
                onAnimationEnd={state === "active" ? onComplete : undefined}
                style={
                    state === "active"
                        ? { animationPlayState: paused ? "paused" : "running" }
                        : undefined
                }
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
    WebkitTouchCallout: "none",
    touchAction: "manipulation",
});

const MediaFrame = styled("div")({
    position: "relative",
    borderRadius: "24px",
    overflow: "hidden",
    isolation: "isolate",
    backgroundColor: "transparent",
    width: "fit-content",
    height: "fit-content",
    maxWidth: DESKTOP_MEDIA_MAX_WIDTH_CSS,
    maxHeight: DESKTOP_MEDIA_MAX_HEIGHT_CSS,
    flexShrink: 0,
    lineHeight: 0,
});

const MediaSwitchLayer = styled("div", {
    shouldForwardProp: (prop) => prop !== "phase",
})<{ phase: "in" | "out" }>(({ phase }) => ({
    position: "absolute",
    inset: 0,
    width: "100%",
    height: "100%",
    zIndex: phase === "out" ? 2 : 1,
    animation:
        phase === "out"
            ? `${mediaSwitchOutAnimation} ${MEDIA_SWITCH_TRANSITION_DURATION_MS}ms cubic-bezier(0.16, 1, 0.3, 1) forwards`
            : `${mediaSwitchInAnimation} ${MEDIA_SWITCH_TRANSITION_DURATION_MS}ms cubic-bezier(0.16, 1, 0.3, 1) both`,
    willChange: "opacity, transform",
    pointerEvents: "none",
}));

interface PhotoImageProps {
    file: EnteFile;
    onFullLoad?: () => void;
    fillFrame?: boolean;
    onAspectRatio?: (width: number, height: number) => void;
    showLoadingOverlay?: boolean;
}

const PhotoImage: React.FC<PhotoImageProps> = ({
    file,
    onFullLoad,
    fillFrame,
    onAspectRatio,
    showLoadingOverlay = true,
}) => {
    const [thumbnailURL, setThumbnailURL] = useState<string | undefined>(
        undefined,
    );
    const [fullImageURL, setFullImageURL] = useState<string | undefined>(
        undefined,
    );
    const [isLoading, setIsLoading] = useState(true);
    const onFullLoadRef = useRef(onFullLoad);
    const hasSignaledReadyRef = useRef(false);
    onFullLoadRef.current = onFullLoad;
    const signalReady = useCallback(() => {
        if (hasSignaledReadyRef.current) return;
        hasSignaledReadyRef.current = true;
        onFullLoadRef.current?.();
    }, []);

    useEffect(() => {
        let cancelled = false;
        setIsLoading(true);
        setThumbnailURL(undefined);
        setFullImageURL(undefined);
        hasSignaledReadyRef.current = false;

        const loadThumbnail = async () => {
            try {
                const thumbnailURL =
                    await downloadManager.renderableThumbnailURL(file);
                if (!cancelled && thumbnailURL) {
                    setThumbnailURL(thumbnailURL);
                } else if (!cancelled) {
                    setIsLoading(false);
                }
            } catch (e) {
                log.error("Failed to load thumbnail", e);
                setIsLoading(false);
            }
        };

        const loadFullImage = async () => {
            try {
                const sourceURLs =
                    await downloadManager.renderableSourceURLs(file);
                if (cancelled) return;
                if (sourceURLs.type === "image") {
                    setFullImageURL(sourceURLs.imageURL);
                } else {
                    signalReady();
                }
            } catch (e) {
                log.error("Failed to load full image", e);
                if (!cancelled) signalReady();
            }
        };

        void loadThumbnail();
        void loadFullImage();
        return () => {
            cancelled = true;
        };
    }, [file, signalReady]);

    const displayURL = fullImageURL ?? thumbnailURL;

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
            {isLoading && showLoadingOverlay && (
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

            {displayURL && (
                <img
                    src={displayURL}
                    alt=""
                    draggable={false}
                    onLoad={(event) => {
                        const isFullImageLoad =
                            !!fullImageURL &&
                            event.currentTarget.src === fullImageURL;
                        if (isFullImageLoad) {
                            onAspectRatio?.(
                                event.currentTarget.naturalWidth,
                                event.currentTarget.naturalHeight,
                            );
                        }
                        setIsLoading(false);
                        if (isFullImageLoad) {
                            signalReady();
                        }
                    }}
                    style={{
                        display: "block",
                        width: fillFrame ? "100%" : "auto",
                        height: fillFrame ? "100%" : "auto",
                        maxWidth: fillFrame
                            ? "100%"
                            : DESKTOP_MEDIA_MAX_WIDTH_CSS,
                        maxHeight: fillFrame
                            ? "100%"
                            : DESKTOP_MEDIA_MAX_HEIGHT_CSS,
                        objectFit: "contain",
                        userSelect: "none",
                        pointerEvents: "none",
                    }}
                />
            )}
        </Box>
    );
};

interface VideoPlayerProps {
    file: EnteFile;
    onReady?: () => void;
    onDuration?: (durationSeconds: number) => void;
    onEnded?: () => void;
    paused?: boolean;
    fillFrame?: boolean;
    onAspectRatio?: (width: number, height: number) => void;
    showLoadingOverlay?: boolean;
}

const VideoPlayer: React.FC<VideoPlayerProps> = ({
    file,
    onReady,
    onDuration,
    onEnded,
    paused,
    fillFrame,
    onAspectRatio,
    showLoadingOverlay = true,
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

    useEffect(() => {
        let cancelled = false;
        setIsLoading(true);
        setError(false);
        setVideoURL(undefined);
        setHlsData(undefined);
        setThumbnailURL(undefined);

        const load = async () => {
            try {
                const thumbURL =
                    await downloadManager.renderableThumbnailURL(file);
                if (!cancelled && thumbURL) {
                    setThumbnailURL(thumbURL);
                }

                const hlsPlaylistData =
                    await downloadManager.hlsPlaylistDataForPublicMemory(file);
                if (
                    !cancelled &&
                    typeof hlsPlaylistData === "object" &&
                    hlsPlaylistData.playlistURL
                ) {
                    setHlsData(hlsPlaylistData);
                    return;
                }

                const sourceURLs: RenderableSourceURLs =
                    await downloadManager.renderableSourceURLs(file);
                if (!cancelled && sourceURLs.type === "video") {
                    setVideoURL(sourceURLs.videoURL);
                } else if (!cancelled) {
                    setIsLoading(false);
                }
            } catch (e) {
                log.error("Failed to load video", e);
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
        if (!video || (!videoURL && !hlsData)) return;

        if (paused) {
            video.pause();
        } else {
            video.play().catch(() => {
                // Autoplay may be blocked; ignore.
            });
        }
    }, [paused, videoURL, hlsData]);

    const handleLoadedMetadata = useCallback(() => {
        const video = videoRef.current;
        if (video && !isNaN(video.duration) && video.duration > 0) {
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
            {isLoading && showLoadingOverlay && (
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
                        width: fillFrame ? "100%" : "auto",
                        height: fillFrame ? "100%" : "auto",
                        maxWidth: fillFrame
                            ? "100%"
                            : DESKTOP_MEDIA_MAX_WIDTH_CSS,
                        maxHeight: fillFrame
                            ? "100%"
                            : DESKTOP_MEDIA_MAX_HEIGHT_CSS,
                        objectFit: "contain",
                        userSelect: "none",
                        pointerEvents: "none",
                    }}
                />
            )}

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
                        width: fillFrame ? "100%" : "auto",
                        height: fillFrame ? "100%" : "auto",
                        maxWidth: fillFrame
                            ? "100%"
                            : DESKTOP_MEDIA_MAX_WIDTH_CSS,
                        maxHeight: fillFrame
                            ? "100%"
                            : DESKTOP_MEDIA_MAX_HEIGHT_CSS,
                        objectFit: "contain",
                        userSelect: "none",
                        pointerEvents: "none",
                    }}
                />
            )}

            {!videoURL && !hlsData && thumbnailURL && (
                <img
                    src={thumbnailURL}
                    alt=""
                    style={{
                        display: "block",
                        width: fillFrame ? "100%" : "auto",
                        height: fillFrame ? "100%" : "auto",
                        maxWidth: fillFrame
                            ? "100%"
                            : DESKTOP_MEDIA_MAX_WIDTH_CSS,
                        maxHeight: fillFrame
                            ? "100%"
                            : DESKTOP_MEDIA_MAX_HEIGHT_CSS,
                        objectFit: "contain",
                        userSelect: "none",
                        pointerEvents: "none",
                    }}
                />
            )}
        </Box>
    );
};

/**
 * Format a date in the style "12th jan, 2022".
 */
const formatMemoryDate = (date: Date): string => {
    const day = date.getDate();
    const month = date.toLocaleString("en", { month: "short" }).toLowerCase();
    const year = date.getFullYear();
    const ordinal = getOrdinalSuffix(day);
    return `${day}${ordinal} ${month}, ${year}`;
};

const getOrdinalSuffix = (n: number): string => {
    const s = ["th", "st", "nd", "rd"];
    const v = n % 100;
    return s[(v - 20) % 10] || s[v] || s[0]!;
};
