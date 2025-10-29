import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import { Box, IconButton, Typography } from "@mui/material";
import React from "react";

interface CopyableFieldProps {
    label: string;
    value: string;
    onCopy: (value: string) => void;
    multiline?: boolean;
    maskValue?: boolean;
}

export const CopyableField: React.FC<CopyableFieldProps> = ({
    label,
    value,
    onCopy,
    multiline = false,
    maskValue = false,
}) => {
    return (
        <Box>
            <Typography
                variant="h6"
                sx={{
                    fontWeight: 500,
                    fontSize: "16px",
                    color: "#000000",
                    mb: 1,
                    mt: 3,
                }}
            >
                {label}
            </Typography>
            <Box
                sx={{
                    position: "relative",
                }}
            >
                <Box
                    sx={{
                        px: 4,
                        py: multiline ? 4 : 2,
                        bgcolor: "#FFFFFF",
                        borderRadius: "12px",
                    }}
                >
                    <Typography
                        variant="body"
                        sx={{
                            color: "#757575",
                            whiteSpace: "pre-wrap",
                            wordBreak: "break-word",
                        }}
                    >
                        {maskValue ? "**********************" : value}
                    </Typography>
                </Box>
                <IconButton
                    onClick={() => onCopy(value)}
                    sx={{
                        position: "absolute",
                        top: 8,
                        right: 8,
                        color: "#757575",
                        "&:hover": {
                            bgcolor: "rgba(0, 0, 0, 0.04)",
                        },
                    }}
                >
                    <ContentCopyIcon fontSize="small" />
                </IconButton>
            </Box>
        </Box>
    );
};
