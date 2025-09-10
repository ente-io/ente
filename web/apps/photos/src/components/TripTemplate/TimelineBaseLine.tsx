import { memo } from "react";

interface TimelineBaseLineProps {
    locationPositions: { top: number; center: number }[];
}

export const TimelineBaseLine = memo<TimelineBaseLineProps>(({
    locationPositions,
}) => {
    const timelineContainer = document.querySelector("#timeline-container");
    if (!timelineContainer || locationPositions.length === 0) {
        return null;
    }

    const locationElements =
        timelineContainer.querySelectorAll(".timeline-location");
    if (locationElements.length === 0) {
        return null;
    }

    const lastLocation = locationElements[
        locationElements.length - 1
    ] as HTMLElement;
    const lastLocationRect = lastLocation.getBoundingClientRect();
    const heightToLastDot =
        lastLocation.offsetTop + lastLocationRect.height / 2;

    const firstLocationCenter = locationPositions[0]?.center || 0;

    return (
        <>
            {/* Long dashed line from trip started dot to first location */}
            <div
                style={{
                    position: "absolute",
                    left: "50%",
                    transform: "translateX(-1.5px)",
                    width: "3px",
                    backgroundImage:
                        "linear-gradient(to bottom, #d1d5db 58%, transparent 58%)",
                    backgroundSize: "100% 22px",
                    backgroundRepeat: "repeat-y",
                    top: "-60px",
                    height: `${firstLocationCenter + 60}px`,
                    zIndex: 0,
                }}
            />
            {/* Solid line from first location to end */}
            <div
                style={{
                    position: "absolute",
                    left: "50%",
                    transform: "translateX(-1.5px)",
                    width: "3px",
                    backgroundColor: "#d1d5db",
                    top: `${firstLocationCenter}px`,
                    height: `${heightToLastDot - firstLocationCenter}px`,
                }}
            />
        </>
    );
});