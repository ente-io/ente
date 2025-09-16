import { memo } from "react";
import type { JourneyPoint } from "./types";

interface TimelineProgressLineProps {
    locationPositions: { top: number; center: number }[];
    scrollProgress: number;
    hasUserScrolled: boolean;
    photoClusters: JourneyPoint[][];
}

export const TimelineProgressLine = memo<TimelineProgressLineProps>(() => {
    // No longer showing progressive green line - green indicators only for current location
    return null;
});
