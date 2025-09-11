import { Box, styled } from "@mui/material";
import { memo } from "react";
import type { JourneyPoint } from "./types";

interface TimelineProgressLineProps {
    locationPositions: { top: number; center: number }[];
    scrollProgress: number;
    hasUserScrolled: boolean;
    photoClusters: JourneyPoint[][];
}

export const TimelineProgressLine = memo<TimelineProgressLineProps>(({
    locationPositions,
    scrollProgress,
    hasUserScrolled,
    photoClusters,
}) => {
    if (photoClusters.length === 0 || locationPositions.length === 0) {
        return null;
    }

    const firstPosition = locationPositions[0];
    const lastPosition = locationPositions[locationPositions.length - 1];
    if (!firstPosition || !lastPosition) {
        return null;
    }
    const firstLocationCenter = firstPosition.center;
    const lastLocationCenter = lastPosition.center;

    if (scrollProgress <= 0 || !hasUserScrolled) {
        return null;
    }

    return (
        <ProgressLine
            sx={{
                top: `${firstLocationCenter}px`,
                height: `${
                    (lastLocationCenter - firstLocationCenter) *
                    scrollProgress
                }px`,
            }}
        />
    );
});

// Styled components
const ProgressLine = styled(Box)(({ theme }) => ({
    position: "absolute",
    left: "50%",
    transform: "translateX(-1.5px)",
    width: "3px",
    backgroundColor: theme.palette.success.main,
}));