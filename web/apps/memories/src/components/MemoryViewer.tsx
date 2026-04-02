import { keyframes } from "@emotion/react";
import { styled, Typography } from "@mui/material";
import { downloadManager } from "ente-gallery/services/download";
import { fileCreationPhotoDate } from "ente-media/file-metadata";
import { FileType } from "ente-media/file-type";
import {
    type MouseEvent as ReactMouseEvent,
    useCallback,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";
import { PlaybackGlyph, ProgressIndicator } from "./PublicMemoryControls";
import { PhotoImage, VideoPlayer } from "./PublicMemoryMedia";
import {
    BrandLink,
    EDGE_NAV_TAP_ZONE_RATIO,
    ENTE_BRAND_TAG_IMAGE_PATH,
    EnteBrandTagImage,
    HOLD_TO_PAUSE_NAV_SUPPRESSION_MS,
    IMAGE_AUTO_PROGRESS_DURATION_MS,
    isInteractiveTapTarget,
    JoinNowButton,
    type MemoryViewerProps,
    MOBILE_LAYOUT_BREAKPOINT_PX,
    MobileJoinNowButton,
    PhotoContainer,
    readViewport,
    ViewerFooterBar,
    ViewerRoot,
} from "./PublicMemoryViewerShared";

const SHARE_FOOTER_ACTIONS_BREAKPOINT_PX = 960;
const MOBILE_MEDIA_RESERVED_VERTICAL_SPACE_PX = 280;
const MOBILE_VIDEO_MEDIA_RESERVED_VERTICAL_SPACE_PX = 244;
const DESKTOP_MEDIA_MAX_WIDTH_PX = 1360;
const DESKTOP_MEDIA_HORIZONTAL_PADDING_PX = 32;
const DESKTOP_MEDIA_VERTICAL_RESERVED_PX = 184;
const MOBILE_VIDEO_MAX_WIDTH_PX = 344;
const MEDIA_SWITCH_TRANSITION_DURATION_MS = 380;
const DESKTOP_MEDIA_MAX_WIDTH_CSS = `min(${DESKTOP_MEDIA_MAX_WIDTH_PX}px, calc(100vw - ${DESKTOP_MEDIA_HORIZONTAL_PADDING_PX}px))`;
const DESKTOP_MEDIA_MAX_HEIGHT_CSS = `calc(min(100vh, 100dvh) - ${DESKTOP_MEDIA_VERTICAL_RESERVED_PX}px)`;
const DESKTOP_BACKGROUND_IMAGE_PATH = "/images/memory-lane-bg-desktop.svg";
const MOBILE_BACKGROUND_IMAGE_PATH = "/images/memory-lane-bg-mobile.svg";

interface SharedMemoryHeaderProps {
    title: string;
    total: number;
    current: number;
    paused: boolean;
    duration: number;
    onComplete: () => void;
    isVideo: boolean;
}

function SharedMemoryHeader({
    title,
    total,
    current,
    paused,
    duration,
    onComplete,
    isVideo,
}: SharedMemoryHeaderProps) {
    return (
        <HeaderSection>
            <MemoryTitle variant="h6">{title}</MemoryTitle>
            <ProgressIndicator
                total={total}
                current={current}
                paused={paused}
                duration={duration}
                onComplete={onComplete}
                isVideo={isVideo}
                minimal
            />
        </HeaderSection>
    );
}

export function MemoryViewer({
    files,
    currentIndex,
    memoryName,
    onNext,
    onPrev,
    onSeek,
}: MemoryViewerProps) {
    const currentFile = files[currentIndex]!;
    const [paused, setPaused] = useState(false);
    const [fileLoaded, setFileLoaded] = useState(false);
    const [videoDurationKnown, setVideoDurationKnown] = useState(false);
    const [progressDuration, setProgressDuration] = useState(
        IMAGE_AUTO_PROGRESS_DURATION_MS,
    );
    const [finishedPlayback, setFinishedPlayback] = useState(false);
    const [mediaAspectRatio, setMediaAspectRatio] = useState<number>();
    const [viewport, setViewport] = useState({ width: 1280, height: 720 });
    const [outgoingFile, setOutgoingFile] = useState<typeof currentFile | null>(
        null,
    );
    const [outgoingIsVideo, setOutgoingIsVideo] = useState(false);
    const [outgoingIndex, setOutgoingIndex] = useState<number | null>(null);
    const pressStartedAtRef = useRef<number | null>(null);
    const suppressTapNavigationRef = useRef(false);
    const previousFileRef = useRef(currentFile);
    const previousIndexRef = useRef(currentIndex);
    const outgoingClearTimeoutRef = useRef<number | null>(null);

    const isVideo = currentFile.metadata.fileType === FileType.video;
    const isMobileLayout = viewport.width <= MOBILE_LAYOUT_BREAKPOINT_PX;
    const useFooterShareActions =
        viewport.width <= SHARE_FOOTER_ACTIONS_BREAKPOINT_PX;

    useEffect(() => {
        setPaused(false);
        setFinishedPlayback(false);
        setFileLoaded(false);
        setVideoDurationKnown(false);
        setMediaAspectRatio(undefined);
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
        setProgressDuration(durationSeconds * 1000);
        setVideoDurationKnown(true);
    }, []);

    const handleMediaAspectRatio = useCallback(
        (width: number, height: number) => {
            if (width <= 0 || height <= 0) {
                return;
            }
            setMediaAspectRatio(width / height);
        },
        [],
    );

    const handleAdvanceOrFinish = useCallback(() => {
        if (currentIndex >= files.length - 1) {
            setFinishedPlayback(true);
            setPaused(true);
            return;
        }
        onNext();
    }, [currentIndex, files.length, onNext]);

    useEffect(() => {
        if (currentIndex < files.length - 1) {
            const nextFile = files[currentIndex + 1]!;
            void downloadManager.renderableThumbnailURL(nextFile);
        }
    }, [currentIndex, files]);

    useEffect(() => {
        const updateViewport = () => setViewport(readViewport());

        updateViewport();
        window.addEventListener("resize", updateViewport);
        window.visualViewport?.addEventListener("resize", updateViewport);
        return () => {
            window.removeEventListener("resize", updateViewport);
            window.visualViewport?.removeEventListener(
                "resize",
                updateViewport,
            );
        };
    }, []);

    const currentFileDate = useMemo(() => {
        try {
            return formatMemoryDate(fileCreationPhotoDate(currentFile));
        } catch {
            return "";
        }
    }, [currentFile]);

    const headerTitle = useMemo(() => {
        if (memoryName && currentFileDate) {
            return `${memoryName} • ${currentFileDate}`;
        }
        return memoryName || currentFileDate || "Memory";
    }, [currentFileDate, memoryName]);

    const handleScreenTap = useCallback(
        (event: ReactMouseEvent<HTMLDivElement>) => {
            if (suppressTapNavigationRef.current) {
                suppressTapNavigationRef.current = false;
                return;
            }
            if (isInteractiveTapTarget(event.target)) {
                return;
            }

            const clickX = event.clientX;
            if (clickX <= viewport.width * EDGE_NAV_TAP_ZONE_RATIO) {
                onPrev();
            } else if (
                clickX >=
                viewport.width * (1 - EDGE_NAV_TAP_ZONE_RATIO)
            ) {
                onNext();
            }
        },
        [onNext, onPrev, viewport.width],
    );

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
        const availableWidth = Math.max(
            220,
            viewport.width - (isVideo ? 32 : 48),
        );
        const maxWidth = Math.min(
            isVideo ? MOBILE_VIDEO_MAX_WIDTH_PX : 326,
            availableWidth,
        );
        const maxHeight = Math.max(
            180,
            viewport.height -
                (isVideo
                    ? MOBILE_VIDEO_MEDIA_RESERVED_VERTICAL_SPACE_PX
                    : MOBILE_MEDIA_RESERVED_VERTICAL_SPACE_PX),
        );
        const ratio = resolvedMediaAspectRatio ?? (isVideo ? 16 / 9 : 4 / 3);

        let width = maxWidth;
        let height = width / ratio;

        if (height > maxHeight) {
            height = maxHeight;
            width = height * ratio;
        }

        return { width: Math.round(width), height: Math.round(height) };
    }, [isVideo, resolvedMediaAspectRatio, viewport.height, viewport.width]);

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
              aspectRatio: `${resolvedMediaAspectRatio ?? (isVideo ? 16 / 9 : 4 / 3)}`,
          }
        : {
              width: `${desktopFrameSize.width}px`,
              aspectRatio: `${resolvedMediaAspectRatio ?? 4 / 3}`,
          };

    const isProgressPaused =
        paused || !fileLoaded || (isVideo && !videoDurationKnown);

    const sharedHeader = (
        <SharedMemoryHeader
            title={headerTitle}
            total={files.length}
            current={currentIndex}
            paused={isProgressPaused}
            duration={progressDuration}
            onComplete={handleAdvanceOrFinish}
            isVideo={isVideo}
        />
    );

    const mediaLayers = (
        <>
            <MediaSwitchLayer phase="in" key={`memory-file-${currentIndex}`}>
                {isVideo ? (
                    <VideoPlayer
                        file={currentFile}
                        onReady={handleFullLoad}
                        onDuration={handleVideoDuration}
                        onEnded={handleAdvanceOrFinish}
                        paused={paused}
                        fillFrame
                        objectFit="contain"
                        mediaAspectRatio={resolvedMediaAspectRatio}
                        onAspectRatio={handleMediaAspectRatio}
                    />
                ) : (
                    <PhotoImage
                        file={currentFile}
                        onFullLoad={handleFullLoad}
                        fillFrame
                        objectFit="contain"
                        mediaAspectRatio={resolvedMediaAspectRatio}
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
                            objectFit="contain"
                            showLoadingOverlay={false}
                        />
                    ) : (
                        <PhotoImage
                            file={outgoingFile}
                            fillFrame
                            objectFit="contain"
                            showLoadingOverlay={false}
                        />
                    )}
                </MediaSwitchLayer>
            )}
        </>
    );

    return (
        <ViewerRoot onClick={handleScreenTap}>
            <BackgroundPattern />
            <ContentContainer
                style={
                    isMobileLayout
                        ? {
                              maxWidth: "375px",
                              padding:
                                  "24px 24px calc(18px + env(safe-area-inset-bottom, 0px))",
                              gap: "14px",
                          }
                        : undefined
                }
            >
                {isMobileLayout ? (
                    sharedHeader
                ) : (
                    <TopControls>
                        <PlaybackControl
                            type="button"
                            onClick={(event) => {
                                event.stopPropagation();
                                if (finishedPlayback) {
                                    if (currentIndex > 0) {
                                        onSeek(0);
                                        return;
                                    }
                                    setFinishedPlayback(false);
                                    setPaused(false);
                                    return;
                                }
                                setPaused((state) => !state);
                            }}
                            aria-label={paused ? "Play" : "Pause"}
                            data-memory-control="true"
                        >
                            <PlaybackGlyph paused={paused} />
                        </PlaybackControl>

                        {sharedHeader}

                        {!useFooterShareActions && (
                            <TopRightActions>
                                <BrandLink
                                    href="https://ente.io"
                                    target="_blank"
                                    rel="noreferrer"
                                    data-memory-control="true"
                                >
                                    <EnteBrandTagImage
                                        src={ENTE_BRAND_TAG_IMAGE_PATH}
                                        alt="Ente Photos"
                                    />
                                </BrandLink>
                                <JoinNowButton
                                    href="https://ente.io"
                                    target="_blank"
                                    rel="noreferrer"
                                >
                                    Join now
                                </JoinNowButton>
                            </TopRightActions>
                        )}
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
                        {mediaLayers}
                    </MediaFrame>
                </PhotoContainer>

                {useFooterShareActions && (
                    <ViewerFooterBar>
                        <BrandLink
                            href="https://ente.io"
                            target="_blank"
                            rel="noreferrer"
                            data-memory-control="true"
                        >
                            <EnteBrandTagImage
                                src={ENTE_BRAND_TAG_IMAGE_PATH}
                                alt="Ente Photos"
                            />
                        </BrandLink>
                        <MobileJoinNowButton
                            href="https://ente.io"
                            target="_blank"
                            rel="noreferrer"
                        >
                            Join now
                        </MobileJoinNowButton>
                    </ViewerFooterBar>
                )}
            </ContentContainer>
        </ViewerRoot>
    );
}

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
    minHeight: "100svh",
    height: "100dvh",
    padding: "42px 24px 24px",
    boxSizing: "border-box",
});

const TopControls = styled("div")({
    position: "relative",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    minHeight: "64px",
    width: `${DESKTOP_MEDIA_MAX_WIDTH_PX}px`,
    maxWidth: "100%",
    boxSizing: "border-box",
    "@media (max-width: 900px)": { minHeight: "56px" },
});

const HeaderSection = styled("div")({
    width: "min(100%, 392px)",
    minWidth: 0,
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    gap: "18px",
    [`@media (max-width: ${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        paddingTop: "8px",
    },
});

const MemoryTitle = styled(Typography)({
    color: "rgba(255, 255, 255, 0.84)",
    fontWeight: 600,
    fontSize: "16px",
    lineHeight: 1.15,
    letterSpacing: "-0.01em",
    textAlign: "center",
    whiteSpace: "normal",
    overflowWrap: "anywhere",
    maxWidth: "100%",
    "@media (max-width: 900px)": { fontSize: "15px" },
    "@media (max-width: 700px)": { fontSize: "14px", lineHeight: 1.2 },
});

const PlaybackControl = styled("button")({
    position: "absolute",
    left: 0,
    top: "50%",
    transform: "translateY(-50%)",
    width: "56px",
    height: "56px",
    borderRadius: "16px",
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
        width: "52px",
        height: "52px",
        borderRadius: "15px",
    },
});

const TopRightActions = styled("div")({
    position: "absolute",
    right: 0,
    top: "50%",
    transform: "translateY(-50%)",
    display: "flex",
    alignItems: "center",
    gap: "16px",
    "@media (max-width: 900px)": { gap: "10px" },
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

function formatMemoryDate(date: Date): string {
    const day = date.getDate();
    const month = date.toLocaleString("en", { month: "short" });
    const year = date.getFullYear();
    const ordinal = getOrdinalSuffix(day);
    return `${day}${ordinal} ${month}, ${year}`;
}

function getOrdinalSuffix(value: number): string {
    const suffixes = ["th", "st", "nd", "rd"];
    const modulo = value % 100;
    return suffixes[(modulo - 20) % 10] || suffixes[modulo] || suffixes[0]!;
}
