import { Navigation06Icon } from "@hugeicons/core-free-icons";
import { HugeiconsIcon } from "@hugeicons/react";
import {
    Box,
    CircularProgress,
    IconButton,
    TextField,
    Typography,
} from "@mui/material";
import useMediaQuery from "@mui/material/useMediaQuery";
import { usePasteColorMode } from "features/paste/hooks/usePasteColorMode";
import { getPasteThemeTokens } from "features/paste/theme/pasteThemeTokens";
import { MAX_PASTE_CHARS } from "../constants";
import { PasteLinkCard } from "./PasteLinkCard";
import { pasteTextFieldSx } from "./textFieldSx";

interface PasteCreatePanelProps {
    inputText: string;
    creating: boolean;
    createError: string | null;
    createdLink: string | null;
    onInputChange: (value: string) => void;
    onCreate: () => Promise<void>;
    onCopyLink: (value: string) => Promise<void>;
    onShareLink: (url: string) => Promise<void>;
}

export const PasteCreatePanel = ({
    inputText,
    creating,
    createError,
    createdLink,
    onInputChange,
    onCreate,
    onCopyLink,
    onShareLink,
}: PasteCreatePanelProps) => {
    const isMobile = useMediaQuery("(max-width:599.95px)", { noSsr: true });
    const { resolvedMode } = usePasteColorMode();
    const tokens = getPasteThemeTokens(resolvedMode);
    const isInputEmpty = inputText.trim().length === 0;
    const nearLimitThreshold = Math.floor(MAX_PASTE_CHARS * 0.9);
    const isNearCharLimit = inputText.length >= nearLimitThreshold;
    const isCreateDisabled = isInputEmpty;
    const privacyPills = [
        isMobile ? "E2EE" : "End-to-end encrypted",
        "Auto-deletes after 24 hours",
    ];

    return (
        <Box sx={{ width: "100%", maxWidth: "100%", minWidth: 0 }}>
            <Typography
                component="h2"
                sx={{
                    color: tokens.text.primary,
                    fontWeight: 600,
                    fontSize: { xs: "1.08rem", sm: "1.18rem" },
                    lineHeight: 1.35,
                    letterSpacing: "0.01em",
                    textAlign: "center",
                    mb: { xs: 1.25, sm: 1.5 },
                    maxWidth: "100%",
                }}
            >
                Share private data with secure, one-time links
            </Typography>
            <Box
                sx={{
                    position: "relative",
                    width: "100%",
                    maxWidth: "100%",
                    minWidth: 0,
                }}
            >
                <TextField
                    variant="filled"
                    hiddenLabel
                    fullWidth
                    slotProps={{
                        input: { disableUnderline: true },
                        htmlInput: {
                            maxLength: MAX_PASTE_CHARS,
                            "aria-label": "Paste text",
                        },
                    }}
                    multiline
                    minRows={5}
                    maxRows={12}
                    placeholder="Paste text (keys, snippets, notes, instructions...)"
                    value={inputText}
                    onChange={(event) => {
                        onInputChange(event.target.value);
                    }}
                    sx={[
                        pasteTextFieldSx(tokens, "20px"),
                        {
                            "& .MuiFilledInput-root": {
                                paddingTop: { xs: "12px", sm: "14px" },
                                paddingRight: { xs: "12px", sm: "14px" },
                                paddingLeft: { xs: "12px", sm: "14px" },
                                // Keep only the minimum reserve needed for the footer row.
                                paddingBottom: { xs: "50px", sm: "56px" },
                                backdropFilter: "blur(9px) saturate(112%)",
                                WebkitBackdropFilter:
                                    "blur(9px) saturate(112%)",
                                background: tokens.surface.inputGradient,
                                boxShadow: tokens.surface.inputShadow,
                                "&:hover": {
                                    bgcolor: tokens.surface.inputBg,
                                    borderColor: tokens.surface.inputBorder,
                                    background: tokens.surface.inputGradient,
                                    boxShadow: tokens.surface.inputShadow,
                                },
                                "&.Mui-focused": {
                                    bgcolor: tokens.surface.inputBg,
                                    borderColor: tokens.surface.inputBorder,
                                    background: tokens.surface.inputGradient,
                                    boxShadow: tokens.surface.inputShadow,
                                },
                            },
                            "& .MuiInputBase-input": {
                                fontSize: { xs: "0.9rem", sm: "0.96rem" },
                                lineHeight: 1.6,
                            },
                        },
                    ]}
                />
                <Box
                    sx={{
                        position: "absolute",
                        left: { xs: 12, sm: 18 },
                        right: { xs: 12, sm: 18 },
                        bottom: { xs: 8, sm: 10 },
                        height: { xs: 36, sm: 40 },
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center",
                        gap: { xs: 1, sm: 2 },
                        pointerEvents: "none",
                    }}
                >
                    <Typography
                        variant="mini"
                        sx={{
                            display: "flex",
                            alignItems: "center",
                            height: { xs: 32, sm: 36 },
                            color: tokens.text.counter,
                            fontWeight: 600,
                            lineHeight: 1,
                            letterSpacing: "0.01em",
                        }}
                    >
                        <Box
                            component="span"
                            sx={{
                                color: isNearCharLimit
                                    ? tokens.text.counterHighlight
                                    : tokens.text.counter,
                            }}
                        >
                            {inputText.length}
                        </Box>
                        <Box
                            component="span"
                            sx={{ color: tokens.text.counter }}
                        >
                            /{MAX_PASTE_CHARS}
                        </Box>
                    </Typography>
                    <IconButton
                        aria-label="Create secure link"
                        aria-busy={creating}
                        onClick={() => {
                            if (creating || isCreateDisabled) return;
                            void onCreate();
                        }}
                        disabled={isCreateDisabled}
                        sx={{
                            pointerEvents: "auto",
                            boxSizing: "border-box",
                            width: { xs: 34, sm: 38 },
                            height: { xs: 34, sm: 38 },
                            minWidth: { xs: 34, sm: 38 },
                            minHeight: { xs: 34, sm: 38 },
                            padding: 0,
                            marginBottom: { xs: "3px", sm: "4px" },
                            marginRight: { xs: "-1px", sm: "-2px" },
                            borderRadius: { xs: "12px", sm: "14px" },
                            bgcolor: tokens.button.primaryBg,
                            color: tokens.button.primaryText,
                            boxShadow: "none",
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            "&:hover": {
                                bgcolor: tokens.button.primaryHoverBg,
                                boxShadow: "none",
                            },
                            "&.Mui-disabled": {
                                bgcolor: tokens.button.primaryDisabledBg,
                                color: tokens.button.primaryDisabledText,
                            },
                        }}
                    >
                        {creating ? (
                            <Box
                                sx={{
                                    width: 18,
                                    height: 18,
                                    display: "flex",
                                    alignItems: "center",
                                    justifyContent: "center",
                                    lineHeight: 0,
                                }}
                            >
                                <CircularProgress
                                    size={17}
                                    thickness={5.2}
                                    sx={{
                                        color: tokens.button.primaryText,
                                        display: "block",
                                        "& .MuiCircularProgress-svg": {
                                            display: "block",
                                            transformOrigin: "50% 50%",
                                        },
                                    }}
                                />
                            </Box>
                        ) : (
                            <Box
                                sx={{
                                    transform: "rotate(90deg)",
                                    display: "flex",
                                }}
                            >
                                <HugeiconsIcon
                                    icon={Navigation06Icon}
                                    size={18}
                                    strokeWidth={2}
                                />
                            </Box>
                        )}
                    </IconButton>
                </Box>
            </Box>
            <Box
                sx={{
                    mt: { xs: "16px" },
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    textAlign: "center",
                    width: "100%",
                    maxWidth: "100%",
                }}
            >
                <Box
                    sx={{
                        display: "flex",
                        flexWrap: "wrap",
                        justifyContent: "center",
                        gap: { xs: 0.7, sm: 1 },
                        width: "100%",
                        maxWidth: { xs: "100%", sm: 520, md: "none" },
                        mb: { xs: "2rem", sm: "3rem" },
                        pointerEvents: "none",
                        userSelect: "none",
                    }}
                >
                    {privacyPills.map((label) => (
                        <Box
                            key={label}
                            component="span"
                            aria-disabled="true"
                            sx={{
                                px: { xs: 1.2, sm: 1.4 },
                                py: { xs: 0.45, sm: 0.6 },
                                borderRadius: "999px",
                                border: `1px solid ${tokens.surface.chipBorder}`,
                                bgcolor: tokens.surface.chipBg,
                                color: tokens.surface.chipText,
                                fontSize: { xs: "0.74rem", sm: "0.79rem" },
                                fontWeight: 600,
                                letterSpacing: "0.01em",
                                lineHeight: 1.2,
                                whiteSpace: "nowrap",
                                boxShadow: tokens.surface.chipInsetShadow,
                                opacity: 0.78,
                            }}
                        >
                            {label}
                        </Box>
                    ))}
                </Box>
            </Box>

            {createError && (
                <Typography color="error">{createError}</Typography>
            )}

            {createdLink && (
                <Box sx={{ mt: 0, width: "100%", minWidth: 0 }}>
                    <PasteLinkCard
                        link={createdLink}
                        onCopy={onCopyLink}
                        onShare={onShareLink}
                    />
                </Box>
            )}
        </Box>
    );
};
