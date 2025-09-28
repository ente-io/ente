import { Box, styled } from "@mui/material";
import { memo } from "react";
import type { JourneyPoint } from "./types";

interface TripStartedSectionProps {
    journeyData: JourneyPoint[];
}

export const TripStartedSection = memo<TripStartedSectionProps>(
    ({ journeyData }) => {
        const sortedData = [...journeyData].sort(
            (a, b) =>
                new Date(a.timestamp).getTime() -
                new Date(b.timestamp).getTime(),
        );
        const firstData = sortedData[0];
        if (!firstData) {
            return null;
        }
        const firstDate = new Date(firstData.timestamp);

        return (
            <SectionContainer>
                <TripStartedLabel>Trip started</TripStartedLabel>
                <br />
                <DateLabel>
                    {firstDate.toLocaleDateString("en-US", {
                        month: "long",
                        day: "2-digit",
                    })}
                </DateLabel>

                <StartingDot />
            </SectionContainer>
        );
    },
);

// Styled components
const SectionContainer = styled(Box)({
    position: "relative",
    marginTop: "32px",
    marginBottom: "100px",
    textAlign: "center",
    zIndex: 1,
});

const TripStartedLabel = styled(Box)(({ theme }) => ({
    fontSize: "20px",
    fontWeight: "600",
    color: theme.palette.text.primary,
    marginBottom: "2px",
    lineHeight: "1.2",
    backgroundColor: theme.palette.background.paper,
    padding: "4px 8px",
    borderRadius: "4px",
    display: "inline-block",
}));

const DateLabel = styled(Box)(({ theme }) => ({
    fontSize: "14px",
    color: theme.palette.text.secondary,
    backgroundColor: theme.palette.background.paper,
    padding: "2px 6px",
    borderRadius: "4px",
    display: "inline-block",
    marginTop: "0px",
}));

const StartingDot = styled(Box)(({ theme }) => ({
    position: "absolute",
    left: "50%",
    top: "80px",
    transform: "translate(-50%, 0)",
    borderRadius: "50%",
    border: `2px solid ${theme.palette.background.paper}`,
    zIndex: 20,
    width: "12px",
    height: "12px",
    backgroundColor: theme.palette.grey[300],
}));
