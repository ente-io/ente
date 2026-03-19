import ChevronRightRoundedIcon from "@mui/icons-material/ChevronRightRounded";
import { Box, ButtonBase, Stack, Typography } from "@mui/material";
import type { Theme } from "@mui/material/styles";
import { t } from "i18next";
import React, { useEffect, useRef, useState } from "react";

interface CollectionChipRowItem {
    key: string;
    label: string;
    selected: boolean;
    onClick: () => void;
}

export const CollectionChipRow: React.FC<{
    items: CollectionChipRowItem[];
    createOpen: boolean;
    disabled?: boolean;
    onCreateClick?: () => void;
    fadeColor?: (theme: Theme) => string;
}> = ({
    items,
    createOpen,
    disabled,
    onCreateClick,
    fadeColor = (theme) => theme.vars.palette.background.paper,
}) => {
    const scrollContainerRef = useRef<HTMLDivElement | null>(null);
    const [showScrollHint, setShowScrollHint] = useState(false);

    const scrollRight = () => {
        const container = scrollContainerRef.current;
        if (!container) {
            return;
        }

        container.scrollBy({
            left: Math.max(container.clientWidth * 0.6, 160),
            behavior: "smooth",
        });
    };

    useEffect(() => {
        const container = scrollContainerRef.current;
        if (!container) {
            return;
        }

        const updateScrollHint = () => {
            const remainingScroll =
                container.scrollWidth -
                container.clientWidth -
                container.scrollLeft;
            setShowScrollHint(remainingScroll > 8);
        };

        updateScrollHint();
        container.addEventListener("scroll", updateScrollHint, {
            passive: true,
        });
        window.addEventListener("resize", updateScrollHint);

        return () => {
            container.removeEventListener("scroll", updateScrollHint);
            window.removeEventListener("resize", updateScrollHint);
        };
    }, [createOpen, items.length]);

    return (
        <Box>
            <Stack
                direction="row"
                sx={{
                    alignItems: "center",
                    justifyContent: "space-between",
                    gap: 1,
                    mb: 1.25,
                }}
            >
                <Typography
                    variant="small"
                    sx={{
                        color: "text.faint",
                        fontWeight: "bold",
                        textTransform: "uppercase",
                        letterSpacing: "0.08em",
                        display: "block",
                    }}
                >
                    {t("collections")}
                </Typography>
            </Stack>
            <Stack direction="row" sx={{ alignItems: "stretch", gap: 0 }}>
                <Box sx={{ position: "relative", flex: 1, minWidth: 0 }}>
                    <Stack
                        ref={scrollContainerRef}
                        direction="row"
                        sx={{
                            gap: 1,
                            flexWrap: "nowrap",
                            overflowX: "auto",
                            overflowY: "hidden",
                            pr: 2,
                            pb: 0.5,
                            scrollbarWidth: "none",
                            "&::-webkit-scrollbar": { display: "none" },
                        }}
                    >
                        {onCreateClick && (
                            <ButtonBase
                                onClick={onCreateClick}
                                disabled={disabled}
                                sx={(theme) => ({
                                    borderRadius: "999px",
                                    px: 1.5,
                                    py: 0.875,
                                    whiteSpace: "nowrap",
                                    flexShrink: 0,
                                    border: `1px dotted ${theme.vars.palette.stroke.muted}`,
                                    color: theme.vars.palette.text.muted,
                                    backgroundColor: createOpen
                                        ? theme.vars.palette.fill.faint
                                        : "transparent",
                                })}
                            >
                                <Typography variant="small">
                                    + {t("collection")}
                                </Typography>
                            </ButtonBase>
                        )}
                        {items.map((item) => (
                            <ButtonBase
                                key={item.key}
                                onClick={item.onClick}
                                disabled={disabled}
                                sx={(theme) => ({
                                    borderRadius: "999px",
                                    px: 1.5,
                                    py: 0.875,
                                    whiteSpace: "nowrap",
                                    flexShrink: 0,
                                    backgroundColor: item.selected
                                        ? "#1071FF"
                                        : theme.vars.palette.fill.faint,
                                    color: item.selected
                                        ? "#FFFFFF"
                                        : theme.vars.palette.text.base,
                                })}
                            >
                                <Typography variant="small">
                                    {item.label}
                                </Typography>
                            </ButtonBase>
                        ))}
                    </Stack>
                    {showScrollHint && (
                        <Box
                            sx={(theme) => ({
                                position: "absolute",
                                top: 0,
                                right: 0,
                                bottom: 0,
                                width: 64,
                                pointerEvents: "none",
                                background: `linear-gradient(90deg, rgba(0, 0, 0, 0) 0%, ${fadeColor(theme)} 100%)`,
                            })}
                        />
                    )}
                </Box>
                <Box
                    sx={{
                        width: 28,
                        flexShrink: 0,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                    }}
                >
                    {showScrollHint && (
                        <ButtonBase
                            onClick={scrollRight}
                            disabled={disabled}
                            sx={(theme) => ({
                                width: 28,
                                height: "100%",
                                color: "#4A4A4A",
                                borderRadius: "999px",
                                ...theme.applyStyles("dark", {
                                    color: "#FFFFFF",
                                }),
                            })}
                        >
                            <ChevronRightRoundedIcon sx={{ fontSize: 28 }} />
                        </ButtonBase>
                    )}
                </Box>
            </Stack>
        </Box>
    );
};
