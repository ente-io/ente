import { Box, Stack, Typography, styled } from "@mui/material";
import { ItemCard } from "ente-new/photos/components/Tiles";
import { UnstyledButton } from "ente-new/photos/components/UnstyledButton";
import type { CollectionSummary } from "ente-new/photos/services/collection-summary";
import { t } from "i18next";
import { useEffect, useRef, useState } from "react";

// Includes the space separating the albums from the existing file list.
export const hiddenAlbumsStripHeight = 232;

export const HiddenAlbumsStrip = ({
    albums,
    onSelectAlbum,
}: {
    albums: CollectionSummary[];
    onSelectAlbum: (id: number) => void;
}) => {
    const scrollRef = useRef<HTMLDivElement>(null);
    const [canScrollRight, setCanScrollRight] = useState(false);

    useEffect(() => {
        const element = scrollRef.current;
        if (!element) return;
        const update = () =>
            setCanScrollRight(
                element.scrollWidth - element.clientWidth - element.scrollLeft >
                    1,
            );
        update();
        const observer = new ResizeObserver(update);
        observer.observe(element);
        element.addEventListener("scroll", update, { passive: true });
        return () => {
            observer.disconnect();
            element.removeEventListener("scroll", update);
        };
    }, [albums]);

    return (
        <Box sx={{ position: "relative", height: hiddenAlbumsStripHeight }}>
            <Stack
                ref={scrollRef}
                direction="row"
                role="region"
                aria-label={t("hidden_albums")}
                sx={{ gap: "22px", overflowX: "auto", pt: "8px", pb: "16px" }}
            >
                {albums.map((album) => (
                    <AlbumButton
                        key={album.id}
                        title={album.name}
                        onClick={() => onSelectAlbum(album.id)}
                    >
                        <ItemCard
                            TileComponent={Cover}
                            coverFile={album.coverFile}
                        />
                        <Stack
                            component="span"
                            sx={{ width: "100%", gap: "4px" }}
                        >
                            <Typography
                                component="span"
                                noWrap
                                sx={{
                                    fontSize: 14,
                                    lineHeight: "20px",
                                    fontWeight: 500,
                                }}
                            >
                                {album.name}
                            </Typography>
                            <Typography
                                component="span"
                                sx={{
                                    fontSize: 12,
                                    lineHeight: "16px",
                                    fontWeight: 500,
                                    color: "text.muted",
                                }}
                            >
                                {t("album_items_count", {
                                    count: album.fileCount,
                                })}
                            </Typography>
                        </Stack>
                    </AlbumButton>
                ))}
            </Stack>
            {canScrollRight && (
                <Box
                    aria-hidden
                    sx={{
                        position: "absolute",
                        top: 0,
                        right: 0,
                        width: 64,
                        height: 204,
                        pointerEvents: "none",
                        background: (theme) =>
                            `linear-gradient(to right, transparent, ${theme.vars.palette.background.paper})`,
                    }}
                />
            )}
        </Box>
    );
};

const AlbumButton = styled(UnstyledButton)(({ theme }) => ({
    width: 140,
    flexShrink: 0,
    display: "flex",
    flexDirection: "column",
    gap: 8,
    textAlign: "left",
    color: theme.vars.palette.text.base,
    borderRadius: 20,
    "&:hover": { opacity: 0.86 },
    "&:focus-visible": {
        outline: `2px solid ${theme.vars.palette.stroke.base}`,
        outlineOffset: -2,
    },
}));

const Cover = styled("div")({
    width: 140,
    height: 140,
    borderRadius: 20,
    overflow: "hidden",
    position: "relative",
    "& > img": {
        width: "100%",
        height: "100%",
        objectFit: "cover",
        display: "block",
    },
});
