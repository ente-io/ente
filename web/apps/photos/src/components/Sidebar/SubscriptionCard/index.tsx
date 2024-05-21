import { FlexWrapper, Overlay } from "@ente/shared/components/Container";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import { Box, Skeleton } from "@mui/material";
import { UserDetails } from "types/user";
import { SubscriptionCardContentOverlay } from "./contentOverlay";

const SUBSCRIPTION_CARD_SIZE = 152;

interface Iprops {
    userDetails: UserDetails;
    onClick: () => void;
}

export default function SubscriptionCard({ userDetails, onClick }: Iprops) {
    if (!userDetails) {
        return (
            <Skeleton
                animation="wave"
                variant="rectangular"
                height={SUBSCRIPTION_CARD_SIZE}
                sx={{ borderRadius: "8px" }}
            />
        );
    }

    return (
        <Box position="relative">
            <BackgroundOverlay />
            <SubscriptionCardContentOverlay userDetails={userDetails} />
            <ClickOverlay onClick={onClick} />
        </Box>
    );
}

function BackgroundOverlay() {
    return (
        <img
            style={{ aspectRatio: "2/1" }}
            width="100%"
            src="/images/subscription-card-background/1x.png"
            srcSet="/images/subscription-card-background/2x.png 2x,
                        /images/subscription-card-background/3x.png 3x"
        />
    );
}

function ClickOverlay({ onClick }) {
    return (
        <Overlay display="flex">
            <FlexWrapper
                onClick={onClick}
                justifyContent={"flex-end"}
                sx={{ cursor: "pointer" }}
            >
                <ChevronRightIcon />
            </FlexWrapper>
        </Overlay>
    );
}
