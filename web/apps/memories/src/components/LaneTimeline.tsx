import { styled } from "@mui/material";
import { useRef } from "react";

interface LaneTimelineProps {
    total: number;
    currentProgress: number;
    width: number;
    onSeek: (index: number) => void;
    onScrubStart: () => void;
    onScrub: (value: number) => void;
    onScrubEnd: (value: number) => void;
}

export function LaneTimeline({
    total,
    currentProgress,
    width,
    onSeek,
    onScrubStart,
    onScrub,
    onScrubEnd,
}: LaneTimelineProps) {
    const dragging = useRef(false);
    const value = useRef(currentProgress);
    value.current = currentProgress;
    const dotCount = Math.min(total, Math.max(1, Math.floor((width + 5) / 20)));
    const activeDot = Math.min(
        dotCount - 1,
        Math.floor((Math.round(currentProgress) * dotCount) / total),
    );
    const endDrag = () => {
        if (!dragging.current) return;
        dragging.current = false;
        onScrubEnd(value.current);
    };
    return (
        <Timeline style={{ width }} data-memory-control="true">
            <Dots aria-hidden="true">
                {Array.from({ length: dotCount }, (_, index) => {
                    const distance = Math.abs(index - activeDot);
                    const size =
                        distance === 0
                            ? 15
                            : distance === 1
                              ? 10
                              : distance === 2
                                ? 7.5
                                : 5;
                    return (
                        <DotSlot key={index}>
                            <Dot
                                style={{
                                    width: size,
                                    height: size,
                                    opacity: distance === 0 ? 1 : 0.5,
                                }}
                            />
                        </DotSlot>
                    );
                })}
            </Dots>
            <TimelineInput
                type="range"
                min={0}
                max={Math.max(0, total - 1)}
                step={1}
                value={Math.round(currentProgress)}
                disabled={total <= 1}
                aria-label="Memory timeline"
                aria-valuetext={`Photo ${Math.round(currentProgress) + 1} of ${total}`}
                onPointerDown={(event) => {
                    if (event.button !== 0 || total <= 1) return;
                    dragging.current = true;
                    event.currentTarget.setPointerCapture(event.pointerId);
                    onScrubStart();
                }}
                onChange={(event) => {
                    value.current = Number(event.currentTarget.value);
                    if (dragging.current) onScrub(value.current);
                    else onSeek(value.current);
                }}
                onPointerUp={endDrag}
                onPointerCancel={endDrag}
                onLostPointerCapture={endDrag}
                onBlur={endDrag}
                onKeyDown={(event) => event.stopPropagation()}
            />
        </Timeline>
    );
}

const Timeline = styled("div")({
    position: "relative",
    maxWidth: "100%",
    height: 44,
    flexShrink: 0,
    borderRadius: 999,
    "&::before": {
        content: '""',
        position: "absolute",
        insetInline: 0,
        insetBlock: 4,
        borderRadius: "inherit",
        background: "rgba(255,255,255,.14)",
        pointerEvents: "none",
    },
    "&:has(input:focus-visible)": {
        outline: "2px solid rgba(255,255,255,.85)",
        outlineOffset: 4,
    },
});
const Dots = styled("div")({
    position: "absolute",
    inset: 0,
    display: "flex",
    alignItems: "center",
    gap: 5,
    paddingInline: 12,
    pointerEvents: "none",
});
const DotSlot = styled("span")({
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
    flex: 1,
});
const Dot = styled("span")({
    display: "block",
    borderRadius: "50%",
    background: "white",
    transition: "width 200ms,height 200ms,opacity 200ms",
    "@media(prefers-reduced-motion:reduce)": { transition: "none" },
});
const TimelineInput = styled("input")({
    position: "absolute",
    inset: 0,
    margin: 0,
    width: "100%",
    height: "100%",
    opacity: 0,
    cursor: "pointer",
    touchAction: "none",
});
