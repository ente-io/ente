import CloseIcon from "@mui/icons-material/Close";
import { Box, Drawer, IconButton, Stack, styled, Typography } from "@mui/material";
import { type ModalVisibilityProps } from "ente-base/components/utils/modal";
import React from "react";

// =============================================================================
// Types
// =============================================================================

export interface FeedSidebarProps extends ModalVisibilityProps {
    /**
     * The name of the album to display in the header.
     */
    albumName: string;
}

// =============================================================================
// Main Component
// =============================================================================

/**
 * A sidebar panel for displaying the feed for an album.
 */
export const FeedSidebar: React.FC<FeedSidebarProps> = ({
    open,
    onClose,
    albumName,
}) => {
    return (
        <SidebarDrawer open={open} onClose={onClose} anchor="right">
            <DrawerContentWrapper>
                <Header>
                    <Typography
                        sx={(theme) => ({
                            color: "#000",
                            fontWeight: 600,
                            ...theme.applyStyles("dark", { color: "#fff" }),
                        })}
                    >
                        {albumName}
                    </Typography>
                    <CloseButton onClick={onClose}>
                        <CloseIcon sx={{ fontSize: 22 }} />
                    </CloseButton>
                </Header>

                <ContentContainer>
                    {/* Main content will be added later */}
                </ContentContainer>
            </DrawerContentWrapper>
        </SidebarDrawer>
    );
};

// =============================================================================
// Styled Components
// =============================================================================

// Drawer & Layout
const SidebarDrawer = styled(Drawer)(({ theme }) => ({
    "& .MuiDrawer-paper": {
        width: "23vw",
        minWidth: "520px",
        maxWidth: "calc(100% - 32px)",
        height: "calc(100% - 32px)",
        margin: "16px",
        borderRadius: "36px",
        backgroundColor: "#fff",
        padding: "24px 24px 32px 24px",
        boxShadow: "none",
        border: "1px solid #E0E0E0",
        display: "flex",
        flexDirection: "column",
        overflow: "visible",
        "@media (max-width: 450px)": {
            width: "100%",
            minWidth: "unset",
            maxWidth: "100%",
            height: "100%",
            margin: 0,
            borderRadius: 0,
        },
        ...theme.applyStyles("dark", {
            backgroundColor: "#1b1b1b",
            border: "1px solid rgba(255, 255, 255, 0.18)",
        }),
    },
    "& .MuiBackdrop-root": { backgroundColor: "transparent" },
}));

const DrawerContentWrapper = styled(Box)(() => ({
    position: "relative",
    display: "flex",
    flexDirection: "column",
    flex: 1,
    minHeight: 0,
}));

const Header = styled(Stack)(() => ({
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 48,
}));

const CloseButton = styled(IconButton)(({ theme }) => ({
    backgroundColor: "#F5F5F7",
    color: "#000",
    padding: "8px",
    "&:hover": { backgroundColor: "#E5E5E7" },
    ...theme.applyStyles("dark", {
        backgroundColor: "rgba(255, 255, 255, 0.12)",
        color: "#fff",
        "&:hover": { backgroundColor: "rgba(255, 255, 255, 0.16)" },
    }),
}));

const ContentContainer = styled(Box)(({ theme }) => ({
    flex: 1,
    overflow: "auto",
    marginRight: -24,
    paddingRight: 24,
    "&::-webkit-scrollbar": { width: "6px" },
    "&::-webkit-scrollbar-track": { background: "transparent" },
    "&::-webkit-scrollbar-thumb": {
        background: "rgba(0, 0, 0, 0.2)",
        borderRadius: "3px",
    },
    scrollbarWidth: "thin",
    scrollbarColor: "rgba(0, 0, 0, 0.2) transparent",
    ...theme.applyStyles("dark", {
        "&::-webkit-scrollbar-thumb": {
            background: "rgba(255, 255, 255, 0.2)",
        },
        scrollbarColor: "rgba(255, 255, 255, 0.2) transparent",
    }),
}));
