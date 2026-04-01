import { keyframes } from "@emotion/react";
import { Box, Typography, styled } from "@mui/material";
import { downloadManager } from "ente-gallery/services/download";
import type { EnteFile } from "ente-media/file";
import { fileCreationPhotoDate } from "ente-media/file-metadata";
import { FileType } from "ente-media/file-type";
import {
    type PublicMemoryShareFrame,
    type PublicMemoryShareMetadata,
} from "ente-new/albums/services/public-memory";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
    buildLaneCaptionModel,
    buildLaneTitle,
    calculateLaneBlur,
    calculateLaneOpacity,
    calculateLaneOverlayOpacity,
    calculateLaneRotation,
    calculateLaneScale,
    calculateLaneYOffset,
    easeInOutCubic,
    formatLaneCaption,
    getFileAspectRatio,
    getFrameCreationDate,
    getLaneStackSlices,
    laneCardShadow,
    lerp,
    resolveLaneCropRect,
} from "../utils/lane";
import {
    LaneCaptionText,
    LanePlaybackGlyph,
    LaneProgressSlider,
    PlaybackGlyph,
    ProgressIndicator,
} from "./PublicMemoryControls";
import { PhotoImage, VideoPlayer } from "./PublicMemoryMedia";

interface MemoryViewerProps {
    files: EnteFile[];
    currentIndex: number;
    memoryName: string;
    memoryMetadata?: PublicMemoryShareMetadata;
    laneFrames?: (PublicMemoryShareFrame | undefined)[];
    variant: "share" | "lane";
    onNext: () => void;
    onPrev: () => void;
    onSeek: (index: number) => void;
}

const IMAGE_AUTO_PROGRESS_DURATION_MS = 5000;
const LANE_FRAME_INTERVAL_MS = 800;
const LANE_CARD_TRANSITION_DURATION_MS = 520;
const MOBILE_LAYOUT_BREAKPOINT_PX = 600;
const SHARE_FOOTER_ACTIONS_BREAKPOINT_PX = 960;
const LANE_COMPACT_LAYOUT_BREAKPOINT_PX = 900;
const EDGE_NAV_TAP_ZONE_RATIO = 0.2;
const HOLD_TO_PAUSE_NAV_SUPPRESSION_MS = 250;
const MOBILE_MEDIA_RESERVED_VERTICAL_SPACE_PX = 280;
const MOBILE_VIDEO_MEDIA_RESERVED_VERTICAL_SPACE_PX = 244;
const LANE_MOBILE_MEDIA_RESERVED_VERTICAL_SPACE_PX = 340;
const DESKTOP_MEDIA_MAX_WIDTH_PX = 1360;
const DESKTOP_MEDIA_HORIZONTAL_PADDING_PX = 32;
const DESKTOP_MEDIA_VERTICAL_RESERVED_PX = 184;
const DESKTOP_LANE_MEDIA_VERTICAL_RESERVED_PX = 320;
const LANE_CARD_ASPECT_RATIO = 0.68;
const LANE_MOBILE_CARD_MAX_WIDTH_PX = 326;
const LANE_MOBILE_CARD_MIN_WIDTH_PX = 220;
const MOBILE_VIDEO_MAX_WIDTH_PX = 344;
const LANE_DESKTOP_CARD_MAX_WIDTH_PX = 420;
const LANE_DESKTOP_CARD_MIN_WIDTH_PX = 280;
const MEDIA_SWITCH_TRANSITION_DURATION_MS = 380;
const DESKTOP_MEDIA_MAX_WIDTH_CSS = `min(${DESKTOP_MEDIA_MAX_WIDTH_PX}px, calc(100vw - ${DESKTOP_MEDIA_HORIZONTAL_PADDING_PX}px))`;
const DESKTOP_MEDIA_MAX_HEIGHT_CSS = `calc(min(100vh, 100dvh) - ${DESKTOP_MEDIA_VERTICAL_RESERVED_PX}px)`;
const DESKTOP_BACKGROUND_IMAGE_PATH = "/images/memory-lane-bg-desktop.svg";
const MOBILE_BACKGROUND_IMAGE_PATH = "/images/memory-lane-bg-mobile.svg";
const ENTE_BRAND_TAG_IMAGE_PATH = "/images/ente-brand-tag.svg";
const LANE_GRID_CELL_SIZE_PX = 80;
const LANE_GRID_LINE_COLOR = "#08c225";
const LANE_GRID_LINE_OPACITY = 0.06;
const LANE_GRID_DISPLACEMENT_SCALE = 9;

const readViewport = () => ({
    width: window.visualViewport?.width ?? window.innerWidth,
    height: window.visualViewport?.height ?? window.innerHeight,
});

interface LaneMemoryViewerProps {
    files: EnteFile[];
    currentIndex: number;
    memoryName: string;
    memoryMetadata?: PublicMemoryShareMetadata;
    laneFrames?: (PublicMemoryShareFrame | undefined)[];
    onNext: () => void;
    onPrev: () => void;
    onSeek: (index: number) => void;
}

export const LaneMemoryViewer: React.FC<LaneMemoryViewerProps> = ({
    files,
    currentIndex,
    memoryName,
    memoryMetadata,
    laneFrames,
    onNext,
    onPrev,
    onSeek,
}) => {
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
    const pressStartedAtRef = useRef<number | null>(null);
    const suppressTapNavigationRef = useRef(false);
    const shouldResumeAfterHoldRef = useRef(false);
    const finishedLanePlaybackRef = useRef(false);
    const restartOnResumeRef = useRef(false);
    const animationFrameRef = useRef<number | null>(null);
    const animationStartTimestampRef = useRef<number | null>(null);
    const stackProgressRef = useRef(currentIndex);
    const displayIndexRef = useRef(currentIndex);
    const currentIndexRef = useRef(currentIndex);
    const pausedRef = useRef(paused);
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
    const isMobileLayout = viewport.width <= MOBILE_LAYOUT_BREAKPOINT_PX;
    const isCompactLaneLayout =
        viewport.width <= LANE_COMPACT_LAYOUT_BREAKPOINT_PX;

    onNextRef.current = onNext;
    currentIndexRef.current = currentIndex;
    pausedRef.current = paused;
    stackProgressRef.current = stackProgress;
    displayIndexRef.current = displayIndex;
    isVideoRef.current = currentFile.metadata.fileType === FileType.video;
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

    const handleActiveAspectRatio = useCallback(
        (width: number, height: number) => {
            if (width <= 0 || height <= 0) {
                return;
            }
            setActiveMediaAspectRatio(width / height);
        },
        [],
    );

    const handlePlaybackToggle = useCallback(
        (event: React.MouseEvent<HTMLButtonElement>) => {
            event.stopPropagation();
            setPaused((previous) => {
                const nextPaused = !previous;
                restartOnResumeRef.current =
                    !nextPaused && finishedLanePlaybackRef.current;
                if (!nextPaused) {
                    finishedLanePlaybackRef.current = false;
                }
                return nextPaused;
            });
        },
        [],
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
        (event: React.MouseEvent<HTMLDivElement>) => {
            if (suppressTapNavigationRef.current) {
                suppressTapNavigationRef.current = false;
                return;
            }
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

        return { width: Math.round(width), height: Math.round(height) };
    }, [isCompactLaneLayout, viewport.height, viewport.width]);

    const laneTitle = useMemo(() => {
        return buildLaneTitle({
            memoryName,
            personName: memoryMetadata?.personName,
        });
    }, [memoryMetadata?.personName, memoryName]);

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
            setIsScrubbing(false);
            setStackProgress(roundedIndex);
            if (displayIndexRef.current !== roundedIndex) {
                commitDisplayIndex(roundedIndex);
            }
            onSeek(roundedIndex);
        },
        [commitDisplayIndex, files.length, onSeek, trackScrubValue],
    );

    return (
        <ViewerRoot onClick={handleScreenTap}>
            <LaneBackground isMobileLayout={isCompactLaneLayout} />
            <LaneContentContainer
                style={
                    isCompactLaneLayout
                        ? {
                              maxWidth: isMobileLayout ? "375px" : "440px",
                              padding: isMobileLayout
                                  ? "24px 24px calc(18px + env(safe-area-inset-bottom, 0px))"
                                  : "32px 28px 30px",
                              gap: isMobileLayout ? "14px" : "20px",
                          }
                        : undefined
                }
            >
                {isCompactLaneLayout ? (
                    <LaneMobileHeaderSection>
                        <LaneMobileTitle variant="h6">
                            {laneTitle}
                        </LaneMobileTitle>
                    </LaneMobileHeaderSection>
                ) : (
                    <LaneTopBar>
                        <LaneDesktopTitle variant="h6">
                            {laneTitle}
                        </LaneDesktopTitle>
                        <LaneTopBrandSection>
                            <LaneSharedUsingLabel>
                                Shared using
                            </LaneSharedUsingLabel>
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
                        </LaneTopBrandSection>
                    </LaneTopBar>
                )}

                <LaneCenterSection>
                    <PhotoContainer
                        style={{ flex: "0 0 auto", minHeight: "auto" }}
                        onContextMenu={(event) => event.preventDefault()}
                        onDragStart={(event) => event.preventDefault()}
                        onPointerDown={
                            isCompactLaneLayout
                                ? () => {
                                      pressStartedAtRef.current = Date.now();
                                      suppressTapNavigationRef.current = false;
                                      shouldResumeAfterHoldRef.current =
                                          !paused;
                                      setPaused(true);
                                  }
                                : undefined
                        }
                        onPointerUp={
                            isCompactLaneLayout
                                ? () => {
                                      const startedAt =
                                          pressStartedAtRef.current;
                                      pressStartedAtRef.current = null;
                                      if (
                                          startedAt &&
                                          Date.now() - startedAt >
                                              HOLD_TO_PAUSE_NAV_SUPPRESSION_MS
                                      ) {
                                          suppressTapNavigationRef.current = true;
                                      }
                                      if (shouldResumeAfterHoldRef.current) {
                                          setPaused(false);
                                      }
                                      shouldResumeAfterHoldRef.current = false;
                                  }
                                : undefined
                        }
                        onPointerCancel={
                            isCompactLaneLayout
                                ? () => {
                                      pressStartedAtRef.current = null;
                                      if (shouldResumeAfterHoldRef.current) {
                                          setPaused(false);
                                      }
                                      shouldResumeAfterHoldRef.current = false;
                                  }
                                : undefined
                        }
                        onPointerLeave={
                            isCompactLaneLayout
                                ? () => {
                                      if (pressStartedAtRef.current !== null) {
                                          pressStartedAtRef.current = null;
                                          if (
                                              shouldResumeAfterHoldRef.current
                                          ) {
                                              setPaused(false);
                                          }
                                          shouldResumeAfterHoldRef.current = false;
                                      }
                                  }
                                : undefined
                        }
                    >
                        <LaneCardStack
                            style={{
                                width: `${laneFrameSize.width}px`,
                                height: `${laneFrameSize.height}px`,
                            }}
                        >
                            {laneSlices.map((slice) => {
                                const file = files[slice.index]!;
                                const frame = laneFrames?.[slice.index];
                                const scale = calculateLaneScale(
                                    slice.distance,
                                );
                                const yOffset = calculateLaneYOffset(
                                    slice.distance,
                                    laneFrameSize.height,
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
                                    calculateLaneOverlayOpacity(slice.distance);
                                const cropRect = resolveLaneCropRect(frame);
                                const containerAspectRatio =
                                    laneFrameSize.width / laneFrameSize.height;
                                const isDisplayCard =
                                    slice.index === displayIndex;
                                const prefersRichImage =
                                    file.metadata.fileType === FileType.video
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
                                            transform: `translateY(${yOffset}px) rotate(${rotation}deg) scale(${scale})`,
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
                                                        onReady={handleFullLoad}
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
                                                            isDisplayCard
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
                                                        opacity: overlayOpacity,
                                                    }}
                                                />
                                            )}
                                        </LaneCardSurface>
                                    </LaneStackSlice>
                                );
                            })}
                        </LaneCardStack>
                    </PhotoContainer>

                    <LaneBottomSection>
                        <LaneCaptionRow>
                            <LanePlaybackButton
                                type="button"
                                data-memory-control="true"
                                onClick={handlePlaybackToggle}
                            >
                                <LanePlaybackGlyph paused={paused} />
                            </LanePlaybackButton>
                            <LaneCaption>
                                <LaneCaptionText
                                    model={laneCaptionModel}
                                    previousValue={previousCaptionValue}
                                />
                            </LaneCaption>
                        </LaneCaptionRow>
                        <LaneProgressSlider
                            total={files.length}
                            currentProgress={stackProgress}
                            onSeek={onSeek}
                            onScrubStart={handleScrubStart}
                            onScrub={handleScrub}
                            onScrubEnd={handleScrubEnd}
                        />
                    </LaneBottomSection>
                </LaneCenterSection>
                <LaneFooter>
                    {isMobileLayout ? (
                        <LaneMobileFooterBar>
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
                        </LaneMobileFooterBar>
                    ) : (
                        <JoinNowButton
                            href="https://ente.io"
                            target="_blank"
                            rel="noreferrer"
                        >
                            Join now
                        </JoinNowButton>
                    )}
                </LaneFooter>
            </LaneContentContainer>
        </ViewerRoot>
    );
};

const isInteractiveTapTarget = (target: EventTarget | null) => {
    if (!(target instanceof Element)) return false;
    return Boolean(
        target.closest(
            "button, a, input, textarea, select, [role='button'], [data-memory-control='true']",
        ),
    );
};

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

const laneBackCardPrimaryEnterAnimation = keyframes`
    from {
        opacity: 0;
        transform: translate(26px, -26px) rotate(6.4deg);
    }
    to {
        opacity: 1;
        transform: translate(14px, -16px) rotate(3.1deg);
    }
`;

const laneBackCardSecondaryEnterAnimation = keyframes`
    from {
        opacity: 0;
        transform: translate(16px, -14px) rotate(-4.2deg);
    }
    to {
        opacity: 1;
        transform: translate(6px, -8px) rotate(-1.3deg);
    }
`;

const laneMediaSwitchInAnimation = keyframes`
    from {
        opacity: 0;
        transform: translateY(-22px) scale(0.97);
    }
    to {
        opacity: 1;
        transform: translateY(0) scale(1);
    }
`;

const laneMediaSwitchOutAnimation = keyframes`
    from {
        opacity: 1;
        transform: translateY(0) scale(1);
    }
    to {
        opacity: 0;
        transform: translateY(76px) scale(1.02);
    }
`;

export const MemoryViewer: React.FC<MemoryViewerProps> = ({
    files,
    currentIndex,
    memoryName,
    memoryMetadata,
    laneFrames,
    variant,
    onNext,
    onPrev,
    onSeek,
}) => {
    const currentFile = files[currentIndex]!;
    const currentLaneFrame = laneFrames?.[currentIndex];
    const [paused, setPaused] = useState(false);
    const [fileLoaded, setFileLoaded] = useState(false);
    // For videos, track if duration is known (prevents premature animation start).
    const [videoDurationKnown, setVideoDurationKnown] = useState(false);
    // For videos, we track the duration in ms; for images, use the constant.
    const [progressDuration, setProgressDuration] = useState(
        IMAGE_AUTO_PROGRESS_DURATION_MS,
    );
    const [finishedPlayback, setFinishedPlayback] = useState(false);
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
    const useFooterShareActions =
        viewport.width <= SHARE_FOOTER_ACTIONS_BREAKPOINT_PX;
    const isCompactLaneLayout =
        viewport.width <= LANE_COMPACT_LAYOUT_BREAKPOINT_PX;

    // Reset loaded state and duration when file changes.
    useEffect(() => {
        setPaused(false);
        setFinishedPlayback(false);
        setFileLoaded(false);
        setVideoDurationKnown(false);
        setMediaAspectRatio(undefined);
        // Reset to image duration; video will update this when it loads.
        setProgressDuration(
            variant === "lane"
                ? LANE_FRAME_INTERVAL_MS
                : IMAGE_AUTO_PROGRESS_DURATION_MS,
        );
    }, [currentIndex, variant]);

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

    const handleAdvanceOrFinish = useCallback(() => {
        if (currentIndex >= files.length - 1) {
            setFinishedPlayback(true);
            setPaused(true);
            return;
        }
        onNext();
    }, [currentIndex, files.length, onNext]);

    // Preload next file's thumbnail for smoother navigation.
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
        const frameDate = getFrameCreationDate(currentLaneFrame);
        if (frameDate) {
            return formatMemoryDate(frameDate);
        }
        try {
            return formatMemoryDate(fileCreationPhotoDate(currentFile));
        } catch {
            return "";
        }
    }, [currentFile, currentLaneFrame]);

    const headerTitle = useMemo(() => {
        if (memoryName && currentFileDate)
            return `${memoryName} • ${currentFileDate}`;
        return memoryName || currentFileDate || "Memory";
    }, [memoryName, currentFileDate]);
    const isLaneVariant = variant === "lane";

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
        const isShareVideo = isVideo && !isLaneVariant;
        const availableWidth = Math.max(
            220,
            viewport.width - (isShareVideo ? 32 : 48),
        );
        const maxWidth = Math.min(
            isShareVideo ? MOBILE_VIDEO_MAX_WIDTH_PX : 326,
            availableWidth,
        );
        const maxHeight = Math.max(
            180,
            viewport.height -
                (isShareVideo
                    ? MOBILE_VIDEO_MEDIA_RESERVED_VERTICAL_SPACE_PX
                    : MOBILE_MEDIA_RESERVED_VERTICAL_SPACE_PX),
        );
        const ratio =
            resolvedMediaAspectRatio ?? (isShareVideo ? 16 / 9 : 4 / 3);

        let width = maxWidth;
        let height = width / ratio;

        if (height > maxHeight) {
            height = maxHeight;
            width = height * ratio;
        }

        return { width: Math.round(width), height: Math.round(height) };
    }, [
        isLaneVariant,
        isVideo,
        resolvedMediaAspectRatio,
        viewport.height,
        viewport.width,
    ]);

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

        return { width: Math.round(width), height: Math.round(height) };
    }, [isCompactLaneLayout, viewport.height, viewport.width]);

    const mediaFrameStyle = isMobileLayout
        ? {
              width: `${mobileFrameSize.width}px`,
              aspectRatio: `${resolvedMediaAspectRatio ?? (isVideo && !isLaneVariant ? 16 / 9 : 4 / 3)}`,
          }
        : {
              width: `${desktopFrameSize.width}px`,
              aspectRatio: `${resolvedMediaAspectRatio ?? 4 / 3}`,
          };

    const laneMediaFrameStyle = {
        width: `${laneFrameSize.width}px`,
        height: `${laneFrameSize.height}px`,
    };

    const isProgressPaused =
        paused || !fileLoaded || (isVideo && !videoDurationKnown);
    const laneTitle = useMemo(() => {
        return buildLaneTitle({
            memoryName,
            personName: memoryMetadata?.personName,
        });
    }, [memoryMetadata?.personName, memoryName]);
    const laneCaption = useMemo(() => {
        return formatLaneCaption({
            frame: currentLaneFrame,
            metadata: memoryMetadata,
            fallbackLabel: currentFileDate || memoryName || "Memory lane",
        });
    }, [currentFileDate, currentLaneFrame, memoryMetadata, memoryName]);
    const mediaObjectFit: "contain" | "cover" = isLaneVariant
        ? "cover"
        : "contain";
    const laneContainerAspectRatio = laneFrameSize.width / laneFrameSize.height;
    const currentCropRect = isLaneVariant
        ? resolveLaneCropRect(currentLaneFrame)
        : undefined;
    const outgoingLaneFrame =
        outgoingIndex !== null ? laneFrames?.[outgoingIndex] : undefined;
    const outgoingCropRect = isLaneVariant
        ? resolveLaneCropRect(outgoingLaneFrame)
        : undefined;
    const mediaLayers = (
        <>
            <MediaSwitchLayer
                phase="in"
                variant={isLaneVariant ? "lane" : "share"}
                key={`memory-file-${currentIndex}`}
            >
                {isVideo ? (
                    <VideoPlayer
                        file={currentFile}
                        onReady={handleFullLoad}
                        onDuration={handleVideoDuration}
                        onEnded={handleAdvanceOrFinish}
                        paused={paused}
                        fillFrame
                        objectFit={mediaObjectFit}
                        cropRect={currentCropRect}
                        cropContainerAspectRatio={laneContainerAspectRatio}
                        mediaAspectRatio={resolvedMediaAspectRatio}
                        onAspectRatio={handleMediaAspectRatio}
                    />
                ) : (
                    <PhotoImage
                        file={currentFile}
                        onFullLoad={handleFullLoad}
                        fillFrame
                        objectFit={mediaObjectFit}
                        cropRect={currentCropRect}
                        cropContainerAspectRatio={laneContainerAspectRatio}
                        mediaAspectRatio={resolvedMediaAspectRatio}
                        onAspectRatio={handleMediaAspectRatio}
                    />
                )}
            </MediaSwitchLayer>
            {outgoingFile && (
                <MediaSwitchLayer
                    phase="out"
                    variant={isLaneVariant ? "lane" : "share"}
                    key={`memory-file-out-${outgoingIndex ?? currentIndex}`}
                >
                    {outgoingIsVideo ? (
                        <VideoPlayer
                            file={outgoingFile}
                            paused
                            fillFrame
                            objectFit={mediaObjectFit}
                            cropRect={outgoingCropRect}
                            cropContainerAspectRatio={laneContainerAspectRatio}
                            mediaAspectRatio={getFileAspectRatio(outgoingFile)}
                            showLoadingOverlay={false}
                        />
                    ) : (
                        <PhotoImage
                            file={outgoingFile}
                            fillFrame
                            objectFit={mediaObjectFit}
                            cropRect={outgoingCropRect}
                            cropContainerAspectRatio={laneContainerAspectRatio}
                            mediaAspectRatio={getFileAspectRatio(outgoingFile)}
                            showLoadingOverlay={false}
                        />
                    )}
                </MediaSwitchLayer>
            )}
        </>
    );

    if (isLaneVariant) {
        return (
            <ViewerRoot onClick={handleScreenTap}>
                <LaneBackground isMobileLayout={isCompactLaneLayout} />
                <LaneContentContainer
                    style={
                        isCompactLaneLayout
                            ? {
                                  maxWidth: isMobileLayout ? "375px" : "440px",
                                  padding: isMobileLayout
                                      ? "24px 24px calc(18px + env(safe-area-inset-bottom, 0px))"
                                      : "32px 28px 30px",
                                  gap: isMobileLayout ? "14px" : "20px",
                              }
                            : undefined
                    }
                >
                    {isCompactLaneLayout ? (
                        <LaneMobileHeaderSection>
                            <LaneMobileTitle variant="h6">
                                {laneTitle}
                            </LaneMobileTitle>
                        </LaneMobileHeaderSection>
                    ) : (
                        <LaneTopBar>
                            <LaneDesktopTitle variant="h6">
                                {laneTitle}
                            </LaneDesktopTitle>
                            <LaneTopBrandSection>
                                <LaneSharedUsingLabel>
                                    Shared using
                                </LaneSharedUsingLabel>
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
                            </LaneTopBrandSection>
                        </LaneTopBar>
                    )}

                    <LaneCenterSection>
                        <PhotoContainer
                            style={{ flex: "0 0 auto", minHeight: "auto" }}
                            onContextMenu={(event) => event.preventDefault()}
                            onDragStart={(event) => event.preventDefault()}
                            onPointerDown={
                                isCompactLaneLayout
                                    ? () => {
                                          pressStartedAtRef.current =
                                              Date.now();
                                          suppressTapNavigationRef.current = false;
                                          setPaused(true);
                                      }
                                    : undefined
                            }
                            onPointerUp={
                                isCompactLaneLayout
                                    ? () => {
                                          const startedAt =
                                              pressStartedAtRef.current;
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
                                isCompactLaneLayout
                                    ? () => {
                                          pressStartedAtRef.current = null;
                                          setPaused(false);
                                      }
                                    : undefined
                            }
                            onPointerLeave={
                                isCompactLaneLayout
                                    ? () => {
                                          if (
                                              pressStartedAtRef.current !== null
                                          ) {
                                              pressStartedAtRef.current = null;
                                              setPaused(false);
                                          }
                                      }
                                    : undefined
                            }
                        >
                            <LaneCardStack style={laneMediaFrameStyle}>
                                <LaneBackCardPrimary
                                    key={`lane-back-primary-${currentIndex}`}
                                    style={
                                        isCompactLaneLayout
                                            ? { borderRadius: "18px" }
                                            : undefined
                                    }
                                />
                                <LaneBackCardSecondary
                                    key={`lane-back-secondary-${currentIndex}`}
                                    style={
                                        isCompactLaneLayout
                                            ? { borderRadius: "18px" }
                                            : undefined
                                    }
                                />
                                <LaneFrontCard
                                    style={
                                        isCompactLaneLayout
                                            ? { borderRadius: "18px" }
                                            : undefined
                                    }
                                >
                                    <MediaFrame
                                        style={{
                                            width: "100%",
                                            height: "100%",
                                            maxWidth: "100%",
                                            maxHeight: "100%",
                                            borderRadius: isCompactLaneLayout
                                                ? "18px"
                                                : "22px",
                                        }}
                                    >
                                        {mediaLayers}
                                    </MediaFrame>
                                </LaneFrontCard>
                            </LaneCardStack>
                        </PhotoContainer>

                        <LaneBottomSection>
                            <Box
                                sx={{
                                    position: "absolute",
                                    width: 1,
                                    height: 1,
                                    opacity: 0,
                                    overflow: "hidden",
                                    pointerEvents: "none",
                                }}
                            >
                                <ProgressIndicator
                                    total={files.length}
                                    current={currentIndex}
                                    paused={isProgressPaused}
                                    duration={progressDuration}
                                    onComplete={onNext}
                                    isVideo={isVideo}
                                />
                            </Box>
                            <LaneCaptionRow>
                                <LanePlaybackButton
                                    type="button"
                                    data-memory-control="true"
                                    onClick={(event) => {
                                        event.stopPropagation();
                                        setPaused((state) => !state);
                                    }}
                                >
                                    <LanePlaybackGlyph paused={paused} />
                                </LanePlaybackButton>
                                <LaneCaption>{laneCaption}</LaneCaption>
                            </LaneCaptionRow>
                            <LaneProgressSlider
                                total={files.length}
                                current={currentIndex}
                                onSeek={onSeek}
                            />
                        </LaneBottomSection>
                    </LaneCenterSection>
                    <LaneFooter>
                        {isCompactLaneLayout ? (
                            <LaneMobileFooterBar>
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
                            </LaneMobileFooterBar>
                        ) : (
                            <JoinNowButton
                                href="https://ente.io"
                                target="_blank"
                                rel="noreferrer"
                            >
                                Join now
                            </JoinNowButton>
                        )}
                    </LaneFooter>
                </LaneContentContainer>
            </ViewerRoot>
        );
    }

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
                    <MobileHeaderSection>
                        <MobileTitle variant="h6">{headerTitle}</MobileTitle>
                        <ProgressIndicator
                            total={files.length}
                            current={currentIndex}
                            paused={isProgressPaused}
                            duration={progressDuration}
                            onComplete={handleAdvanceOrFinish}
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

                        <HeaderSection>
                            <MemoryTitle variant="h6">
                                {headerTitle}
                            </MemoryTitle>
                            <ProgressIndicator
                                total={files.length}
                                current={currentIndex}
                                paused={isProgressPaused}
                                duration={progressDuration}
                                onComplete={handleAdvanceOrFinish}
                                isVideo={isVideo}
                            />
                        </HeaderSection>

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
                    <MobileBottomBar>
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
                    </MobileBottomBar>
                )}
            </ContentContainer>
        </ViewerRoot>
    );
};

const ViewerRoot = styled("div")({
    position: "relative",
    width: "100vw",
    minHeight: "100svh",
    height: "100dvh",
    overflow: "hidden",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    userSelect: "none",
    WebkitUserSelect: "none",
    WebkitTouchCallout: "none",
    WebkitTapHighlightColor: "transparent",
    touchAction: "manipulation",
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

const LaneBackgroundGridFill: React.FC<{
    patternId: string;
    filterId: string;
}> = ({ patternId, filterId }) => (
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

const LaneDesktopBackgroundGridOverlay = () => (
    <LaneDesktopBackgroundGrid aria-hidden preserveAspectRatio="none">
        <LaneBackgroundGridFill
            patternId="lane-desktop-grid-pattern"
            filterId="lane-desktop-grid-filter"
        />
    </LaneDesktopBackgroundGrid>
);

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

const LaneMobileBackgroundGridOverlay = () => (
    <LaneMobileBackgroundGrid aria-hidden preserveAspectRatio="none">
        <LaneBackgroundGridFill
            patternId="lane-mobile-grid-pattern"
            filterId="lane-mobile-grid-filter"
        />
    </LaneMobileBackgroundGrid>
);

const LaneBackground: React.FC<{ isMobileLayout?: boolean }> = ({
    isMobileLayout = false,
}) =>
    isMobileLayout ? (
        <LaneMobileBackgroundPattern>
            <LaneMobileBackgroundGridOverlay />
        </LaneMobileBackgroundPattern>
    ) : (
        <LaneDesktopBackgroundPattern>
            <LaneDesktopBackgroundAtmosphere />
            <LaneDesktopBackgroundGridOverlay />
        </LaneDesktopBackgroundPattern>
    );

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

const LaneContentContainer = styled("div")({
    position: "relative",
    zIndex: 2,
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    gap: "26px",
    width: "100%",
    maxWidth: `${DESKTOP_MEDIA_MAX_WIDTH_PX}px`,
    minHeight: "100svh",
    height: "100dvh",
    padding: "56px 48px 40px",
    boxSizing: "border-box",
    [`@media (max-width: ${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        padding: "24px 24px calc(18px + env(safe-area-inset-bottom, 0px))",
    },
});

const LaneMobileHeaderSection = styled("div")({
    width: "100%",
    display: "flex",
    alignItems: "center",
    justifyContent: "flex-start",
    minHeight: "40px",
});

const LaneMobileTitle = styled(Typography)({
    color: "white",
    fontFamily: "'Inter', sans-serif",
    fontWeight: 600,
    fontSize: "20px",
    lineHeight: "20px",
    letterSpacing: 0,
    textAlign: "left",
    maxWidth: "100%",
    whiteSpace: "nowrap",
    overflow: "hidden",
    textOverflow: "ellipsis",
});

const LaneTopBar = styled("div")({
    width: "calc(100% + 48px)",
    marginLeft: "-24px",
    marginRight: "-24px",
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    minHeight: "48px",
});

const LaneDesktopTitle = styled(Typography)({
    color: "white",
    fontFamily: "'Inter', sans-serif",
    fontWeight: 500,
    fontSize: "27px",
    lineHeight: "24px",
    letterSpacing: "-1px",
    textAlign: "left",
    whiteSpace: "normal",
    overflowWrap: "anywhere",
    maxWidth: "70%",
    "@media (max-width: 900px)": {
        fontSize: "22px",
        lineHeight: "22px",
        letterSpacing: "0px",
    },
});

const LaneTopBrandSection = styled("div")({
    display: "flex",
    alignItems: "center",
    gap: "12px",
});

const LaneCenterSection = styled("div")({
    width: "100%",
    flex: 1,
    minHeight: 0,
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
    gap: "38px",
    "@media (max-width: 900px)": { gap: "28px" },
});

const LaneFooter = styled("div")({
    width: "100%",
    flexShrink: 0,
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    marginTop: "auto",
    paddingBottom: "max(8px, env(safe-area-inset-bottom, 0px))",
    [`@media (max-width: ${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        paddingBottom: 0,
    },
});

const LaneSharedUsingLabel = styled("span")({
    color: "rgba(255, 255, 255, 0.53)",
    fontFamily: "var(--font-itim), cursive",
    fontStyle: "normal",
    fontWeight: 400,
    fontSize: "24px",
    lineHeight: "13px",
    textAlign: "center",
    whiteSpace: "nowrap",
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

const LaneBackCardBase = styled("div")({
    position: "absolute",
    inset: 0,
    borderRadius: "22px",
    border: "4px solid rgba(255, 255, 255, 0.82)",
    backgroundColor: "rgba(255, 255, 255, 0.2)",
});

const LaneBackCardPrimary = styled(LaneBackCardBase)({
    transform: "translate(14px, -16px) rotate(3.1deg)",
    transformOrigin: "center",
    zIndex: 1,
    animation: `${laneBackCardPrimaryEnterAnimation} 320ms cubic-bezier(0.2, 0.8, 0.2, 1)`,
});

const LaneBackCardSecondary = styled(LaneBackCardBase)({
    transform: "translate(6px, -8px) rotate(-1.3deg)",
    transformOrigin: "center",
    zIndex: 2,
    animation: `${laneBackCardSecondaryEnterAnimation} 280ms cubic-bezier(0.2, 0.8, 0.2, 1)`,
});

const LaneFrontCard = styled("div")({
    position: "relative",
    zIndex: 3,
    width: "100%",
    height: "100%",
    borderRadius: "22px",
    border: "4px solid rgba(255, 255, 255, 0.92)",
    overflow: "hidden",
    backgroundColor: "black",
});

const LaneBottomSection = styled("div")({
    position: "relative",
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "flex-end",
    gap: "20px",
    width: "100%",
    paddingBottom: 0,
});

const LaneCaptionRow = styled("div")({
    display: "flex",
    alignItems: "center",
    gap: "10px",
});

const LanePlaybackButton = styled("button")({
    border: 0,
    outline: "none",
    width: "28px",
    height: "28px",
    borderRadius: "999px",
    padding: 0,
    cursor: "pointer",
    backgroundColor: "rgba(255, 255, 255, 0.2)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    color: "white",
});

const LaneCaption = styled("div")({
    color: "rgba(255, 255, 255, 0.53)",
    fontFamily: "var(--font-itim), cursive",
    fontStyle: "normal",
    fontWeight: 400,
    fontSize: "24px",
    lineHeight: 1.15,
    textAlign: "center",
    whiteSpace: "normal",
    overflowWrap: "anywhere",
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
    width: `${DESKTOP_MEDIA_MAX_WIDTH_PX}px`,
    maxWidth: "100%",
    boxSizing: "border-box",
    "@media (max-width: 900px)": { minHeight: "56px" },
});

const HeaderSection = styled("div")({
    width: "min(100%, 448px)",
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
    letterSpacing: "0px",
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
    borderRadius: "19px",
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
    borderRadius: "39px",
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
    right: 0,
    top: "50%",
    transform: "translateY(-50%)",
    display: "flex",
    alignItems: "center",
    gap: "16px",
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

const EnteBrandTagImage = styled("img")({
    width: "58px",
    height: "42px",
    display: "block",
    userSelect: "none",
});

const MobileBottomBar = styled("div")({
    width: "100%",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    gap: "10px",
    marginTop: "auto",
    paddingBottom: "max(2px, env(safe-area-inset-bottom, 0px))",
});

const LaneMobileFooterBar = styled("div")({
    width: "100%",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    gap: "10px",
    marginTop: "auto",
    paddingBottom: "max(2px, env(safe-area-inset-bottom, 0px))",
});

const MobileJoinNowButton = styled("a")({
    backgroundColor: "#08c225",
    color: "white",
    textDecoration: "none",
    borderRadius: "33px",
    padding: "16px 28px",
    fontWeight: 700,
    fontSize: "14px",
    lineHeight: "12px",
    whiteSpace: "nowrap",
});

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
    shouldForwardProp: (prop) => prop !== "phase" && prop !== "variant",
})<{ phase: "in" | "out"; variant?: "share" | "lane" }>(
    ({ phase, variant = "share" }) => ({
        position: "absolute",
        inset: 0,
        width: "100%",
        height: "100%",
        zIndex: phase === "out" ? (variant === "lane" ? 3 : 2) : 1,
        animation: (() => {
            if (variant === "lane") {
                return phase === "out"
                    ? `${laneMediaSwitchOutAnimation} ${MEDIA_SWITCH_TRANSITION_DURATION_MS}ms cubic-bezier(0.22, 0.9, 0.2, 1) forwards`
                    : `${laneMediaSwitchInAnimation} ${MEDIA_SWITCH_TRANSITION_DURATION_MS}ms cubic-bezier(0.22, 0.9, 0.2, 1) both`;
            }
            return phase === "out"
                ? `${mediaSwitchOutAnimation} ${MEDIA_SWITCH_TRANSITION_DURATION_MS}ms cubic-bezier(0.16, 1, 0.3, 1) forwards`
                : `${mediaSwitchInAnimation} ${MEDIA_SWITCH_TRANSITION_DURATION_MS}ms cubic-bezier(0.16, 1, 0.3, 1) both`;
        })(),
        willChange: "opacity, transform",
        pointerEvents: "none",
    }),
);

/**
 * Format a date in the style "12th jan, 2022".
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
