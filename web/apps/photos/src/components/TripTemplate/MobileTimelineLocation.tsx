import { Box, Typography, styled } from "@mui/material";
import { memo } from "react";
import { PhotoFan } from "./PhotoFan";
import type { JourneyPoint } from "./types";

interface MobileTimelineLocationProps {
    cluster: JourneyPoint[];
    index: number;
    photoClusters: JourneyPoint[][];
    scrollProgress: number;
    journeyData: JourneyPoint[];
    onRef: (el: HTMLDivElement | null) => void;
    onPhotoClick?: (cluster: JourneyPoint[], fileId: number) => void;
}

export const MobileTimelineLocation = memo<MobileTimelineLocationProps>(
    ({
        cluster,
        index,
        photoClusters,
        scrollProgress,
        journeyData,
        onRef,
        onPhotoClick,
    }) => {
        const firstPhoto = cluster[0];
        if (!firstPhoto) return null;

        const sortedData = [...journeyData].sort(
            (a, b) =>
                new Date(a.timestamp).getTime() -
                new Date(b.timestamp).getTime(),
        );
        const firstData = sortedData[0];
        if (!firstData) return null;
        const firstDate = new Date(firstData.timestamp);
        const photoDate = new Date(firstPhoto.timestamp);

        const firstDateOnly = new Date(
            firstDate.getFullYear(),
            firstDate.getMonth(),
            firstDate.getDate(),
        );
        const photoDateOnly = new Date(
            photoDate.getFullYear(),
            photoDate.getMonth(),
            photoDate.getDate(),
        );
        const diffTime = photoDateOnly.getTime() - firstDateOnly.getTime();
        const dayNumber = Math.floor(diffTime / (1000 * 60 * 60 * 24)) + 1;

        // Show green for all covered locations (up to current position)
        const currentLocationIndex = Math.round(scrollProgress * Math.max(0, photoClusters.length - 1));
        const isCovered = index <= currentLocationIndex;

        return (
            <MobileLocationContainer
                ref={onRef}
                id={`location-${index}`}
                className="timeline-location"
            >
                {/* Centered Photo Fan Container */}
                <CenteredPhotoContainer>
                    <PhotoFanWrapper>
                        <PhotoFan
                            cluster={cluster}
                            onPhotoClick={onPhotoClick}
                        />

                        {/* Overlay text on top of main photo */}
                        <PhotoOverlay>
                            <DayBadge>
                                DAY {dayNumber} •{" "}
                                {new Date(firstPhoto.timestamp)
                                    .toLocaleDateString("en-US", {
                                        month: "long",
                                        day: "numeric",
                                    })
                                    .toUpperCase()}
                            </DayBadge>
                            <LocationTitle>
                                {firstPhoto.name}
                            </LocationTitle>
                            <LocationCountry>
                                {firstPhoto.country}
                            </LocationCountry>
                        </PhotoOverlay>
                    </PhotoFanWrapper>
                </CenteredPhotoContainer>

                {/* Dots positioned after the photo fan */}
                <DotsContainer>
                    <DotBackground />
                    <TimelineDot isReached={isCovered} />
                </DotsContainer>
            </MobileLocationContainer>
        );
    },
);

// Styled components
const MobileLocationContainer = styled(Box)({
    position: "relative",
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
    width: "100%",
    minHeight: "100vh",
    scrollSnapAlign: "start",
    padding: "40px 20px",
});

const CenteredPhotoContainer = styled(Box)({
    position: "relative",
    display: "flex",
    justifyContent: "center",
    marginBottom: "16px",
});

const PhotoFanWrapper = styled(Box)({
    position: "relative",
    width: "180px",
    height: "240px",
});

const PhotoOverlay = styled(Box)({
    position: "absolute",
    bottom: "0",
    left: "0",
    right: "0",
    zIndex: 30,
    pointerEvents: "none",
    background: "linear-gradient(to top, rgba(0, 0, 0, 0.7), rgba(0, 0, 0, 0.3), transparent)",
    borderRadius: "0 0 14px 14px",
    padding: "24px 16px 16px 16px",
});

const DotsContainer = styled(Box)({
    position: "relative",
    width: "32px",
    height: "32px",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    marginTop: "32px",
});

const DotBackground = styled(Box)(({ theme }) => ({
    position: "absolute",
    width: "32px",
    height: "32px",
    borderRadius: "50%",
    zIndex: 10,
    backgroundColor: theme.palette.background.paper,
    boxShadow: "0 2px 8px rgba(0, 0, 0, 0.1)",
}));

const TimelineDot = styled(Box, {
    shouldForwardProp: (prop) => prop !== 'isReached',
})<{ isReached: boolean }>(
    ({ theme, isReached }) => ({
        position: "absolute",
        borderRadius: "50%",
        border: `3px solid ${theme.palette.background.paper}`,
        zIndex: 20,
        width: "16px",
        height: "16px",
        transition: "all 0.3s",
        backgroundColor: isReached
            ? theme.palette.success.main
            : theme.palette.text.primary,
        boxShadow: isReached
            ? `0 0 0 4px ${theme.palette.success.main}30, 0 0 0 8px ${theme.palette.success.main}15`
            : "0 2px 8px rgba(0, 0, 0, 0.2)",
    }),
);

const DayBadge = styled(Box)(({ theme }) => ({
    display: "inline-flex",
    alignItems: "center",
    backgroundColor: "rgba(255, 255, 255, 0.95)",
    border: `1px solid ${theme.palette.grey[300]}`,
    borderRadius: "8px",
    padding: "4px 12px",
    marginBottom: "8px",
    fontSize: "10px",
    fontWeight: "600",
    color: theme.palette.text.secondary,
    textTransform: "uppercase",
    letterSpacing: "0.15em",
    backdropFilter: "blur(10px)",
    boxShadow: "0 2px 8px rgba(0, 0, 0, 0.1)",
}));

const LocationTitle = styled(Typography)(() => ({
    fontSize: "18px",
    fontWeight: "600",
    color: "white",
    margin: "0 0 4px 0",
    lineHeight: "1.2",
    textShadow: "0 2px 8px rgba(0, 0, 0, 0.5)",
    component: "h3",
}));

const LocationCountry = styled(Typography)(() => ({
    fontSize: "13px",
    color: "rgba(255, 255, 255, 0.9)",
    margin: "0",
    textShadow: "0 1px 4px rgba(0, 0, 0, 0.5)",
    component: "p",
}));