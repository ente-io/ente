import { pt, ut } from "@/base/i18n";
import { EnteDrawer } from "@/new/shared/components/EnteDrawer";
import { Titlebar } from "@/new/shared/components/Titlebar";
import { Box, Stack, Typography, type DialogProps } from "@mui/material";
import React from "react";

interface MLSettingsBetaProps {
    /** If `true`, then this drawer page is shown. */
    open: boolean;
    /** Called when the user wants to go back from this drawer page. */
    onClose: () => void;
    /** Called when the user wants to close the entire stack of drawers. */
    onRootClose: () => void;
}

export const MLSettingsBeta: React.FC<MLSettingsBetaProps> = ({
    open,
    onClose,
    onRootClose,
}) => {
    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason == "backdropClick") handleRootClose();
        else onClose();
    };

    return (
        <Box>
            <EnteDrawer
                anchor="left"
                transitionDuration={0}
                open={open}
                onClose={handleDrawerClose}
                BackdropProps={{
                    sx: { "&&&": { backgroundColor: "transparent" } },
                }}
            >
                <Stack spacing={"4px"} py={"12px"}>
                    <Titlebar
                        onClose={onClose}
                        title={pt("ML search")}
                        onRootClose={onRootClose}
                    />

                    <Box px="8px">
                        <Typography color="text.muted">
                            {ut(
                                "We're putting finishing touches, coming back soon!",
                            )}
                        </Typography>
                    </Box>
                </Stack>
            </EnteDrawer>
        </Box>
    );
};
