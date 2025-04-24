import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import DoneIcon from "@mui/icons-material/Done";
import { Box, IconButton, Tooltip, Typography } from "@mui/material";
import { CenteredRow } from "ente-base/components/containers";
import { ActivityIndicator } from "ente-base/components/mui/ActivityIndicator";
import { useClipboardCopy } from "ente-base/components/utils/hooks";
import { t } from "i18next";
import React from "react";

interface CodeBlockProps {
    /**
     * The code (an arbitrary string) to show.
     *
     * If not present, then an activity indicator will be shown.
     */
    code: string | undefined;
}

/**
 * A component that shows a "code" (e.g. the user's recovery key, or a 2FA setup
 * code), alongwith a button to copy it.
 */
export const CodeBlock: React.FC<CodeBlockProps> = ({ code }) => {
    if (!code) {
        return (
            <CenteredRow sx={{ minHeight: "80px" }}>
                <ActivityIndicator />
            </CenteredRow>
        );
    }

    return (
        <Box
            sx={{
                position: "relative",
                bgcolor: "accent.dark",
                borderRadius: 1,
            }}
        >
            <Typography
                sx={{
                    padding: "16px 44px 16px 16px",
                    wordBreak: "break-word",
                    color: "accent.contrastText",
                    // Increase the line height from the body default.
                    lineHeight: 1.5,
                }}
            >
                {code}
            </Typography>
            <Box sx={{ position: "absolute", top: 0, right: 0, mt: 1 }}>
                <CopyButton code={code} />
            </Box>
        </Box>
    );
};

interface CopyButtonProps {
    /**
     * The code to copy when the button is clicked.
     */
    code: string;
}

export const CopyButton: React.FC<CopyButtonProps> = ({ code }) => {
    const [copied, handleClick] = useClipboardCopy(code);

    const Icon = copied ? DoneIcon : ContentCopyIcon;

    return (
        <Tooltip arrow open={copied} title={t("copied")}>
            <IconButton onClick={handleClick}>
                <Icon sx={{ color: "accent.contrastText" }} fontSize="small" />
            </IconButton>
        </Tooltip>
    );
};
