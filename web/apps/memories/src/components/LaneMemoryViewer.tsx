import { styled, useMediaQuery } from "@mui/material";
import log from "ente-base/log";
import { downloadManager } from "ente-gallery/services/download";
import { FileType } from "ente-media/file-type";
import {
    type MouseEvent as ReactMouseEvent,
    type PointerEvent as ReactPointerEvent,
    useCallback,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";
import {
    buildLaneCaptionModel,
    buildLaneTitle,
    easeInOutCubic,
    getFileAspectRatio,
    getLaneStackSlices,
    lerp,
    resolveLaneCropRect,
} from "../utils/lane";
import { LaneCaption } from "./LaneCaption";
import { LaneTimeline } from "./LaneTimeline";
import { PlaybackGlyph } from "./PublicMemoryControls";
import { PhotoImage, VideoPlayer } from "./PublicMemoryMedia";
import {
    BrandLink,
    ENTE_BRAND_TAG_IMAGE_PATH,
    EnteBrandTagImage,
    isInteractiveTapTarget,
    JoinNowButton,
    type LaneMemoryViewerProps,
    MOBILE_LAYOUT_BREAKPOINT_PX,
    readViewport,
} from "./PublicMemoryViewerShared";

const LANE_PLAYBACK_SPEED_MULTIPLIER = 1.25;
const LANE_FRAME_INTERVAL_MS = 1000;
const LANE_MEDIA_ASPECT_RATIO_CHANGE_EPSILON = 0.00001;

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
    const [mediaAspectRatios, setMediaAspectRatios] = useState<
        Record<number, number>
    >({});
    const reducedMotion = useMediaQuery("(prefers-reduced-motion: reduce)");
    const transitionDurationRef = useRef(100);
    const heldPointerRef = useRef<
        { id: number; started: number; paused: boolean } | undefined
    >(undefined);
    const suppressTapRef = useRef(false);
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
            transitionDurationRef.current = 1000;
            onNextRef.current();
        }, LANE_FRAME_INTERVAL_MS);
    }, [clearLaneAdvanceTimeout, files.length]);

    const commitDisplayIndex = useCallback((nextIndex: number) => {
        if (displayIndexRef.current === nextIndex) return;
        finishedLanePlaybackRef.current = false;
        setFileLoaded(false);
        setVideoDurationKnown(false);
        setActiveMediaAspectRatio(undefined);
        setDisplayIndex(nextIndex);
    }, []);

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

        if (reducedMotion || Math.abs(targetIndex - startProgress) > 1) {
            setStackProgress(targetIndex);
            commitDisplayIndex(targetIndex);
            transitionDurationRef.current = 100;
            return;
        }
        const duration = transitionDurationRef.current;
        transitionDurationRef.current = 100;
        commitDisplayIndex(targetIndex);
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
        reducedMotion,
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

    useEffect(() => {
        const activeVideo = activeVideoElementRef.current;
        if (!activeVideo || !isVideo) {
            return;
        }

        activeVideo.defaultPlaybackRate = LANE_PLAYBACK_SPEED_MULTIPLIER;
        activeVideo.playbackRate = LANE_PLAYBACK_SPEED_MULTIPLIER;
    }, [displayIndex, isVideo]);

    const handleFullLoad = useCallback(() => {
        setFileLoaded(true);
    }, []);

    const handleVideoDuration = useCallback((durationSeconds: number) => {
        void durationSeconds;
        setVideoDurationKnown(true);
    }, []);

    const handleVideoPlaybackBlocked = useCallback(() => {
        finishedLanePlaybackRef.current = false;
        setPaused(true);
    }, []);

    useEffect(() => {
        if (!fileLoaded || displayIndex >= files.length - 1) {
            return;
        }

        const nextFile = files[displayIndex + 1]!;

        void (async () => {
            const prefetchTasks: Promise<unknown>[] = [
                downloadManager.renderableThumbnailURL(nextFile),
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

    const handleMediaAspectRatio = useCallback(
        (fileID: number, width: number, height: number) => {
            if (width <= 0 || height <= 0) {
                return;
            }

            const nextAspectRatio = width / height;
            setMediaAspectRatios((previousAspectRatios) => {
                const previousAspectRatio = previousAspectRatios[fileID];
                if (
                    typeof previousAspectRatio === "number" &&
                    Math.abs(previousAspectRatio - nextAspectRatio) <
                        LANE_MEDIA_ASPECT_RATIO_CHANGE_EPSILON
                ) {
                    return previousAspectRatios;
                }

                return { ...previousAspectRatios, [fileID]: nextAspectRatio };
            });
        },
        [],
    );

    const handleActiveAspectRatio = useCallback(
        (width: number, height: number) => {
            if (width <= 0 || height <= 0) {
                return;
            }
            setActiveMediaAspectRatio(width / height);
        },
        [],
    );

    const resumeLanePlaybackFromGesture = useCallback(() => {
        setPaused(false);

        if (finishedLanePlaybackRef.current) {
            finishedLanePlaybackRef.current = false;
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

        if (!isVideoRef.current || isAnimatingStackRef.current) {
            return;
        }

        const activeVideo = activeVideoElementRef.current;
        if (!activeVideo) {
            return;
        }

        activeVideo.defaultPlaybackRate = LANE_PLAYBACK_SPEED_MULTIPLIER;
        activeVideo.playbackRate = LANE_PLAYBACK_SPEED_MULTIPLIER;
        activeVideo.muted = false;
        void activeVideo.play().catch((error: unknown) => {
            log.warn(
                "Failed to start lane memory video playback from user gesture",
                error,
            );
            handleVideoPlaybackBlocked();
        });
    }, [handleVideoPlaybackBlocked, onSeek]);

    const pauseLanePlayback = useCallback(() => {
        setPaused(true);
    }, []);

    const handlePlaybackToggle = useCallback(
        (event: ReactMouseEvent<HTMLButtonElement>) => {
            event.stopPropagation();
            if (pausedRef.current) {
                resumeLanePlaybackFromGesture();
            } else {
                pauseLanePlayback();
            }
        },
        [pauseLanePlayback, resumeLanePlaybackFromGesture],
    );

    const handleVideoEnded = useCallback(() => {
        if (currentIndexRef.current >= files.length - 1) {
            finishedLanePlaybackRef.current = true;
            setPaused(true);
            return;
        }
        transitionDurationRef.current = 1000;
        onNext();
    }, [files.length, onNext]);

    useEffect(() => {
        const handleKeyDown = (event: KeyboardEvent) => {
            if (
                event.defaultPrevented ||
                isInteractiveTapTarget(event.target) ||
                event.altKey ||
                event.ctrlKey ||
                event.metaKey
            )
                return;
            if (event.code === "Space") {
                event.preventDefault();
                if (pausedRef.current) resumeLanePlaybackFromGesture();
                else pauseLanePlayback();
            } else if (event.key === "Home") {
                event.preventDefault();
                onSeek(0);
            } else if (event.key === "End") {
                event.preventDefault();
                onSeek(files.length - 1);
            }
        };
        window.addEventListener("keydown", handleKeyDown);
        return () => window.removeEventListener("keydown", handleKeyDown);
    }, [
        files.length,
        onSeek,
        pauseLanePlayback,
        resumeLanePlaybackFromGesture,
    ]);

    const handleHoldStart = (event: ReactPointerEvent<HTMLDivElement>) => {
        if (event.button !== 0 || heldPointerRef.current) return;
        suppressTapRef.current = false;
        heldPointerRef.current = {
            id: event.pointerId,
            started: performance.now(),
            paused: pausedRef.current,
        };
        event.currentTarget.setPointerCapture(event.pointerId);
        setPaused(true);
    };
    const handleHoldEnd = (event: ReactPointerEvent<HTMLDivElement>) => {
        const held = heldPointerRef.current;
        if (held?.id !== event.pointerId) return;
        heldPointerRef.current = undefined;
        suppressTapRef.current = performance.now() - held.started > 300;
        setPaused(held.paused);
    };

    const handlePhotoTap = useCallback(
        (event: ReactMouseEvent<HTMLDivElement>) => {
            if (
                suppressTapRef.current ||
                isInteractiveTapTarget(event.target) ||
                isScrubbingRef.current
            )
                return;
            const rect = event.currentTarget.getBoundingClientRect();
            if (event.clientX - rect.left < rect.width / 2) onPrev();
            else onNext();
        },
        [onNext, onPrev],
    );

    const laneFrameSize = useMemo(() => {
        if (viewport.height <= 500 && viewport.width >= 480) {
            const width = Math.max(
                100,
                Math.min(
                    viewport.width * 0.5 - 60,
                    (viewport.height - 112) * 0.75,
                ),
            );
            return { width, height: width / 0.75 };
        }
        const width = Math.max(
            100,
            Math.min(
                viewport.width * 0.84,
                480,
                Math.max(120, viewport.height - 360) * 0.75,
            ),
        );
        return { width, height: width / 0.75 };
    }, [viewport.height, viewport.width]);

    const laneTitle = useMemo(
        () =>
            buildLaneTitle({
                memoryName,
                personName: memoryMetadata?.personName,
            }),
        [memoryMetadata?.personName, memoryName],
    );

    const laneTitleLines = useMemo(() => {
        const name = memoryMetadata?.personName?.trim();
        if (
            name &&
            laneTitle.startsWith(name) &&
            !laneTitle.includes(name, name.length)
        ) {
            const suffix = /^(\S*)\s+(.+)$/u.exec(laneTitle.slice(name.length));
            if (suffix) {
                return { primary: name + suffix[1]!, secondary: suffix[2] };
            }
        }
        return { primary: laneTitle, secondary: undefined };
    }, [laneTitle, memoryMetadata?.personName]);

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
        },
        [commitDisplayIndex, files.length, trackScrubValue],
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
            if (currentIndexRef.current !== roundedIndex) {
                onSeek(roundedIndex);
            }
        },
        [commitDisplayIndex, files.length, onSeek, trackScrubValue],
    );

    const visibleSlices = laneSlices.filter(
        (slice) => Math.abs(slice.distance) <= 1,
    );

    return (
        <LaneRoot>
            <LaneBackdrop aria-hidden="true">
                {visibleSlices.map((slice) => (
                    <LaneBackdropImage
                        key={slice.index}
                        style={{ opacity: 1 - Math.abs(slice.distance) }}
                    >
                        <PhotoImage
                            file={files[slice.index]!}
                            fillFrame
                            objectFit="cover"
                            thumbnailOnly
                            showLoadingOverlay={false}
                        />
                    </LaneBackdropImage>
                ))}
            </LaneBackdrop>
            <LaneContent>
                <LaneHeader>
                    <LaneHeaderBrandLink
                        href="https://ente.com"
                        target="_blank"
                        rel="noopener"
                        aria-label="Ente Photos"
                    >
                        <EnteBrandTagImage
                            src={ENTE_BRAND_TAG_IMAGE_PATH}
                            alt="Ente Photos"
                        />
                    </LaneHeaderBrandLink>
                    <JoinNowButton
                        variant="contained"
                        color="accent"
                        disableElevation
                        href="https://ente.com/try"
                        target="_blank"
                        rel="noopener"
                        sx={laneHeaderJoinNowButtonSx}
                    >
                        Get Ente Photos
                    </JoinNowButton>
                </LaneHeader>
                <LaneMediaSection>
                    <LaneHeading
                        className="lane-heading"
                        dir="auto"
                        aria-label={laneTitle}
                    >
                        <LaneTitlePrimary>
                            {laneTitleLines.primary}
                        </LaneTitlePrimary>
                        {laneTitleLines.secondary && (
                            <LaneTitleSecondary>
                                {laneTitleLines.secondary}
                            </LaneTitleSecondary>
                        )}
                    </LaneHeading>
                    <LaneStage className="lane-stage">
                        <LaneNavigation
                            className="lane-navigation"
                            type="button"
                            aria-label="Previous"
                            onClick={onPrev}
                            disabled={currentIndex === 0}
                            data-memory-control="true"
                        >
                            <span aria-hidden="true">‹</span>
                        </LaneNavigation>
                        <LanePhotoFrame
                            role="group"
                            aria-label="Photos"
                            style={{
                                width: laneFrameSize.width,
                                height: laneFrameSize.height,
                            }}
                            onClick={handlePhotoTap}
                            onPointerDown={handleHoldStart}
                            onPointerUp={handleHoldEnd}
                            onPointerCancel={handleHoldEnd}
                            onLostPointerCapture={handleHoldEnd}
                        >
                            {laneSlices.map((slice) => {
                                const file = files[slice.index]!;
                                const isDisplayCard =
                                    slice.index === displayIndex;
                                const distance = Math.min(
                                    1,
                                    Math.abs(slice.distance),
                                );
                                const mediaAspectRatio =
                                    file.metadata.fileType === FileType.video &&
                                    isDisplayCard
                                        ? (activeMediaAspectRatio ??
                                          getFileAspectRatio(file))
                                        : (mediaAspectRatios[file.id] ??
                                          getFileAspectRatio(file));
                                const common = {
                                    file,
                                    fillFrame: true,
                                    objectFit: "cover" as const,
                                    cropRect: resolveLaneCropRect(
                                        laneFrames?.[slice.index],
                                    ),
                                    cropContainerAspectRatio: 0.75,
                                    mediaAspectRatio,
                                };
                                return (
                                    <LanePhotoLayer
                                        key={slice.index}
                                        style={{
                                            opacity: 1 - distance,
                                            transform: `scale(${reducedMotion ? 1 : 1.1 - 0.1 * distance})`,
                                            filter:
                                                reducedMotion || distance === 0
                                                    ? undefined
                                                    : `blur(${12 * distance}px)`,
                                        }}
                                    >
                                        {file.metadata.fileType ===
                                            FileType.video && isDisplayCard ? (
                                            <VideoPlayer
                                                {...common}
                                                paused={
                                                    paused || isAnimatingStack
                                                }
                                                mediaRef={activeVideoElementRef}
                                                onReady={handleFullLoad}
                                                onDuration={handleVideoDuration}
                                                onEnded={handleVideoEnded}
                                                onPlaybackBlocked={
                                                    handleVideoPlaybackBlocked
                                                }
                                                onAspectRatio={
                                                    handleActiveAspectRatio
                                                }
                                            />
                                        ) : (
                                            <PhotoImage
                                                {...common}
                                                onFullLoad={
                                                    isDisplayCard
                                                        ? handleFullLoad
                                                        : undefined
                                                }
                                                onAspectRatio={(
                                                    width,
                                                    height,
                                                ) =>
                                                    handleMediaAspectRatio(
                                                        file.id,
                                                        width,
                                                        height,
                                                    )
                                                }
                                                showLoadingOverlay={false}
                                                thumbnailOnly={
                                                    file.metadata.fileType ===
                                                        FileType.video ||
                                                    Math.abs(slice.distance) > 1
                                                }
                                            />
                                        )}
                                    </LanePhotoLayer>
                                );
                            })}
                            {!fileLoaded && (
                                <LaneLoading role="status">
                                    Loading...
                                </LaneLoading>
                            )}
                        </LanePhotoFrame>
                        <LaneNavigation
                            className="lane-navigation"
                            type="button"
                            aria-label="Next"
                            onClick={onNext}
                            disabled={currentIndex === files.length - 1}
                            data-memory-control="true"
                        >
                            <span aria-hidden="true">›</span>
                        </LaneNavigation>
                    </LaneStage>
                    <LaneBottom className="lane-bottom">
                        <LaneCaption model={laneCaptionModel} />
                        <LaneTimelineRow>
                            <LaneTimeline
                                total={files.length}
                                currentProgress={
                                    isScrubbing ? stackProgress : displayIndex
                                }
                                width={Math.min(viewport.width * 0.68, 400)}
                                onSeek={onSeek}
                                onScrubStart={handleScrubStart}
                                onScrub={handleScrub}
                                onScrubEnd={handleScrubEnd}
                            />
                            <LaneControl
                                className="lane-playback"
                                type="button"
                                onClick={handlePlaybackToggle}
                                aria-label={
                                    finishedLanePlaybackRef.current
                                        ? "Replay memory lane"
                                        : paused
                                          ? "Play"
                                          : "Pause"
                                }
                                title={
                                    finishedLanePlaybackRef.current
                                        ? "Replay memory lane"
                                        : paused
                                          ? "Play"
                                          : "Pause"
                                }
                                data-memory-control="true"
                            >
                                {finishedLanePlaybackRef.current ? (
                                    <span
                                        aria-hidden="true"
                                        style={{ fontSize: 26 }}
                                    >
                                        ↻
                                    </span>
                                ) : (
                                    <span
                                        style={{
                                            transform: "scale(.65)",
                                            display: "flex",
                                        }}
                                    >
                                        <PlaybackGlyph paused={paused} />
                                    </span>
                                )}
                            </LaneControl>
                        </LaneTimelineRow>
                    </LaneBottom>
                </LaneMediaSection>
            </LaneContent>
        </LaneRoot>
    );
}

const LaneRoot = styled("main")({
    position: "relative",
    isolation: "isolate",
    width: "100%",
    minHeight: "100svh",
    height: "100dvh",
    overflow: "auto",
    background: "#111",
    color: "white",
    fontFamily: "Inter Variable, Inter, sans-serif",
    touchAction: "manipulation",
});
const LaneBackdrop = styled("div")({
    position: "fixed",
    inset: 0,
    zIndex: -1,
    overflow: "hidden",
    pointerEvents: "none",
    "&::after": {
        content: '""',
        position: "absolute",
        inset: 0,
        background:
            "linear-gradient(180deg,rgba(0,0,0,.38),rgba(0,0,0,.12) 45%,rgba(0,0,0,.5))",
    },
});
const LaneBackdropImage = styled("div")({
    position: "absolute",
    inset: "-100px",
    filter: "blur(80px)",
    transform: "scale(1.15)",
});
const LaneContent = styled("div")({
    position: "relative",
    width: "100%",
    maxWidth: 1360,
    minHeight: "100%",
    marginInline: "auto",
    "& > *": { minWidth: 0 },
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    padding:
        "max(42px,env(safe-area-inset-top)) 24px max(24px,env(safe-area-inset-bottom))",
    boxSizing: "border-box",
    "@media(max-width:900px)": {
        paddingTop: "max(36px,env(safe-area-inset-top))",
    },
    [`@media(max-width:${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        paddingTop: "max(32px,env(safe-area-inset-top))",
        paddingBottom: "max(18px,env(safe-area-inset-bottom))",
    },
    "@media (max-height: 500px) and (min-width: 480px)": {
        display: "grid",
        gridTemplateColumns: "minmax(0, 1fr) minmax(0, 1fr)",
        gridTemplateRows: "auto auto 1fr",
        columnGap: 24,
        rowGap: 12,
        maxWidth: 1000,
        paddingBlock: 16,
        "& > header": { gridColumn: "1 / 3", gridRow: 1 },
        "& .lane-heading": { gridColumn: 2, gridRow: 2, marginBlock: 0 },
        "& .lane-stage": {
            gridColumn: 1,
            gridRow: "2 / 4",
            paddingBlock: 0,
            height: "100%",
        },
        "& .lane-bottom": { gridColumn: 2, gridRow: 3, minHeight: 80 },
        "& .lane-navigation": { display: "none" },
    },
});
const LaneHeader = styled("header")({
    width: "100%",
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    gap: 20,
    flexShrink: 0,
    minHeight: 64,
    "@media(max-width:900px)": { minHeight: 56, gap: 14 },
    [`@media(max-width:${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        minHeight: 48,
        gap: 12,
    },
});
const LaneHeaderBrandLink = styled(BrandLink)({
    "& img": { width: 98 },
    "@media(max-width:900px)": { "& img": { width: 84 } },
    [`@media(max-width:${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        "& img": { width: 72 },
    },
});
const laneHeaderJoinNowButtonSx = {
    color: "white",
    backgroundColor: "rgba(255,255,255,.14)",
    "&:hover": { backgroundColor: "rgba(255,255,255,.22)" },
    "&:focus-visible": { outline: "2px solid white", outlineOffset: 4 },
    fontSize: "17px",
    paddingBlock: "14px",
    paddingInline: "30px",
    "@media(max-width:900px)": {
        fontSize: "15px",
        paddingBlock: "11px",
        paddingInline: "22px",
    },
    [`@media(max-width:${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        borderRadius: "14px",
        fontSize: "14px",
        paddingBlock: "9px",
        paddingInline: "18px",
        minWidth: "auto",
    },
} as const;
const LaneHeading = styled("h1")({
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    gap: 4,
    textAlign: "center",
    margin: 0,
    whiteSpace: "normal",
    overflowWrap: "anywhere",
    maxWidth: "min(100%, 520px)",
    textShadow: "0 12px 28px rgba(0,0,0,.32)",
    "@media(max-width:900px)": { gap: 3, maxWidth: "min(100%, 420px)" },
    [`@media(max-width:${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        gap: 2,
        maxWidth: "min(100%, 320px)",
    },
});
const LaneTitlePrimary = styled("span")({
    color: "rgba(255,255,255,.82)",
    fontWeight: 600,
    fontSize: 44,
    lineHeight: 0.98,
    letterSpacing: "-.04em",
    "@media(max-width:900px)": { fontSize: 37 },
    [`@media(max-width:${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        fontSize: 31,
        lineHeight: 1,
    },
});
const LaneTitleSecondary = styled("span")({
    color: "rgba(255,255,255,.5)",
    fontWeight: 500,
    fontSize: 29,
    lineHeight: 1.02,
    letterSpacing: "-.02em",
    "@media(max-width:900px)": { fontSize: 25 },
    [`@media(max-width:${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        fontSize: 21,
        lineHeight: 1.08,
    },
});
const LaneControl = styled("button")({
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    width: 48,
    height: 48,
    flexShrink: 0,
    border: 0,
    borderRadius: "50%",
    color: "white",
    background: "rgba(0,0,0,.16)",
    cursor: "pointer",
    "&:hover": { background: "rgba(255,255,255,.14)" },
    "&:focus-visible": { outline: "2px solid white", outlineOffset: 4 },
});
const LaneMediaSection = styled("div")({
    width: "100%",
    flex: 1,
    minHeight: 0,
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
    "@media (max-height: 500px) and (min-width: 480px)": {
        display: "contents",
    },
});
const LaneStage = styled("div")({
    width: "100%",
    flex: "0 0 auto",
    minHeight: 0,
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    gap: 48,
    paddingBlock: "24px",
    userSelect: "none",
});
const LanePhotoFrame = styled("div")({
    position: "relative",
    maxWidth: "100%",
    flexShrink: 0,
    overflow: "hidden",
    borderRadius: 16,
    background: "rgba(0,0,0,.15)",
    cursor: "pointer",
    WebkitTapHighlightColor: "transparent",
});
const LanePhotoLayer = styled("div")({
    position: "absolute",
    inset: 0,
    pointerEvents: "none",
    willChange: "transform,opacity",
});
const LaneNavigation = styled(LaneControl)({
    fontSize: 34,
    "&:disabled": { opacity: 0.25, cursor: "default" },
    "@media(max-width:899px)": { display: "none" },
});
const LaneLoading = styled("div")({
    position: "absolute",
    inset: 0,
    display: "grid",
    placeItems: "center",
    fontSize: 14,
    color: "rgba(255,255,255,.8)",
    pointerEvents: "none",
});
const LaneBottom = styled("div")({
    width: "100%",
    minHeight: 100,
    flexShrink: 0,
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
    gap: 12,
});
const LaneTimelineRow = styled("div")({
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    width: "100%",
    maxWidth: 460,
    gap: 12,
    "& > :first-child": { flex: 1, minWidth: 0 },
});
