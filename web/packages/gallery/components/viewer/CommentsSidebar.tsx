import CloseIcon from "@mui/icons-material/Close";
import {
    Box,
    Drawer,
    IconButton,
    Stack,
    styled,
    TextField,
    Typography,
} from "@mui/material";
import { type ModalVisibilityProps } from "ente-base/components/utils/modal";
import { t } from "i18next";
import React, { useState } from "react";

const SendIcon: React.FC = () => (
    <svg
        width="18"
        height="16"
        viewBox="0 0 15 13"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
    >
        <path
            d="M2.03872 4.50697L2.47372 5.26697C2.75072 5.75197 2.88872 5.99397 2.88872 6.25997C2.88872 6.52597 2.75072 6.76797 2.47372 7.25197L2.03872 8.01297C0.800717 10.18 0.181717 11.263 0.663717 11.801C1.14672 12.338 2.29072 11.838 4.57672 10.838L10.8527 8.09197C12.6477 7.30697 13.5457 6.91397 13.5457 6.25997C13.5457 5.60597 12.6477 5.21297 10.8527 4.42797L4.57672 1.68197C2.29072 0.681968 1.14672 0.181968 0.663717 0.718968C0.181717 1.25597 0.800717 2.33897 2.03872 4.50697Z"
            stroke="black"
            strokeOpacity="0.8"
        />
    </svg>
);

export type CommentsSidebarProps = ModalVisibilityProps;

/**
 * A sidebar panel for displaying and managing comments on a file.
 */
export const CommentsSidebar: React.FC<CommentsSidebarProps> = ({
    open,
    onClose,
}) => {
    const [comment, setComment] = useState("");

    const handleSend = () => {
        if (!comment.trim()) return;

        // TODO: Call API to store comment
        setComment("");
    };

    return (
        <CommentsSidebarDrawer open={open} onClose={onClose} anchor="right">
            <Stack
                direction="row"
                sx={{
                    alignItems: "center",
                    justifyContent: "space-between",
                    mb: 2,
                }}
            >
                <Typography sx={{ color: "#000", fontWeight: 600 }}>
                    {`12 ${t("comments")}`}
                </Typography>
                <IconButton
                    onClick={onClose}
                    sx={{
                        backgroundColor: "#F5F5F7",
                        color: "#000",
                        padding: "8px",
                        "&:hover": {
                            backgroundColor: "#E5E5E7",
                        },
                    }}
                >
                    <CloseIcon sx={{ fontSize: 22 }} />
                </IconButton>
            </Stack>
            <Stack sx={{ flex: 1 }}>
                {/* Comments content will go here */}
            </Stack>
            <CommentInputContainer>
                <CommentInputWrapper>
                    <CommentInput
                        fullWidth
                        multiline
                        minRows={1}
                        placeholder="Say something nice!"
                        variant="standard"
                        value={comment}
                        onChange={(e) => setComment(e.target.value)}
                    />
                </CommentInputWrapper>
                <IconButton
                    sx={{
                        position: "absolute",
                        right: 12,
                        bottom: 8.5,
                        color: "#000",
                        width: 42,
                        height: 42,
                        "&:hover": {
                            backgroundColor: "rgba(0, 0, 0, 0.1)",
                        },
                    }}
                    onClick={handleSend}
                >
                    <SendIcon />
                </IconButton>
            </CommentInputContainer>
        </CommentsSidebarDrawer>
    );
};

const CommentsSidebarDrawer = styled(Drawer)(() => ({
    "& .MuiDrawer-paper": {
        width: "500px",
        maxWidth: "calc(100% - 32px)",
        height: "calc(100% - 32px)",
        margin: "16px",
        borderRadius: "36px",
        backgroundColor: "#fff",
        padding: "32px",
        boxShadow: "none",
        // Mobile view: full screen, no margin, no rounded corners
        "@media (max-width: 450px)": {
            width: "100%",
            maxWidth: "100%",
            height: "100%",
            margin: 0,
            borderRadius: 0,
        },
    },
    // No backdrop overlay
    "& .MuiBackdrop-root": {
        backgroundColor: "transparent",
    },
}));

const CommentInputContainer = styled(Box)(() => ({
    position: "relative",
    backgroundColor: "#F3F3F3",
    borderRadius: "20px",
    border: "2px solid rgba(0, 0, 0, 0.008)",
    margin: "-16px",
    marginTop: 0,
}));

const CommentInputWrapper = styled(Box)(() => ({
    padding: "8px 48px 8px 16px",
    maxHeight: "300px",
    overflow: "auto",
    "&::-webkit-scrollbar": {
        width: "8px",
    },
    "&::-webkit-scrollbar-track": {
        background: "transparent",
    },
    "&::-webkit-scrollbar-thumb": {
        background: "rgba(0, 0, 0, 0.3)",
        borderRadius: "4px",
    },
    "&::-webkit-scrollbar-thumb:hover": {
        background: "rgba(0, 0, 0, 0.5)",
    },
    scrollbarWidth: "thin",
    scrollbarColor: "rgba(0, 0, 0, 0.3) transparent",
}));

const CommentInput = styled(TextField)(() => ({
    "& .MuiInput-root": {
        "&::before, &::after": {
            display: "none",
        },
    },
    "& .MuiInputBase-input": {
        padding: 0,
        color: "#000",
        "&::placeholder": {
            color: "#666",
            opacity: 1,
        },
    },
}));
