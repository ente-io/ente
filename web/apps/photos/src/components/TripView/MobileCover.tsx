import { Box, Skeleton, styled, Typography } from "@mui/material";
import Image from "next/image";
import { memo } from "react";
import type { JourneyPoint } from "./types";

interface MobileCoverProps {
    journeyData: JourneyPoint[];
    photoClusters: JourneyPoint[][];
    albumTitle?: string;
    coverImageUrl?: string | null;
}

export const MobileCover = memo<MobileCoverProps>(
    ({ journeyData, photoClusters, albumTitle, coverImageUrl }) => {
        const sortedData = [...journeyData].sort(
            (a, b) =>
                new Date(a.timestamp).getTime() -
                new Date(b.timestamp).getTime(),
        );
        const firstData = sortedData[0];
        const lastData = sortedData[sortedData.length - 1];
        if (!firstData || !lastData) {
            return null;
        }
        const firstDate = new Date(firstData.timestamp);
        const lastDate = new Date(lastData.timestamp);
        const diffTime = Math.abs(lastDate.getTime() - firstDate.getTime());
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        const monthYear = firstDate.toLocaleDateString("en-US", {
            month: "long",
            year: "numeric",
        });

        return (
            <MobileCoverContainer>
                {coverImageUrl ? (
                    <>
                        <Image
                            src={coverImageUrl}
                            alt="Trip Cover"
                            fill
                            style={{ objectFit: "cover" }}
                            sizes="100vw"
                        />
                        <GradientOverlay />
                    </>
                ) : (
                    <Skeleton
                        variant="rectangular"
                        width="100%"
                        height="100%"
                        sx={{ bgcolor: "#f5f5f5" }}
                    />
                )}

                <ContentContainer>
                    {coverImageUrl ? (
                        <>
                            <TripTitle>{albumTitle || "Trip"}</TripTitle>
                            <TripSubtitle>
                                {monthYear} • {diffDays} days •{" "}
                                {photoClusters.length} locations
                            </TripSubtitle>
                        </>
                    ) : (
                        <>
                            <Skeleton
                                variant="text"
                                width="200px"
                                height="40px"
                                sx={{
                                    mb: "5px",
                                    bgcolor: "rgba(255,255,255,0.95)",
                                }}
                            />
                            <Skeleton
                                variant="text"
                                width="270px"
                                height="24px"
                                sx={{
                                    mb: "20px",
                                    bgcolor: "rgba(255,255,255,0.7)",
                                }}
                            />
                        </>
                    )}
                </ContentContainer>
            </MobileCoverContainer>
        );
    },
);

const MobileCoverContainer = styled(Box)({
    position: "relative",
    width: "100%",
    height: "100%",
    backgroundColor: "#e0e0e0",
});

const GradientOverlay = styled(Box)({
    position: "absolute",
    inset: 0,
    background:
        "linear-gradient(to bottom, rgba(0,0,0,0.3), transparent 30%, transparent 65%, rgba(0,0,0,0.9))",
});

const ContentContainer = styled(Box)({
    position: "absolute",
    bottom: "20px",
    left: "20px",
    right: "20px",
    color: "white",
});

const TripTitle = styled(Typography)({
    fontSize: "28px",
    fontWeight: "bold",
    marginBottom: "12px",
    component: "h1",
});

const TripSubtitle = styled(Typography)({
    color: "rgba(255, 255, 255, 0.8)",
    fontSize: "15px",
    fontWeight: "600",
    paddingBottom: "20px",
});
