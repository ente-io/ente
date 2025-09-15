import { Box, styled, Typography } from "@mui/material";
import { memo } from "react";

interface TripStartedProps {
    onRef: (el: HTMLDivElement | null) => void;
}

export const TripStarted = memo<TripStartedProps>(({ onRef }) => {
    return (
        <TripStartedContainer ref={onRef}>
            <TripStartedContent>
                <TripStartedText>Trip Started</TripStartedText>
            </TripStartedContent>
            <TripStartedLine />
        </TripStartedContainer>
    );
});

const TripStartedContainer = styled(Box)({
    position: "relative",
    marginBottom: "32px",
    paddingTop: "24px",
});

const TripStartedContent = styled(Box)({
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    paddingLeft: "32px",
    paddingRight: "32px",
});

const TripStartedText = styled(Typography)(({ theme }) => ({
    fontSize: "18px",
    fontWeight: "600",
    color: theme.palette.success.main,
    backgroundColor: theme.palette.background.paper,
    padding: "8px 16px",
    borderRadius: "20px",
    border: `2px solid ${theme.palette.divider}`,
}));

const TripStartedLine = styled(Box)(({ theme }) => ({
    position: "absolute",
    left: "50%",
    top: "60px",
    bottom: "-32px",
    width: "2px",
    backgroundColor: theme.palette.divider,
    transform: "translateX(-50%)",
}));