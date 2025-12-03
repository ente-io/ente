import CheckIcon from "@mui/icons-material/Check";
import { Box, IconButton, Typography } from "@mui/material";
import { Copy01Icon } from "hugeicons-react";
import React, { useState } from "react";

interface CopyableFieldProps {
    label?: string;
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
    const [copied, setCopied] = useState(false);

    const handleCopy = () => {
        onCopy(value);
        setCopied(true);
        setTimeout(() => {
            setCopied(false);
        }, 2000);
    };

    return (
        <Box>
            {label && (
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
            )}
            <Box sx={{ position: "relative" }}>
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
                {copied ? (
                    <Box
                        sx={{
                            position: "absolute",
                            top: multiline ? 8 : "50%",
                            right: 8,
                            transform: multiline ? "none" : "translateY(-50%)",
                            color: "#4caf50",
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            p: 1,
                        }}
                    >
                        <CheckIcon fontSize="small" />
                    </Box>
                ) : (
                    <IconButton
                        onClick={handleCopy}
                        sx={{
                            position: "absolute",
                            top: multiline ? 8 : "50%",
                            right: 8,
                            transform: multiline ? "none" : "translateY(-50%)",
                            color: "#757575",
                            "&:hover": { bgcolor: "rgba(0, 0, 0, 0.04)" },
                        }}
                    >
                        <Copy01Icon size={16} />
                    </IconButton>
                )}
            </Box>
        </Box>
    );
};
