/**
 * Shared playback and progress controls for the public memories viewers.
 * This file contains the share viewer progress bar plus the lane-specific
 * caption, glyph, and scrubber controls used by `MemoryViewer` and
 * `LaneMemoryViewer`.
 */
import { keyframes } from "@emotion/react";
import { Box, styled } from "@mui/material";
import { useCallback, useMemo, useState } from "react";
import type { LaneCaptionModel } from "../utils/lane";

const MOBILE_LAYOUT_BREAKPOINT_PX = 600;
const DESKTOP_PROGRESS_MAX_WIDTH_PX = 448;
const MOBILE_PROGRESS_MAX_WIDTH_PX = 326;
const MINIMAL_DESKTOP_PROGRESS_MAX_WIDTH_PX = 392;
const MINIMAL_PROGRESS_COMPACT_BREAKPOINT_PX = 700;
const MINIMAL_PROGRESS_COMPACT_MAX_WIDTH_PX = 352;

const progressFillAnimation = keyframes`
    from { width: 0%; }
    to { width: 100%; }
`;

const LaneCaptionInline = styled("span")({
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    flexWrap: "wrap",
    gap: "4px",
    textAlign: "center",
});

const LaneCaptionNumber = styled("span")({
    color: "rgba(255, 255, 255, 0.9)",
    fontFamily: "var(--font-itim), cursive",
    fontSize: "24px",
    fontStyle: "normal",
    fontWeight: 400,
    lineHeight: 1.1,
    display: "inline-flex",
    minWidth: "2ch",
    justifyContent: "center",
});

const LaneProgressTrack = styled("div")({
    position: "relative",
    width: "100%",
    maxWidth: "640px",
    height: "8px",
    borderRadius: "999px",
    backgroundColor: "rgba(193, 246, 235, 0.32)",
    cursor: "pointer",
    "@media (max-width: 900px)": { maxWidth: "320px" },
    [`@media (max-width: ${MOBILE_LAYOUT_BREAKPOINT_PX}px)`]: {
        maxWidth: "248px",
    },
});

const LaneProgressFill = styled("div")({
    position: "absolute",
    left: 0,
    top: 0,
    bottom: 0,
    borderRadius: "999px",
    backgroundColor: "#62d049",
});

const LaneProgressThumb = styled("div")({
    position: "absolute",
    top: "50%",
    width: "20px",
    height: "20px",
    borderRadius: "999px",
    backgroundColor: "white",
    boxShadow: "0 2px 12px rgba(0, 0, 0, 0.35)",
    transform: "translate(-50%, -50%)",
});

/**
 * Play/pause glyph used by the share viewer's playback button.
 * Used by `MemoryViewer`.
 */
export const PlaybackGlyph: React.FC<{ paused: boolean }> = ({ paused }) => {
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

/**
 * Smaller play/pause glyph sized for the lane viewer footer controls.
 * Used by `LaneMemoryViewer`.
 */
export const LanePlaybackGlyph: React.FC<{ paused: boolean }> = ({
    paused,
}) => {
    if (paused) {
        return (
            <Box
                sx={{
                    width: 0,
                    height: 0,
                    borderTop: "5px solid transparent",
                    borderBottom: "5px solid transparent",
                    borderLeft: "8px solid white",
                    ml: "2px",
                }}
            />
        );
    }

    return (
        <Box sx={{ display: "flex", gap: "3px" }}>
            <Box
                sx={{
                    width: "3px",
                    height: "10px",
                    borderRadius: "1px",
                    backgroundColor: "white",
                }}
            />
            <Box
                sx={{
                    width: "3px",
                    height: "10px",
                    borderRadius: "1px",
                    backgroundColor: "white",
                }}
            />
        </Box>
    );
};

/**
 * Formats and renders the lane caption text, including the animated numeric counter state.
 * Used by `LaneMemoryViewer`.
 */
export const LaneCaptionText: React.FC<{
    model: LaneCaptionModel;
    previousValue?: number;
}> = ({ model, previousValue }) => {
    if (typeof model.value !== "number") {
        return <>{model.text}</>;
    }

    const currentValue = model.value;
    const formattedValue = new Intl.NumberFormat().format(currentValue);
    const formattedPrevious = new Intl.NumberFormat().format(
        previousValue ?? currentValue,
    );

    return (
        <LaneCaptionInline>
            {model.prefix}
            <LaneCaptionNumber
                key={`${formattedPrevious}->${formattedValue}`}
                style={{
                    transition:
                        "transform 320ms cubic-bezier(0.22, 1, 0.36, 1)",
                    transform:
                        previousValue === currentValue
                            ? "translateY(0)"
                            : "translateY(0)",
                }}
            >
                {formattedValue}
            </LaneCaptionNumber>
            {model.suffix}
        </LaneCaptionInline>
    );
};

interface LaneProgressSliderProps {
    total: number;
    current?: number;
    currentProgress?: number;
    onSeek: (index: number) => void;
    onScrubStart?: () => void;
    onScrub?: (value: number) => void;
    onScrubEnd?: (value: number) => void;
}

/**
 * Scrubbable progress control for lane shares.
 * Used by `LaneMemoryViewer`.
 */
export const LaneProgressSlider: React.FC<LaneProgressSliderProps> = ({
    total,
    current,
    currentProgress,
    onSeek,
    onScrubStart,
    onScrub,
    onScrubEnd,
}) => {
    const progressPercentage = useMemo(() => {
        if (total <= 1) {
            return 0;
        }
        const value = currentProgress ?? current ?? 0;
        return (value / (total - 1)) * 100;
    }, [current, currentProgress, total]);

    const [draggingPointerId, setDraggingPointerId] = useState<number | null>(
        null,
    );

    const getScrubValue = useCallback(
        (event: React.PointerEvent<HTMLDivElement>) => {
            const rect = event.currentTarget.getBoundingClientRect();
            if (rect.width <= 0 || total <= 1) {
                return 0;
            }
            const ratio = (event.clientX - rect.left) / rect.width;
            return Math.min(Math.max(ratio, 0), 1) * (total - 1);
        },
        [total],
    );

    const handlePointerDown = useCallback(
        (event: React.PointerEvent<HTMLDivElement>) => {
            event.stopPropagation();
            if (total <= 1) {
                return;
            }
            setDraggingPointerId(event.pointerId);
            event.currentTarget.setPointerCapture(event.pointerId);
            const value = getScrubValue(event);
            onScrubStart?.();
            onScrub?.(value);
        },
        [getScrubValue, onScrub, onScrubStart, total],
    );

    const handlePointerMove = useCallback(
        (event: React.PointerEvent<HTMLDivElement>) => {
            if (draggingPointerId !== event.pointerId) {
                return;
            }
            event.stopPropagation();
            onScrub?.(getScrubValue(event));
        },
        [draggingPointerId, getScrubValue, onScrub],
    );

    const endScrub = useCallback(
        (event: React.PointerEvent<HTMLDivElement>) => {
            if (draggingPointerId !== event.pointerId) {
                return;
            }
            event.stopPropagation();
            const value = getScrubValue(event);
            event.currentTarget.releasePointerCapture(event.pointerId);
            setDraggingPointerId(null);
            onScrubEnd?.(value);
            if (!onScrubEnd) {
                onSeek(Math.round(value));
            }
        },
        [draggingPointerId, getScrubValue, onScrubEnd, onSeek],
    );

    return (
        <LaneProgressTrack
            data-memory-control="true"
            onPointerDown={handlePointerDown}
            onPointerMove={handlePointerMove}
            onPointerUp={endScrub}
            onPointerCancel={endScrub}
        >
            <LaneProgressFill style={{ width: `${progressPercentage}%` }} />
            <LaneProgressThumb style={{ left: `${progressPercentage}%` }} />
        </LaneProgressTrack>
    );
};

interface ProgressIndicatorProps {
    total: number;
    current: number;
    paused: boolean;
    duration: number;
    onComplete: () => void;
    isVideo?: boolean;
    compact?: boolean;
    minimal?: boolean;
}

/**
 * Segmented autoplay progress bar for the share viewer header.
 * Used by `MemoryViewer`.
 */
export const ProgressIndicator: React.FC<ProgressIndicatorProps> = ({
    total,
    current,
    paused,
    duration,
    onComplete,
    isVideo,
    compact,
    minimal,
}) => {
    const segments = useMemo(
        () => Array.from({ length: total }, (_, i) => i),
        [total],
    );
    const progressGap = total > 15 ? "4px" : minimal ? "8px" : "12px";
    const progressHeight = minimal ? "2px" : "4px";
    const compactMinimalProgressGap = total > 15 ? "3px" : "6px";
    const progressTrackOpacity = minimal ? 0.24 : 0.45;
    const progressFillColor = minimal ? "rgba(255, 255, 255, 0.78)" : "white";

    return (
        <Box
            sx={{
                display: "flex",
                gap: progressGap,
                alignItems: "center",
                width: "100%",
                maxWidth: compact
                    ? `${MOBILE_PROGRESS_MAX_WIDTH_PX}px`
                    : minimal
                      ? `${MINIMAL_DESKTOP_PROGRESS_MAX_WIDTH_PX}px`
                      : `${DESKTOP_PROGRESS_MAX_WIDTH_PX}px`,
                minWidth: 0,
                height: progressHeight,
                ...(minimal && {
                    [`@media (max-width: ${MINIMAL_PROGRESS_COMPACT_BREAKPOINT_PX}px)`]:
                        {
                            gap: compactMinimalProgressGap,
                            maxWidth: `${MINIMAL_PROGRESS_COMPACT_MAX_WIDTH_PX}px`,
                            height: "1.5px",
                        },
                }),
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
                    height={progressHeight}
                    minimal={minimal}
                    trackOpacity={progressTrackOpacity}
                    fillColor={progressFillColor}
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
    height: string;
    minimal?: boolean;
    trackOpacity: number;
    fillColor: string;
    onComplete?: () => void;
}

/**
 * Single progress segment used to build `ProgressIndicator`.
 * Used only within `PublicMemoryControls.tsx`.
 */
const ProgressBar: React.FC<ProgressBarProps> = ({
    state,
    paused,
    duration,
    height,
    minimal,
    trackOpacity,
    fillColor,
    onComplete,
}) => {
    return (
        <Box
            sx={{
                position: "relative",
                flex: 1,
                minWidth: 0,
                height,
                borderRadius: "999px",
                backgroundColor: `rgba(255, 255, 255, ${trackOpacity})`,
                overflow: "hidden",
                ...(minimal && {
                    [`@media (max-width: ${MINIMAL_PROGRESS_COMPACT_BREAKPOINT_PX}px)`]:
                        {
                            height: "1.5px",
                        },
                }),
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
                    borderRadius: "999px",
                    backgroundColor: fillColor,
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
