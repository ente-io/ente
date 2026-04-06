import ChevronLeftRoundedIcon from "@mui/icons-material/ChevronLeftRounded";
import ChevronRightRoundedIcon from "@mui/icons-material/ChevronRightRounded";
import { Box, ButtonBase, Stack, Typography } from "@mui/material";
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
}> = ({ items, createOpen, disabled, onCreateClick }) => {
    const scrollContainerRef = useRef<HTMLDivElement | null>(null);
    const [canScrollLeft, setCanScrollLeft] = useState(false);
    const [canScrollRight, setCanScrollRight] = useState(false);

    const scrollBy = (direction: number) => {
        const container = scrollContainerRef.current;
        if (!container) {
            return;
        }

        container.scrollBy({
            left: direction * Math.max(container.clientWidth * 0.6, 160),
            behavior: "smooth",
        });
    };

    useEffect(() => {
        const container = scrollContainerRef.current;
        if (!container) {
            return;
        }

        const updateScrollHints = () => {
            setCanScrollLeft(container.scrollLeft > 8);
            const remainingScroll =
                container.scrollWidth -
                container.clientWidth -
                container.scrollLeft;
            setCanScrollRight(remainingScroll > 8);
        };

        updateScrollHints();
        container.addEventListener("scroll", updateScrollHints, {
            passive: true,
        });
        window.addEventListener("resize", updateScrollHints);

        return () => {
            container.removeEventListener("scroll", updateScrollHints);
            window.removeEventListener("resize", updateScrollHints);
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
            <Box sx={{ position: "relative", minWidth: 0 }}>
                <Box
                    sx={{
                        position: "absolute",
                        left: 0,
                        top: 0,
                        bottom: 0,
                        zIndex: 1,
                        display: "flex",
                        alignItems: "center",
                    }}
                >
                    {canScrollLeft && (
                        <ButtonBase
                            onClick={() => scrollBy(-1)}
                            disabled={disabled}
                            sx={(theme) => ({
                                width: 28,
                                height: 28,
                                color: "#4A4A4A",
                                borderRadius: "999px",
                                backgroundColor:
                                    theme.vars.palette.background.paper,
                                ...theme.applyStyles("dark", {
                                    color: "#FFFFFF",
                                }),
                            })}
                        >
                            <ChevronLeftRoundedIcon sx={{ fontSize: 28 }} />
                        </ButtonBase>
                    )}
                </Box>
                <Box sx={{ position: "relative", minWidth: 0 }}>
                    <Stack
                        ref={scrollContainerRef}
                        direction="row"
                        sx={{
                            gap: 1,
                            flexWrap: "nowrap",
                            overflowX: "auto",
                            overflowY: "hidden",
                            px: 0.5,
                            pb: 0.5,
                            maskImage:
                                canScrollLeft && canScrollRight
                                    ? "linear-gradient(90deg, rgba(0,0,0,0) 0%, #000 64px, #000 calc(100% - 64px), rgba(0,0,0,0) 100%)"
                                    : canScrollLeft
                                      ? "linear-gradient(90deg, rgba(0,0,0,0) 0%, #000 64px)"
                                      : canScrollRight
                                        ? "linear-gradient(90deg, #000 0%, #000 calc(100% - 64px), rgba(0,0,0,0) 100%)"
                                        : undefined,
                            WebkitMaskImage:
                                canScrollLeft && canScrollRight
                                    ? "linear-gradient(90deg, rgba(0,0,0,0) 0%, #000 64px, #000 calc(100% - 64px), rgba(0,0,0,0) 100%)"
                                    : canScrollLeft
                                      ? "linear-gradient(90deg, rgba(0,0,0,0) 0%, #000 64px)"
                                      : canScrollRight
                                        ? "linear-gradient(90deg, #000 0%, #000 calc(100% - 64px), rgba(0,0,0,0) 100%)"
                                        : undefined,
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
                </Box>
                <Box
                    sx={{
                        position: "absolute",
                        right: 0,
                        top: 0,
                        bottom: 0,
                        zIndex: 1,
                        display: "flex",
                        alignItems: "center",
                    }}
                >
                    {canScrollRight && (
                        <ButtonBase
                            onClick={() => scrollBy(1)}
                            disabled={disabled}
                            sx={(theme) => ({
                                width: 28,
                                height: 28,
                                color: "#4A4A4A",
                                borderRadius: "999px",
                                backgroundColor:
                                    theme.vars.palette.background.paper,
                                ...theme.applyStyles("dark", {
                                    color: "#FFFFFF",
                                }),
                            })}
                        >
                            <ChevronRightRoundedIcon sx={{ fontSize: 28 }} />
                        </ButtonBase>
                    )}
                </Box>
            </Box>
        </Box>
    );
};
