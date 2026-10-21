import { keyframes } from "@emotion/react";
import { Box } from "@mui/material";
import { useMemo } from "react";

const DESKTOP_PROGRESS_MAX_WIDTH_PX = 448;
const MOBILE_PROGRESS_MAX_WIDTH_PX = 326;
const MINIMAL_DESKTOP_PROGRESS_MAX_WIDTH_PX = 392;
const MINIMAL_PROGRESS_COMPACT_BREAKPOINT_PX = 700;
const MINIMAL_PROGRESS_COMPACT_MAX_WIDTH_PX = 352;

const progressFillAnimation = keyframes`
    from { width: 0%; }
    to { width: 100%; }
`;

export const PlaybackGlyph: React.FC<{ paused: boolean }> = ({ paused }) => {
    if (paused) {
        return (
            <Box
                sx={{
                    width: 0,
                    height: 0,
                    borderTop: "12px solid transparent",
                    borderBottom: "12px solid transparent",
                    borderLeft: "17px solid white",
                    ml: "4px",
                }}
            />
        );
    }

    return (
        <Box sx={{ display: "flex", gap: "7px" }}>
            <Box
                sx={{
                    width: "7px",
                    height: "20px",
                    borderRadius: "2px",
                    backgroundColor: "white",
                }}
            />
            <Box
                sx={{
                    width: "7px",
                    height: "20px",
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
    isVideo?: boolean;
    compact?: boolean;
    minimal?: boolean;
}

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
                        { height: "1.5px" },
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
