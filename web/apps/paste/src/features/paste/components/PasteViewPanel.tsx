import { Alert02Icon } from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import ContentCopyRoundedIcon from "@mui/icons-material/ContentCopyRounded";
import {
    Box,
    Button,
    CircularProgress,
    Stack,
    TextField,
    Typography,
} from "@mui/material";
import { pasteTextFieldSx } from "./textFieldSx";

interface PasteViewPanelProps {
    consuming: boolean;
    consumeError: string | null;
    resolvedText: string | null;
    onCopyText: (value: string) => Promise<void>;
}

export const PasteViewPanel = ({
    consuming,
    consumeError,
    resolvedText,
    onCopyText,
}: PasteViewPanelProps) => {
    const frameBlue = "#2f6df7";
    const inputGlassBg = "rgba(39, 42, 52, 0.76)";
    const inputGlassBorder = "rgba(213, 225, 255, 0.14)";

    return (
        <>
            {consuming && (
                <Stack
                    spacing={1.1}
                    alignItems="center"
                    sx={{
                        width: "100%",
                        pt: { xs: 1.5, md: 2 },
                        pb: { xs: 0.5, md: 1 },
                    }}
                >
                    <CircularProgress
                        size={58}
                        thickness={4.5}
                        sx={{
                            color: "rgba(176, 198, 234, 0.76)",
                            mb: { xs: 0.7, md: 0.9 },
                        }}
                    />
                    <Typography
                        sx={{
                            color: "rgba(201, 212, 236, 0.66)",
                            fontWeight: 600,
                            fontSize: { xs: "1rem", md: "1.1rem" },
                            lineHeight: 1.2,
                            letterSpacing: "0.01em",
                            textAlign: "center",
                        }}
                    >
                        Opening secure paste...
                    </Typography>
                    <Typography
                        variant="mini"
                        sx={{
                            color: "rgba(188, 201, 230, 0.44)",
                            fontWeight: 500,
                            textAlign: "center",
                        }}
                    >
                        Decrypting in your browser.
                    </Typography>
                </Stack>
            )}

            {consumeError && (
                <Stack
                    spacing={1.25}
                    alignItems="center"
                    sx={{
                        width: "100%",
                        pt: { xs: 1.5, md: 2 },
                        pb: { xs: 0.5, md: 1 },
                    }}
                >
                    <HugeiconsIcon
                        icon={Alert02Icon}
                        size={56}
                        strokeWidth={2}
                        style={{ color: "rgba(180, 198, 232, 0.76)" }}
                    />
                    <Stack spacing={{ xs: 2.2, md: 2.6 }} alignItems="center">
                        <Typography
                            sx={{
                                maxWidth: 560,
                                color: "rgba(186, 201, 232, 0.46)",
                                fontWeight: 500,
                                fontSize: { xs: "0.85rem", md: "0.92rem" },
                                lineHeight: 1.3,
                                textAlign: "center",
                            }}
                        >
                            {consumeError}
                        </Typography>
                        <Button
                            variant="contained"
                            component="a"
                            href="/"
                            disableElevation
                            sx={{
                                px: "34px",
                                py: "14px",
                                minHeight: 54,
                                borderRadius: "10px",
                                textTransform: "none",
                                fontWeight: 600,
                                fontSize: "1rem",
                                lineHeight: 1,
                                bgcolor: frameBlue,
                                color: "rgba(231, 238, 252, 0.9)",
                                "&:hover": {
                                    bgcolor: frameBlue,
                                    boxShadow: "none",
                                },
                            }}
                        >
                            Create new paste
                        </Button>
                    </Stack>
                </Stack>
            )}

            {!resolvedText && (
                <Stack spacing={1.8}>
                    <Typography
                        sx={{
                            fontSize: "0.82rem",
                            color: "rgba(186, 201, 232, 0.56)",
                            fontWeight: 600,
                            letterSpacing: "0.01em",
                        }}
                    >
                        Paste contents
                    </Typography>
                    <Box sx={{ position: "relative", width: "100%" }}>
                        <TextField
                            variant="filled"
                            hiddenLabel
                            fullWidth
                            multiline
                            minRows={10}
                            maxRows={14}
                            value={resolvedText}
                            slotProps={{
                                htmlInput: { "aria-label": "Paste contents" },
                                input: {
                                    readOnly: true,
                                    disableUnderline: true,
                                },
                            }}
                            sx={[
                                pasteTextFieldSx(
                                    "20px",
                                    inputGlassBg,
                                    inputGlassBorder,
                                ),
                                {
                                    "& .MuiFilledInput-root": {
                                        paddingBottom: "72px",
                                        maxHeight: { xs: 320, sm: 360 },
                                        overflow: "hidden",
                                        backdropFilter:
                                            "blur(9px) saturate(112%)",
                                        WebkitBackdropFilter:
                                            "blur(9px) saturate(112%)",
                                        background:
                                            "linear-gradient(160deg, rgba(255, 255, 255, 0.06) 0%, rgba(255, 255, 255, 0.02) 58%, rgba(255, 255, 255, 0.015) 100%)",
                                        boxShadow:
                                            "0 12px 28px rgba(0, 0, 0, 0.26), inset 0 1px 0 rgba(255, 255, 255, 0.1)",
                                        "&:hover": {
                                            bgcolor: inputGlassBg,
                                            borderColor: inputGlassBorder,
                                            background:
                                                "linear-gradient(160deg, rgba(255, 255, 255, 0.06) 0%, rgba(255, 255, 255, 0.02) 58%, rgba(255, 255, 255, 0.015) 100%)",
                                            boxShadow:
                                                "0 12px 28px rgba(0, 0, 0, 0.26), inset 0 1px 0 rgba(255, 255, 255, 0.1)",
                                        },
                                        "&.Mui-focused": {
                                            bgcolor: inputGlassBg,
                                            borderColor: inputGlassBorder,
                                            background:
                                                "linear-gradient(160deg, rgba(255, 255, 255, 0.06) 0%, rgba(255, 255, 255, 0.02) 58%, rgba(255, 255, 255, 0.015) 100%)",
                                            boxShadow:
                                                "0 12px 28px rgba(0, 0, 0, 0.26), inset 0 1px 0 rgba(255, 255, 255, 0.1)",
                                        },
                                    },
                                },
                            ]}
                        />
                        <Box
                            sx={{
                                position: "absolute",
                                left: 18,
                                right: 18,
                                bottom: 18,
                                display: "flex",
                                justifyContent: "flex-end",
                                alignItems: "center",
                                gap: 1.2,
                                pointerEvents: "none",
                            }}
                        >
                            <Button
                                variant="contained"
                                size="small"
                                disableElevation
                                onClick={() => {
                                    if (resolvedText === null) {
                                        return;
                                    }
                                    void onCopyText(resolvedText).catch(() => {
                                        // Ignore errors to avoid unhandled rejections in click handlers.
                                    });
                                }}
                                startIcon={
                                    <ContentCopyRoundedIcon
                                        sx={{ fontSize: 16 }}
                                    />
                                }
                                sx={{
                                    pointerEvents: "auto",
                                    minHeight: 34,
                                    px: 1.25,
                                    borderRadius: "10px",
                                    textTransform: "none",
                                    fontWeight: 600,
                                    fontSize: "0.78rem",
                                    bgcolor: frameBlue,
                                    color: "rgba(231, 238, 252, 0.9)",
                                    boxShadow: "none",
                                    "& .MuiButton-startIcon": { mr: 0.6 },
                                    "&:hover": {
                                        bgcolor: frameBlue,
                                        boxShadow: "none",
                                    },
                                }}
                            >
                                Copy
                            </Button>
                        </Box>
                    </Box>
                    <Typography
                        variant="mini"
                        sx={{
                            color: "rgba(182, 197, 229, 0.44)",
                            fontWeight: 500,
                        }}
                    >
                        This paste has been removed from Ente servers.
                    </Typography>
                </Stack>
            )}
        </>
    );
};
