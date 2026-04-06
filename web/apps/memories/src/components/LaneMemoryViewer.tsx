/**
 * Lane-style public memory viewer.
 * This file contains the stacked-card lane experience, including lane-specific
 * playback timing, scrubbing, captions, and decorative backgrounds. It is
 * rendered by `pages/index.tsx` for the `"lane"` variant.
 */
import { styled, Typography } from "@mui/material";
import log from "ente-base/log";
import { downloadManager } from "ente-gallery/services/download";
import { FileType } from "ente-media/file-type";
import {
    type MouseEvent as ReactMouseEvent,
    useCallback,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";
import {
    buildLaneCaptionModel,
    buildLaneTitle,
    calculateLaneBlur,
    calculateLaneOpacity,
    calculateLaneOverlayOpacity,
    calculateLaneRotation,
    calculateLaneScale,
    easeInOutCubic,
    getFileAspectRatio,
    getLaneStackSlices,
    laneCardShadow,
    lerp,
    resolveLaneCropRect,
} from "../utils/lane";
import {
    LaneCaptionText,
    LanePlaybackGlyph,
    LaneProgressSlider,
} from "./PublicMemoryControls";
import { PhotoImage, VideoPlayer } from "./PublicMemoryMedia";
import {
    BrandLink,
    EDGE_NAV_TAP_ZONE_RATIO,
    ENTE_BRAND_TAG_IMAGE_PATH,
    EnteBrandTagImage,
    isInteractiveTapTarget,
    JoinNowButton,
    type LaneMemoryViewerProps,
    MOBILE_LAYOUT_BREAKPOINT_PX,
    PhotoContainer,
    readViewport,
    ViewerRoot,
} from "./PublicMemoryViewerShared";

const LANE_FRAME_INTERVAL_MS = 1500;
const LANE_CARD_TRANSITION_DURATION_MS = 440;
const LANE_COMPACT_LAYOUT_BREAKPOINT_PX = 900;
const LANE_MOBILE_MEDIA_RESERVED_VERTICAL_SPACE_PX = 340;
const DESKTOP_LANE_MEDIA_VERTICAL_RESERVED_PX = 320;
const LANE_CARD_ASPECT_RATIO = 0.68;
const LANE_MOBILE_CARD_MAX_WIDTH_PX = 326;
const LANE_MOBILE_CARD_MIN_WIDTH_PX = 220;
const LANE_DESKTOP_CARD_MAX_WIDTH_PX = 420;
const LANE_DESKTOP_CARD_MIN_WIDTH_PX = 280;
const LANE_GRID_CELL_SIZE_PX = 80;
const LANE_GRID_LINE_COLOR = "#08c225";
const LANE_GRID_LINE_OPACITY = 0.06;
const LANE_GRID_DISPLACEMENT_SCALE = 9;
const LANE_VERTICAL_STACK_GAP_PX = 32;
const LANE_CARD_TO_CONTROLS_GAP_PX = 52;
const LANE_CARD_SIZE_SCALE = 0.94;

function calculateLaneXOffset(
    distance: number,
    cardWidth: number,
    viewportWidth: number,
): number {
    if (distance >= 0) {
        const compression = Math.pow(0.78, distance);
        return -cardWidth * 0.12 * distance * compression;
    }
    const sideways = Math.abs(distance);
    const exitDistance = Math.max(cardWidth * 1.8, viewportWidth * 0.82);
    const overshoot = Math.max(0, sideways - 1) * cardWidth * 0.4;
    return sideways * exitDistance + overshoot;
}

/**
 * Primary viewer for lane-style public memory shares.
 * Used by `pages/index.tsx` when `viewerVariant` resolves to `"lane"`.
 */
export function LaneMemoryViewer({
    files,
    currentIndex,
    memoryName,
    memoryMetadata,
    laneFrames,
    onNext,
    onPrev,
    onSeek,
}: LaneMemoryViewerProps) {
    const [paused, setPaused] = useState(false);
    const [fileLoaded, setFileLoaded] = useState(false);
    const [videoDurationKnown, setVideoDurationKnown] = useState(false);
    const [viewport, setViewport] = useState({ width: 1280, height: 720 });
    const [stackProgress, setStackProgress] = useState(currentIndex);
    const [displayIndex, setDisplayIndex] = useState(currentIndex);
    const [isScrubbing, setIsScrubbing] = useState(false);
    const [isAnimatingStack, setIsAnimatingStack] = useState(false);
    const [activeMediaAspectRatio, setActiveMediaAspectRatio] = useState<
        number | undefined
    >(undefined);
    const [previousCaptionValue, setPreviousCaptionValue] = useState<
        number | undefined
    >(() => {
        const initialModel = buildLaneCaptionModel({
            frame: laneFrames?.[currentIndex],
            metadata: memoryMetadata,
            fallbackLabel: memoryName || "Memory lane",
        });
        return initialModel.value;
    });
    const finishedLanePlaybackRef = useRef(false);
    const restartOnResumeRef = useRef(false);
    const animationFrameRef = useRef<number | null>(null);
    const animationStartTimestampRef = useRef<number | null>(null);
    const stackProgressRef = useRef(currentIndex);
    const displayIndexRef = useRef(currentIndex);
    const currentIndexRef = useRef(currentIndex);
    const pausedRef = useRef(paused);
    const wasPausedBeforeScrubRef = useRef(paused);
    const isVideoRef = useRef(false);
    const isAnimatingStackRef = useRef(false);
    const isScrubbingRef = useRef(false);
    const fileLoadedRef = useRef(false);
    const videoDurationKnownRef = useRef(false);
    const onNextRef = useRef(onNext);
    const laneAdvanceTimeoutRef = useRef<number | null>(null);
    const activeVideoElementRef = useRef<HTMLVideoElement | null>(null);

    const currentFile = files[displayIndex]!;
    const currentLaneFrame = laneFrames?.[displayIndex];
    const isVideo = currentFile.metadata.fileType === FileType.video;
    const isCompactLaneLayout =
        viewport.width <= LANE_COMPACT_LAYOUT_BREAKPOINT_PX;

    onNextRef.current = onNext;
    currentIndexRef.current = currentIndex;
    pausedRef.current = paused;
    stackProgressRef.current = stackProgress;
    displayIndexRef.current = displayIndex;
    isVideoRef.current = isVideo;
    isAnimatingStackRef.current = isAnimatingStack;
    isScrubbingRef.current = isScrubbing;
    fileLoadedRef.current = fileLoaded;
    videoDurationKnownRef.current = videoDurationKnown;

    const laneCaptionModel = buildLaneCaptionModel({
        frame: currentLaneFrame,
        metadata: memoryMetadata,
        fallbackLabel: memoryName || "Memory lane",
    });

    const cancelStackAnimation = useCallback(() => {
        if (animationFrameRef.current !== null) {
            window.cancelAnimationFrame(animationFrameRef.current);
            animationFrameRef.current = null;
        }
        animationStartTimestampRef.current = null;
        setIsAnimatingStack(false);
    }, []);

    const clearLaneAdvanceTimeout = useCallback(() => {
        if (laneAdvanceTimeoutRef.current !== null) {
            window.clearTimeout(laneAdvanceTimeoutRef.current);
            laneAdvanceTimeoutRef.current = null;
        }
    }, []);

    const scheduleLaneAdvance = useCallback(() => {
        clearLaneAdvanceTimeout();
        if (files.length <= 1 || pausedRef.current || isVideoRef.current) {
            return;
        }
        if (isScrubbingRef.current || isAnimatingStackRef.current) {
            return;
        }
        if (!fileLoadedRef.current) {
            return;
        }
        if (currentIndexRef.current >= files.length - 1) {
            return;
        }

        laneAdvanceTimeoutRef.current = window.setTimeout(() => {
            laneAdvanceTimeoutRef.current = null;
            onNextRef.current();
        }, LANE_FRAME_INTERVAL_MS);
    }, [clearLaneAdvanceTimeout, files.length]);

    const commitDisplayIndex = useCallback(
        (nextIndex: number) => {
            const previousModel = buildLaneCaptionModel({
                frame: laneFrames?.[displayIndexRef.current],
                metadata: memoryMetadata,
                fallbackLabel: memoryName || "Memory lane",
            });
            const nextModel = buildLaneCaptionModel({
                frame: laneFrames?.[nextIndex],
                metadata: memoryMetadata,
                fallbackLabel: memoryName || "Memory lane",
            });
            setPreviousCaptionValue(previousModel.value ?? nextModel.value);
            setFileLoaded(false);
            setVideoDurationKnown(false);
            setActiveMediaAspectRatio(undefined);
            setDisplayIndex(nextIndex);
        },
        [laneFrames, memoryMetadata, memoryName],
    );

    useEffect(
        () => () => {
            cancelStackAnimation();
            clearLaneAdvanceTimeout();
        },
        [cancelStackAnimation, clearLaneAdvanceTimeout],
    );

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

    useEffect(() => {
        if (isScrubbing) {
            return;
        }

        finishedLanePlaybackRef.current = false;

        const targetIndex = Math.min(
            Math.max(currentIndex, 0),
            files.length - 1,
        );
        const startProgress = stackProgressRef.current;
        cancelStackAnimation();

        if (Math.abs(targetIndex - startProgress) < 0.0001) {
            setStackProgress(targetIndex);
            if (displayIndexRef.current !== targetIndex) {
                commitDisplayIndex(targetIndex);
            }
            return;
        }

        const duration =
            LANE_CARD_TRANSITION_DURATION_MS *
            Math.min(Math.max(Math.abs(targetIndex - startProgress), 1), 4);
        setIsAnimatingStack(true);

        const tick = (timestamp: number) => {
            if (animationStartTimestampRef.current === null) {
                animationStartTimestampRef.current = timestamp;
            }
            const elapsed = timestamp - animationStartTimestampRef.current;
            const progress = Math.min(elapsed / duration, 1);
            const eased = easeInOutCubic(progress);
            setStackProgress(lerp(startProgress, targetIndex, eased));

            if (progress < 1) {
                animationFrameRef.current = window.requestAnimationFrame(tick);
                return;
            }

            animationFrameRef.current = null;
            animationStartTimestampRef.current = null;
            setIsAnimatingStack(false);
            setStackProgress(targetIndex);
            if (displayIndexRef.current !== targetIndex) {
                commitDisplayIndex(targetIndex);
            }
        };

        animationFrameRef.current = window.requestAnimationFrame(tick);
    }, [
        cancelStackAnimation,
        commitDisplayIndex,
        currentIndex,
        files.length,
        isScrubbing,
    ]);

    useEffect(() => {
        if (paused) {
            clearLaneAdvanceTimeout();
            activeVideoElementRef.current?.pause();
            return;
        }

        if (restartOnResumeRef.current) {
            restartOnResumeRef.current = false;
            if (currentIndexRef.current > 0) {
                onSeek(0);
                return;
            }

            const activeVideo = activeVideoElementRef.current;
            if (activeVideo) {
                activeVideo.currentTime = 0;
            }
        }

        if (isAnimatingStack || isScrubbing || !fileLoaded) {
            return;
        }

        if (isVideo) {
            const activeVideo = activeVideoElementRef.current;
            if (activeVideo) {
                void activeVideo.play().catch(() => {
                    // Browser playback policies may still reject here.
                });
            }
            return;
        }

        if (currentIndex >= files.length - 1) {
            clearLaneAdvanceTimeout();
            laneAdvanceTimeoutRef.current = window.setTimeout(() => {
                laneAdvanceTimeoutRef.current = null;
                finishedLanePlaybackRef.current = true;
                setPaused(true);
            }, LANE_FRAME_INTERVAL_MS);
            return clearLaneAdvanceTimeout;
        }

        scheduleLaneAdvance();
        return clearLaneAdvanceTimeout;
    }, [
        clearLaneAdvanceTimeout,
        currentIndex,
        fileLoaded,
        files.length,
        isAnimatingStack,
        isScrubbing,
        isVideo,
        onSeek,
        paused,
        scheduleLaneAdvance,
        videoDurationKnown,
    ]);

    const handleFullLoad = useCallback(() => {
        setFileLoaded(true);
    }, []);

    const handleVideoDuration = useCallback((durationSeconds: number) => {
        void durationSeconds;
        setVideoDurationKnown(true);
    }, []);

    useEffect(() => {
        if (!fileLoaded || displayIndex >= files.length - 1) {
            return;
        }

        const nextFile = files[displayIndex + 1]!;

        void (async () => {
            const prefetchTasks: Promise<unknown>[] = [
                downloadManager.renderableThumbnailURL(nextFile),
                downloadManager.renderableSourceURLs(nextFile),
            ];

            if (nextFile.metadata.fileType === FileType.video) {
                prefetchTasks.unshift(
                    downloadManager.hlsPlaylistDataForPublicMemory(nextFile),
                );
            }

            const results = await Promise.allSettled(prefetchTasks);
            results.forEach((result) => {
                if (result.status === "rejected") {
                    log.warn(
                        "Failed to prefetch next lane memory media",
                        result.reason,
                    );
                }
            });
        })();
    }, [displayIndex, fileLoaded, files]);

    const handleActiveAspectRatio = useCallback(
        (width: number, height: number) => {
            if (width <= 0 || height <= 0) {
                return;
            }
            setActiveMediaAspectRatio(width / height);
        },
        [],
    );

    const toggleLanePlayback = useCallback(() => {
        setPaused((previous) => {
            const nextPaused = !previous;
            restartOnResumeRef.current =
                !nextPaused && finishedLanePlaybackRef.current;
            if (!nextPaused) {
                finishedLanePlaybackRef.current = false;
            }
            return nextPaused;
        });
    }, []);

    const handlePlaybackToggle = useCallback(
        (event: ReactMouseEvent<HTMLButtonElement>) => {
            event.stopPropagation();
            toggleLanePlayback();
        },
        [toggleLanePlayback],
    );

    const handleVideoEnded = useCallback(() => {
        if (currentIndexRef.current >= files.length - 1) {
            finishedLanePlaybackRef.current = true;
            setPaused(true);
            return;
        }
        onNext();
    }, [files.length, onNext]);

    const handleScreenTap = useCallback(
        (event: ReactMouseEvent<HTMLDivElement>) => {
            if (isInteractiveTapTarget(event.target)) {
                return;
            }
            if (isAnimatingStackRef.current || isScrubbingRef.current) {
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

    const handleLaneMediaFrameClick = useCallback(
        (event: ReactMouseEvent<HTMLDivElement>) => {
            if (isInteractiveTapTarget(event.target)) {
                return;
            }
            if (isAnimatingStackRef.current || isScrubbingRef.current) {
                return;
            }

            event.stopPropagation();

            const clickX = event.clientX;
            if (clickX <= viewport.width * EDGE_NAV_TAP_ZONE_RATIO) {
                onPrev();
                return;
            }

            if (clickX >= viewport.width * (1 - EDGE_NAV_TAP_ZONE_RATIO)) {
                onNext();
                return;
            }

            toggleLanePlayback();
        },
        [onNext, onPrev, toggleLanePlayback, viewport.width],
    );

    const laneFrameSize = useMemo(() => {
        const availableWidth = Math.max(
            isCompactLaneLayout
                ? LANE_MOBILE_CARD_MIN_WIDTH_PX
                : LANE_DESKTOP_CARD_MIN_WIDTH_PX,
            viewport.width - (isCompactLaneLayout ? 56 : 96),
        );
        const availableHeight = Math.max(
            200,
            viewport.height -
                (isCompactLaneLayout
                    ? LANE_MOBILE_MEDIA_RESERVED_VERTICAL_SPACE_PX - 24
                    : DESKTOP_LANE_MEDIA_VERTICAL_RESERVED_PX),
        );
        const preferredWidth = isCompactLaneLayout
            ? Math.min(LANE_MOBILE_CARD_MAX_WIDTH_PX + 28, availableWidth)
            : Math.min(
                  LANE_DESKTOP_CARD_MAX_WIDTH_PX,
                  Math.max(
                      LANE_DESKTOP_CARD_MIN_WIDTH_PX,
                      availableWidth * 0.34,
                  ),
              );

        let width = preferredWidth;
        let height = width / LANE_CARD_ASPECT_RATIO;

        if (height > availableHeight) {
            height = availableHeight;
            width = height * LANE_CARD_ASPECT_RATIO;
        }

        width *= LANE_CARD_SIZE_SCALE;
        height *= LANE_CARD_SIZE_SCALE;

        return { width: Math.round(width), height: Math.round(height) };
    }, [isCompactLaneLayout, viewport.height, viewport.width]);

    const laneTitle = useMemo(
        () =>
            buildLaneTitle({
                memoryName,
                personName: memoryMetadata?.personName,
            }),
        [memoryMetadata?.personName, memoryName],
    );

    const laneSlices = useMemo(
        () => getLaneStackSlices(files.length, stackProgress),
        [files.length, stackProgress],
    );

    const trackScrubValue = useCallback(
        (value: number) => {
            if (files.length <= 1) {
                return 0;
            }
            return Math.min(Math.max(value, 0), files.length - 1);
        },
        [files.length],
    );

    const handleScrubStart = useCallback(() => {
        wasPausedBeforeScrubRef.current = pausedRef.current;
        setPaused(true);
        setIsScrubbing(true);
        cancelStackAnimation();
    }, [cancelStackAnimation]);

    const handleScrub = useCallback(
        (value: number) => {
            const clampedValue = trackScrubValue(value);
            const roundedIndex = Math.min(
                Math.max(Math.round(clampedValue), 0),
                files.length - 1,
            );
            setStackProgress(clampedValue);
            if (displayIndexRef.current !== roundedIndex) {
                commitDisplayIndex(roundedIndex);
            }
            onSeek(roundedIndex);
        },
        [commitDisplayIndex, files.length, onSeek, trackScrubValue],
    );

    const handleScrubEnd = useCallback(
        (value: number) => {
            const clampedValue = trackScrubValue(value);
            const roundedIndex = Math.min(
                Math.max(Math.round(clampedValue), 0),
                files.length - 1,
            );
            restartOnResumeRef.current = false;
            finishedLanePlaybackRef.current = false;
            setIsScrubbing(false);
            setPaused(wasPausedBeforeScrubRef.current);
            setStackProgress(roundedIndex);
            if (displayIndexRef.current !== roundedIndex) {
                commitDisplayIndex(roundedIndex);
            }
            onSeek(roundedIndex);
        },
        [commitDisplayIndex, files.length, onSeek, trackScrubValue],
    );

    const showPlaybackOverlay = paused && !isScrubbing;
    const playbackOverlayLabel = finishedLanePlaybackRef.current
        ? "Restart memory lane"
        : "Resume playback";

    return (
        <ViewerRoot onClick={handleScreenTap}>
            <LaneBackground isCompactLayout={isCompactLaneLayout} />
            <LaneContentContainer>
                <LaneTopBar>
                    <LaneTopBrandSection>
                        <LaneHeaderBrandLink
                            href="https://ente.io"
                            target="_blank"
                            rel="noreferrer"
                            data-memory-control="true"
                        >
                            <EnteBrandTagImage
                                src={ENTE_BRAND_TAG_IMAGE_PATH}
                                alt="Ente Photos"
                            />
                        </LaneHeaderBrandLink>
                    </LaneTopBrandSection>
                    <LaneTopActionSection>
                        <JoinNowButton
                            variant="contained"
                            color="accent"
                            disableElevation
                            href="https://ente.io/get"
                            target="_blank"
                            rel="noreferrer"
                            sx={laneHeaderJoinNowButtonSx}
                        >
                            Try Ente
                        </JoinNowButton>
                    </LaneTopActionSection>
                </LaneTopBar>

                <LaneCenterSection>
                    <LaneMediaSection>
                        <LaneSliderTitle variant="h6">
                            {laneTitle}
                        </LaneSliderTitle>
                        <PhotoContainer
                            style={{ flex: "0 0 auto", minHeight: "auto" }}
                            onContextMenu={(event) => event.preventDefault()}
                            onDragStart={(event) => event.preventDefault()}
                        >
                            <LaneCardStack
                                style={{
                                    width: `${laneFrameSize.width}px`,
                                    height: `${laneFrameSize.height}px`,
                                }}
                                onClick={handleLaneMediaFrameClick}
                            >
                                {laneSlices.map((slice) => {
                                    const file = files[slice.index]!;
                                    const frame = laneFrames?.[slice.index];
                                    const scale = calculateLaneScale(
                                        slice.distance,
                                    );
                                    const xOffset: number =
                                        calculateLaneXOffset(
                                            slice.distance,
                                            laneFrameSize.width,
                                            viewport.width,
                                        );
                                    const opacity = calculateLaneOpacity(
                                        slice.distance,
                                    );
                                    const blurSigma =
                                        isScrubbing || isCompactLaneLayout
                                            ? 0
                                            : calculateLaneBlur(slice.distance);
                                    const rotation =
                                        (calculateLaneRotation(slice.distance) *
                                            180) /
                                        Math.PI;
                                    const overlayOpacity =
                                        calculateLaneOverlayOpacity(
                                            slice.distance,
                                        );
                                    const cropRect = resolveLaneCropRect(frame);
                                    const containerAspectRatio =
                                        laneFrameSize.width /
                                        laneFrameSize.height;
                                    const isDisplayCard =
                                        slice.index === displayIndex;
                                    const prefersRichImage =
                                        file.metadata.fileType ===
                                        FileType.video
                                            ? isDisplayCard
                                            : Math.abs(slice.distance) < 1.1;
                                    const mediaAspectRatio = isDisplayCard
                                        ? (activeMediaAspectRatio ??
                                          getFileAspectRatio(file))
                                        : getFileAspectRatio(file);

                                    return (
                                        <LaneStackSlice
                                            key={`lane-slice-${slice.index}`}
                                            style={{
                                                opacity,
                                                transform: `translateX(${xOffset}px) rotate(${rotation}deg) scale(${scale})`,
                                            }}
                                        >
                                            <LaneCardSurface
                                                style={{
                                                    boxShadow: laneCardShadow(
                                                        slice.distance,
                                                    ),
                                                }}
                                            >
                                                <LaneCardMediaLayer
                                                    style={{
                                                        filter:
                                                            blurSigma > 0
                                                                ? `blur(${blurSigma}px)`
                                                                : undefined,
                                                    }}
                                                >
                                                    {file.metadata.fileType ===
                                                        FileType.video &&
                                                    isDisplayCard ? (
                                                        <VideoPlayer
                                                            file={file}
                                                            paused={paused}
                                                            mediaRef={
                                                                activeVideoElementRef
                                                            }
                                                            fillFrame
                                                            objectFit="cover"
                                                            cropRect={cropRect}
                                                            cropContainerAspectRatio={
                                                                containerAspectRatio
                                                            }
                                                            mediaAspectRatio={
                                                                mediaAspectRatio
                                                            }
                                                            onReady={
                                                                handleFullLoad
                                                            }
                                                            onDuration={
                                                                handleVideoDuration
                                                            }
                                                            onEnded={
                                                                handleVideoEnded
                                                            }
                                                            onAspectRatio={
                                                                handleActiveAspectRatio
                                                            }
                                                        />
                                                    ) : (
                                                        <PhotoImage
                                                            file={file}
                                                            fillFrame
                                                            objectFit="cover"
                                                            cropRect={cropRect}
                                                            cropContainerAspectRatio={
                                                                containerAspectRatio
                                                            }
                                                            mediaAspectRatio={
                                                                mediaAspectRatio
                                                            }
                                                            onFullLoad={
                                                                isDisplayCard
                                                                    ? handleFullLoad
                                                                    : undefined
                                                            }
                                                            onAspectRatio={
                                                                isDisplayCard
                                                                    ? handleActiveAspectRatio
                                                                    : undefined
                                                            }
                                                            showLoadingOverlay={
                                                                false
                                                            }
                                                            thumbnailOnly={
                                                                !prefersRichImage
                                                            }
                                                        />
                                                    )}
                                                </LaneCardMediaLayer>
                                                {overlayOpacity > 0 && (
                                                    <LaneCardOverlayLayer
                                                        style={{
                                                            opacity:
                                                                overlayOpacity,
                                                        }}
                                                    />
                                                )}
                                            </LaneCardSurface>
                                        </LaneStackSlice>
                                    );
                                })}
                                {showPlaybackOverlay && (
                                    <LaneCornerPlaybackOverlay>
                                        <LaneCornerPlaybackControl
                                            type="button"
                                            onClick={handlePlaybackToggle}
                                            aria-label={playbackOverlayLabel}
                                            data-memory-control="true"
                                        >
                                            <LaneCornerPlaybackGlyph>
                                                <LanePlaybackGlyph
                                                    paused={paused}
                                                />
                                            </LaneCornerPlaybackGlyph>
                                        </LaneCornerPlaybackControl>
                                    </LaneCornerPlaybackOverlay>
                                )}
                            </LaneCardStack>
                        </PhotoContainer>
                    </LaneMediaSection>

                    <LaneBottomSection>
                        <LaneSliderMetaStack>
                            <LaneProgressSlider
                                total={files.length}
                                currentProgress={stackProgress}
                                width={laneFrameSize.width}
                                onSeek={onSeek}
                                onScrubStart={handleScrubStart}
                                onScrub={handleScrub}
                                onScrubEnd={handleScrubEnd}
                            />
                            <LaneCaptionRow>
                                <LaneCaption>
                                    <LaneCaptionText
                                        model={laneCaptionModel}
                                        previousValue={previousCaptionValue}
                                    />
                                </LaneCaption>
                            </LaneCaptionRow>
                        </LaneSliderMetaStack>
                    </LaneBottomSection>
                </LaneCenterSection>
            </LaneContentContainer>
        </ViewerRoot>
    );
}

const LaneDesktopBackgroundPattern = styled("div")({
    position: "fixed",
    inset: 0,
    overflow: "hidden",
    backgroundColor: "#000000",
    zIndex: 1,
    pointerEvents: "none",
    "&::before": {
        content: '""',
        position: "absolute",
        inset: 0,
        background: [
            "radial-gradient(ellipse 102% 138% at 50% 60%, rgba(7, 102, 81, 0.36) 0%, rgba(6, 86, 73, 0.28) 32%, rgba(4, 60, 59, 0.17) 54%, rgba(2, 33, 35, 0.08) 76%, transparent 100%)",
            "radial-gradient(ellipse 82% 120% at 50% 60%, rgba(8, 123, 91, 0.5) 0%, rgba(7, 104, 83, 0.38) 30%, rgba(5, 78, 69, 0.24) 52%, rgba(3, 48, 48, 0.11) 74%, transparent 100%)",
            "radial-gradient(ellipse 56% 86% at 50% 60%, rgba(10, 133, 95, 0.24) 0%, rgba(7, 103, 82, 0.14) 42%, transparent 100%)",
        ].join(", "),
    },
    "&::after": {
        content: '""',
        position: "absolute",
        inset: 0,
        background: [
            "linear-gradient(180deg, rgba(0, 0, 0, 0.98) 0%, rgba(0, 0, 0, 0.62) 14%, rgba(0, 0, 0, 0.14) 32%, rgba(0, 0, 0, 0.10) 68%, rgba(0, 0, 0, 0.62) 88%, rgba(0, 0, 0, 0.98) 100%)",
            "radial-gradient(ellipse 62% 30% at 50% 9%, rgba(28, 51, 96, 0.26) 0%, rgba(13, 23, 48, 0.18) 42%, transparent 100%)",
            "radial-gradient(ellipse 124% 132% at 50% 58%, transparent 24%, rgba(0, 0, 0, 0.18) 48%, rgba(0, 0, 0, 0.86) 100%)",
        ].join(", "),
    },
});

const LaneDesktopBackgroundAtmosphere = styled("div")({
    position: "absolute",
    inset: "-6% 0 34%",
    background:
        "repeating-linear-gradient(90deg, rgba(34, 60, 112, 0.12) 0px, rgba(34, 60, 112, 0.12) 20px, transparent 20px, transparent 94px)",
    opacity: 0.11,
    filter: "blur(26px)",
    maskImage:
        "linear-gradient(180deg, rgba(0, 0, 0, 0.98) 0%, rgba(0, 0, 0, 0.86) 18%, rgba(0, 0, 0, 0.30) 50%, transparent 100%)",
});

const LaneDesktopBackgroundGrid = styled("svg")({
    position: "absolute",
    inset: 0,
    width: "100%",
    height: "100%",
    maskImage:
        "radial-gradient(ellipse 82% 84% at 50% 56%, rgba(0, 0, 0, 0.9) 0%, rgba(0, 0, 0, 0.74) 44%, rgba(0, 0, 0, 0.32) 72%, transparent 100%)",
});

/**
 * Shared SVG pattern definition for the lane background grids.
 * Used by both desktop and mobile lane background overlays in this file.
 */
function LaneBackgroundGridFill({
    patternId,
    filterId,
}: {
    patternId: string;
    filterId: string;
}) {
    return (
        <>
            <defs>
                <pattern
                    id={patternId}
                    width={LANE_GRID_CELL_SIZE_PX}
                    height={LANE_GRID_CELL_SIZE_PX}
                    patternUnits="userSpaceOnUse"
                >
                    <rect
                        width={LANE_GRID_CELL_SIZE_PX}
                        height="1"
                        fill={LANE_GRID_LINE_COLOR}
                        fillOpacity={LANE_GRID_LINE_OPACITY}
                    />
                    <rect
                        width="1"
                        height={LANE_GRID_CELL_SIZE_PX}
                        fill={LANE_GRID_LINE_COLOR}
                        fillOpacity={LANE_GRID_LINE_OPACITY}
                    />
                </pattern>
                <filter
                    id={filterId}
                    x="-6%"
                    y="-6%"
                    width="112%"
                    height="112%"
                    colorInterpolationFilters="sRGB"
                >
                    <feTurbulence
                        type="turbulence"
                        baseFrequency="0.009"
                        numOctaves="3"
                        seed="3"
                        result="laneGridNoise"
                    />
                    <feDisplacementMap
                        in="SourceGraphic"
                        in2="laneGridNoise"
                        scale={LANE_GRID_DISPLACEMENT_SCALE}
                        xChannelSelector="R"
                        yChannelSelector="G"
                    />
                </filter>
            </defs>
            <rect
                width="100%"
                height="100%"
                fill={`url(#${patternId})`}
                filter={`url(#${filterId})`}
            />
        </>
    );
}

/**
 * Desktop lane background grid overlay.
 * Used by `LaneBackground` for the non-compact layout branch.
 */
function LaneDesktopBackgroundGridOverlay() {
    return (
        <LaneDesktopBackgroundGrid aria-hidden preserveAspectRatio="none">
            <LaneBackgroundGridFill
                patternId="lane-desktop-grid-pattern"
                filterId="lane-desktop-grid-filter"
            />
        </LaneDesktopBackgroundGrid>
    );
}

const LaneMobileBackgroundPattern = styled("div")({
    position: "fixed",
    inset: 0,
    overflow: "hidden",
    backgroundColor: "#000000",
    zIndex: 1,
    pointerEvents: "none",
    "&::before": {
        content: '""',
        position: "absolute",
        inset: 0,
        background: [
            "linear-gradient(180deg, rgba(8, 37, 32, 0.96) 0%, rgba(19, 78, 59, 0.88) 16%, rgba(46, 95, 95, 0.94) 50%, rgba(16, 70, 64, 0.88) 72%, rgba(5, 47, 34, 0.94) 100%)",
            "radial-gradient(ellipse 82% 26% at 50% 16%, rgba(24, 120, 80, 0.42) 0%, rgba(14, 80, 58, 0.24) 46%, transparent 100%)",
            "radial-gradient(ellipse 100% 34% at 50% 54%, rgba(76, 123, 145, 0.38) 0%, rgba(43, 90, 107, 0.22) 42%, transparent 100%)",
            "radial-gradient(ellipse 84% 28% at 50% 86%, rgba(18, 96, 54, 0.34) 0%, rgba(9, 58, 39, 0.18) 46%, transparent 100%)",
        ].join(", "),
    },
    "&::after": {
        content: '""',
        position: "absolute",
        inset: 0,
        background: [
            "linear-gradient(180deg, rgba(0, 0, 0, 0.96) 0%, rgba(0, 0, 0, 0.34) 12%, rgba(0, 0, 0, 0.08) 24%, rgba(0, 0, 0, 0.10) 48%, rgba(0, 0, 0, 0.16) 68%, rgba(0, 0, 0, 0.46) 88%, rgba(0, 0, 0, 0.96) 100%)",
            "linear-gradient(90deg, rgba(0, 0, 0, 0.94) 0%, rgba(0, 0, 0, 0.52) 16%, rgba(0, 0, 0, 0.14) 32%, rgba(0, 0, 0, 0.14) 68%, rgba(0, 0, 0, 0.52) 84%, rgba(0, 0, 0, 0.94) 100%)",
        ].join(", "),
    },
});

const LaneMobileBackgroundGrid = styled("svg")({
    position: "absolute",
    inset: 0,
    width: "100%",
    height: "100%",
    maskImage:
        "linear-gradient(180deg, rgba(0, 0, 0, 0.96) 0%, rgba(0, 0, 0, 0.78) 10%, rgba(0, 0, 0, 0.42) 24%, rgba(0, 0, 0, 0.30) 52%, rgba(0, 0, 0, 0.52) 76%, rgba(0, 0, 0, 0.92) 100%)",
});

/**
 * Mobile lane background grid overlay.
 * Used by `LaneBackground` for the compact layout branch.
 */
function LaneMobileBackgroundGridOverlay() {
    return (
        <LaneMobileBackgroundGrid aria-hidden preserveAspectRatio="none">
            <LaneBackgroundGridFill
                patternId="lane-mobile-grid-pattern"
                filterId="lane-mobile-grid-filter"
            />
        </LaneMobileBackgroundGrid>
    );
}

/**
 * Chooses the correct decorative background for the lane viewer.
 * Used only by `LaneMemoryViewer`.
 */
function LaneBackground({
    isCompactLayout = false,
}: {
    isCompactLayout?: boolean;
}) {
    return isCompactLayout ? (
        <LaneMobileBackgroundPattern>
            <LaneMobileBackgroundGridOverlay />
        </LaneMobileBackgroundPattern>
    ) : (
        <LaneDesktopBackgroundPattern>
            <LaneDesktopBackgroundAtmosphere />
            <LaneDesktopBackgroundGridOverlay />
        </LaneDesktopBackgroundPattern>
    );
}

const LaneContentContainer = styled("div")({
    position: "relative",
    zIndex: 2,
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    gap: "26px",
    width: "100%",
    maxWidth: "1360px",
    minHeight: "100svh",
    height: "100dvh",
    padding: "42px 24px 24px",
    boxSizing: "border-box",
    "@media (max-width: 900px)": { gap: "22px", padding: "36px 24px 24px" },
    [`@media (max-width: ${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        gap: "18px",
        padding: "32px 24px calc(18px + env(safe-area-inset-bottom, 0px))",
    },
});

const LaneTopBar = styled("div")({
    width: "100%",
    maxWidth: "100%",
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    minHeight: "64px",
    gap: "20px",
    boxSizing: "border-box",
    "@media (max-width: 900px)": { minHeight: "56px", gap: "14px" },
    [`@media (max-width: ${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        minHeight: "48px",
        gap: "12px",
    },
});

const LaneTopBrandSection = styled("div")({
    display: "flex",
    alignItems: "center",
    gap: "12px",
});

const LaneHeaderBrandLink = styled(BrandLink)({
    "& img": { width: "98px" },
    "@media (max-width: 900px)": { "& img": { width: "84px" } },
    [`@media (max-width: ${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        "& img": { width: "72px" },
    },
});

const LaneTopActionSection = styled("div")({
    display: "flex",
    alignItems: "center",
});

const laneHeaderJoinNowButtonSx = {
    fontSize: "17px",
    paddingBlock: "14px",
    paddingInline: "30px",
    "@media (max-width: 900px)": {
        fontSize: "15px",
        paddingBlock: "11px",
        paddingInline: "22px",
    },
    [`@media (max-width: ${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        borderRadius: "14px",
        fontSize: "14px",
        paddingBlock: "9px",
        paddingInline: "18px",
        minWidth: "auto",
    },
} as const;

const LaneSliderTitle = styled(Typography)({
    color: "rgba(255, 255, 255, 0.42)",
    fontWeight: 600,
    fontSize: "24px",
    lineHeight: 1.15,
    letterSpacing: "-0.01em",
    textAlign: "center",
    paddingBottom: "10px",
    whiteSpace: "normal",
    overflowWrap: "anywhere",
    maxWidth: "min(42vw, 420px)",
    "@media (max-width: 900px)": {
        fontSize: "21px",
        paddingBottom: "8px",
        maxWidth: "min(56vw, 360px)",
    },
    [`@media (max-width: ${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        fontSize: "18px",
        lineHeight: 1.2,
        paddingBottom: "6px",
        maxWidth: "min(100%, 280px)",
    },
});

const LaneCenterSection = styled("div")({
    width: "100%",
    flex: 1,
    minHeight: 0,
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
    gap: `${LANE_CARD_TO_CONTROLS_GAP_PX}px`,
    transform: "translateY(-28px)",
    "@media (max-width: 900px)": { transform: "translateY(0)" },
});

const LaneMediaSection = styled("div")({
    width: "100%",
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    gap: "26px",
    "@media (max-width: 900px)": { gap: "22px" },
    [`@media (max-width: ${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: { gap: "18px" },
});

const LaneCardStack = styled("div")({ position: "relative", flexShrink: 0 });

const LaneStackSlice = styled("div")({
    position: "absolute",
    inset: 0,
    pointerEvents: "none",
    willChange: "transform, opacity",
});

const LaneCardSurface = styled("div")({
    position: "relative",
    width: "100%",
    height: "100%",
    overflow: "hidden",
    borderRadius: "28px",
    border: "3px solid white",
    boxSizing: "border-box",
    backgroundColor: "black",
    "@media (max-width: 900px)": { borderRadius: "24px" },
    [`@media (max-width: ${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        borderRadius: "22px",
        borderWidth: "2px",
    },
});

const LaneCardMediaLayer = styled("div")({
    position: "absolute",
    inset: 0,
    overflow: "hidden",
    borderRadius: "inherit",
});

const LaneCardOverlayLayer = styled("div")({
    position: "absolute",
    inset: 0,
    borderRadius: "inherit",
    backgroundColor: "rgba(0, 0, 0, 1)",
});

const LaneBottomSection = styled("div")({
    position: "relative",
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "flex-end",
    gap: `${LANE_VERTICAL_STACK_GAP_PX}px`,
    width: "100%",
    paddingBottom: 0,
});

const LaneSliderMetaStack = styled("div")({
    width: "100%",
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    gap: `${LANE_VERTICAL_STACK_GAP_PX}px`,
});

const LaneCaptionRow = styled("div")({
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    width: "100%",
});

const LaneCaption = styled("div")({
    color: "rgba(255, 255, 255, 0.53)",
    fontWeight: 600,
    fontSize: "24px",
    letterSpacing: "-0.01em",
    lineHeight: 1.15,
    textAlign: "center",
    whiteSpace: "normal",
    overflowWrap: "anywhere",
    "@media (max-width: 900px)": { fontSize: "21px" },
    [`@media (max-width: ${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        fontSize: "18px",
        lineHeight: 1.2,
    },
});

const LaneCornerPlaybackOverlay = styled("div")({
    position: "absolute",
    inset: 0,
    zIndex: 4,
    display: "flex",
    alignItems: "flex-end",
    justifyContent: "flex-end",
    padding: "20px",
    pointerEvents: "none",
    "@media (max-width: 900px)": { padding: "18px" },
    [`@media (max-width: ${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        padding: "14px",
    },
});

const LaneCornerPlaybackControl = styled("button")({
    width: "58px",
    height: "58px",
    borderRadius: "999px",
    border: 0,
    cursor: "pointer",
    padding: 0,
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    color: "white",
    backgroundColor: "rgba(18, 18, 18, 0.64)",
    boxShadow: "0 18px 40px rgba(0, 0, 0, 0.34)",
    backdropFilter: "blur(10px)",
    WebkitBackdropFilter: "blur(10px)",
    transition:
        "transform 150ms ease, background-color 150ms ease, box-shadow 150ms ease",
    pointerEvents: "auto",
    "&:hover": {
        backgroundColor: "rgba(18, 18, 18, 0.72)",
        transform: "scale(1.03)",
    },
    "&:active": { transform: "scale(0.98)" },
    "@media (max-width: 900px)": { width: "54px", height: "54px" },
    [`@media (max-width: ${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        width: "48px",
        height: "48px",
    },
});

const LaneCornerPlaybackGlyph = styled("span")({
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    transform: "scale(1.55)",
    transformOrigin: "center",
    [`@media (max-width: ${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        transform: "scale(1.35)",
    },
});
