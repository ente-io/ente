import { CenteredFlex } from "@/base/components/containers";
import { CopyButton } from "@/base/components/CopyButton";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { Box, Typography } from "@mui/material";
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
            <CenteredFlex sx={{ minHeight: "80px" }}>
                <ActivityIndicator />
            </CenteredFlex>
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
                <CopyButton color="accentContrastText" code={code} />
            </Box>
        </Box>
    );
};
