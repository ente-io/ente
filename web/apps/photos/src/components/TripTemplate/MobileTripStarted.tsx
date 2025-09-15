import { Box, styled, Typography } from "@mui/material";
import { memo } from "react";

interface MobileTripStartedProps {
    onRef: (el: HTMLDivElement | null) => void;
}

export const MobileTripStarted = memo<MobileTripStartedProps>(({ onRef }) => {
    return (
        <MobileTripStartedContainer ref={onRef}>
            <MobileTripStartedContent>
                <MobileTripStartedText>Trip Started</MobileTripStartedText>
            </MobileTripStartedContent>
            <MobileTripStartedLine />
        </MobileTripStartedContainer>
    );
});

const MobileTripStartedContainer = styled(Box)({
    position: "relative",
    minHeight: "100vh",
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
    scrollSnapAlign: "start",
    padding: "40px 20px",
});

const MobileTripStartedContent = styled(Box)({
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    marginBottom: "60px",
});

const MobileTripStartedText = styled(Typography)(({ theme }) => ({
    fontSize: "24px",
    fontWeight: "600",
    color: theme.palette.success.main,
    backgroundColor: theme.palette.background.paper,
    padding: "16px 32px",
    borderRadius: "30px",
    border: `3px solid ${theme.palette.success.main}`,
    boxShadow: "0 4px 20px rgba(0, 0, 0, 0.1)",
    textAlign: "center",
}));

const MobileTripStartedLine = styled(Box)(({ theme }) => ({
    position: "absolute",
    left: "50%",
    top: "70%",
    bottom: "0",
    width: "4px",
    backgroundColor: theme.palette.success.main,
    transform: "translateX(-50%)",
    borderRadius: "2px",
}));