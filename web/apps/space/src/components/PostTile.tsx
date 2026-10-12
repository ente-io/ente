import { Box } from "@mui/material";
import { SpaceCaptionText } from "components/CaptionText";
import {
    SpacePostPhotosBadge,
    SpacePostVideoBadge,
} from "components/PostPhotosBadge";
import { viewerOriginKey } from "components/viewer-transition";
import log from "ente-base/log";
import React from "react";
import type { SpacePostAsset, SpacePostPhoto } from "services/space";
import { spaceSurface, spaceTextMuted } from "styles/colors";
import {
    minimumPostPhotoFrameAspectRatio,
    spaceProfilePostRadius,
} from "styles/tiles";
import { formatSpaceDate } from "utils/display";
import { thumbHashDataURLFromBase64 } from "utils/thumbhash";

const green = "#08C225";

export interface SpacePostTileItem {
    avatarUrl?: string | null;
    caption?: string;
    friendID?: string;
    height?: number;
    id: string;
    imageAsset?: SpacePostAsset;
    imageUrl?: string;
    photos?: SpacePostPhoto[];
    isUnavailable?: boolean;
    name?: string;
    postId?: number;
    spaceId?: string;
    timestampMs: number;
    thumbHash?: string;
    viewerLiked?: boolean;
    width?: number;
}

interface SpacePostTileProps {
    displayName: string;
    imageUrl?: string;
    index: number;
    isUnavailable: boolean;
    item: SpacePostTileItem;
    loadRootMargin: string;
    onImageDecodeError: () => void;
    onLoadImage: () => Promise<string | undefined>;
    onOpen: (imageUrl: string) => void;
    onRememberDimensions?: (itemID: string, image: HTMLImageElement) => void;
    photoIndex?: number;
}

export const SpacePostTile: React.FC<SpacePostTileProps> = ({
    displayName,
    imageUrl,
    index,
    isUnavailable: isPostUnavailable,
    item,
    loadRootMargin,
    onImageDecodeError,
    onLoadImage,
    onOpen,
    onRememberDimensions,
    photoIndex = 0,
}) => {
    const [shouldLoad, setShouldLoad] = React.useState(Boolean(imageUrl));
    const [readyImageUrl, setReadyImageUrl] = React.useState<string>();
    const [failedImageUrl, setFailedImageUrl] = React.useState<string>();
    const tileRef = React.useRef<HTMLButtonElement | null>(null);
    const shownPhoto = item.photos?.[photoIndex];
    const thumbHash = photoIndex > 0 ? shownPhoto?.thumbHash : item.thumbHash;
    const thumbHashDataURL = React.useMemo(
        () => thumbHashDataURLFromBase64(thumbHash),
        [thumbHash],
    );
    const isCurrentImageReady = Boolean(imageUrl && readyImageUrl == imageUrl);
    const isUnavailable =
        isPostUnavailable || Boolean(imageUrl && failedImageUrl == imageUrl);
    const photoCount = item.photos?.length ?? 1;
    const caption = item.caption?.trim();
    const aspectRatio = Math.max(
        minimumPostPhotoFrameAspectRatio,
        item.width && item.height ? item.width / item.height : 1,
    );

    React.useEffect(() => {
        if (imageUrl) setShouldLoad(true);
    }, [imageUrl]);

    React.useEffect(() => {
        if (isUnavailable) return;
        if (shouldLoad || imageUrl) return;
        const element = tileRef.current;
        if (!element) return;
        if (
            typeof window == "undefined" ||
            !("IntersectionObserver" in window)
        ) {
            setShouldLoad(true);
            return;
        }

        const observer = new IntersectionObserver(
            (entries) => {
                if (entries.some((entry) => entry.isIntersecting)) {
                    setShouldLoad(true);
                    observer.disconnect();
                }
            },
            { rootMargin: loadRootMargin },
        );
        observer.observe(element);
        return () => observer.disconnect();
    }, [imageUrl, isUnavailable, loadRootMargin, shouldLoad]);

    React.useEffect(() => {
        if (isUnavailable) return;
        if (!shouldLoad || imageUrl) return;
        void onLoadImage().catch((error: unknown) => {
            log.warn("Failed to load profile post image", error);
        });
    }, [imageUrl, isUnavailable, onLoadImage, shouldLoad]);

    return (
        <Box
            component="article"
            sx={{
                aspectRatio,
                bgcolor: spaceSurface,
                borderRadius: `${spaceProfilePostRadius}px`,
                minWidth: 0,
                overflow: "hidden",
                position: "relative",
                width: "100%",
            }}
        >
            <Box
                ref={tileRef}
                component="button"
                type="button"
                aria-label={
                    isUnavailable
                        ? "Post unavailable"
                        : `Open ${displayName} post ${index + 1}${
                              photoCount > 1 ? `, ${photoCount} photos` : ""
                          }`
                }
                disabled={!imageUrl || isUnavailable}
                data-space-viewer-origin={viewerOriginKey(
                    item.spaceId,
                    item.postId,
                )}
                onClick={() => {
                    if (imageUrl && !isUnavailable) onOpen(imageUrl);
                }}
                sx={{
                    appearance: "none",
                    bgcolor: spaceSurface,
                    border: 0,
                    borderRadius: "inherit",
                    cursor: imageUrl && !isUnavailable ? "pointer" : "default",
                    display: "block",
                    height: "100%",
                    isolation: "isolate",
                    minWidth: 0,
                    opacity: 1,
                    overflow: "hidden",
                    p: 0,
                    position: "relative",
                    width: "100%",
                    "&::after": {
                        borderRadius: "inherit",
                        boxShadow: "inset 0 0 0 1px #282828",
                        content: '""',
                        inset: 0,
                        mixBlendMode: "lighten",
                        pointerEvents: "none",
                        position: "absolute",
                        zIndex: 2,
                    },
                    "&:focus-visible": {
                        outline: `2px solid ${green}`,
                        outlineOffset: -2,
                    },
                }}
            >
                {!isUnavailable && thumbHashDataURL ? (
                    <Box
                        component="img"
                        alt=""
                        aria-hidden
                        src={thumbHashDataURL}
                        sx={{
                            display: "block",
                            filter: "blur(14px)",
                            height: "100%",
                            inset: 0,
                            objectFit: "cover",
                            objectPosition: "center",
                            position: "absolute",
                            transform: "scale(1.08)",
                            width: "100%",
                        }}
                    />
                ) : null}
                {!isUnavailable && imageUrl ? (
                    <Box
                        component="img"
                        alt={`${displayName} post ${index + 1}`}
                        onLoad={(event) => {
                            setReadyImageUrl(imageUrl);
                            if (photoIndex == 0)
                                onRememberDimensions?.(
                                    item.id,
                                    event.currentTarget,
                                );
                        }}
                        onError={() => {
                            log.warn(
                                `Post ${item.postId} is unavailable because the browser could not decode its image`,
                            );
                            setFailedImageUrl(imageUrl);
                            onImageDecodeError();
                        }}
                        src={imageUrl}
                        sx={{
                            display: "block",
                            height: "100%",
                            inset: 0,
                            objectFit: "cover",
                            objectPosition: "center",
                            opacity:
                                isCurrentImageReady || !thumbHashDataURL
                                    ? 1
                                    : 0,
                            position: "absolute",
                            transition: thumbHashDataURL
                                ? "opacity 220ms ease"
                                : "none",
                            width: "100%",
                            "@media (prefers-reduced-motion: reduce)": {
                                opacity: 1,
                                transition: "none",
                            },
                        }}
                    />
                ) : null}
                {!isUnavailable && (
                    <>
                        <Box
                            aria-hidden
                            data-space-viewer-header-shade
                            sx={{
                                background:
                                    "linear-gradient(180deg, rgba(0, 0, 0, 0.78), rgba(0, 0, 0, 0))",
                                filter: "blur(12px)",
                                height: 100,
                                left: -12,
                                pointerEvents: "none",
                                position: "absolute",
                                right: -12,
                                top: -12,
                            }}
                        />
                        <Box
                            component="time"
                            data-space-viewer-header
                            dateTime={new Date(item.timestampMs).toISOString()}
                            sx={{
                                color: "#D9D9D9",
                                fontFamily:
                                    '"Inter Variable", Inter, sans-serif',
                                fontSize: 12,
                                fontWeight: 500,
                                left: 16,
                                lineHeight: "16px",
                                pointerEvents: "none",
                                position: "absolute",
                                top: 16,
                            }}
                        >
                            {formatSpaceDate(item.timestampMs)}
                        </Box>
                        <SpacePostPhotosBadge count={photoCount} inset={12} />
                        <SpacePostVideoBadge
                            durationMs={
                                item.photos?.[photoIndex]?.video?.durationMs
                            }
                            size={18}
                        />
                        {caption && (
                            <Box
                                title={caption}
                                sx={{
                                    bottom: 20,
                                    color: "#E6E6E6",
                                    fontFamily:
                                        '"Inter Variable", Inter, sans-serif',
                                    fontSize: 13,
                                    fontWeight: 600,
                                    left: "50%",
                                    lineHeight: "21px",
                                    maxWidth: "78%",
                                    pointerEvents: "none",
                                    position: "absolute",
                                    textAlign: "center",
                                    textWrap: "balance",
                                    transform: "translateX(-50%)",
                                    width: "max-content",
                                }}
                            >
                                <SpaceCaptionText
                                    caption={caption}
                                    lineClamp={2}
                                />
                            </Box>
                        )}
                    </>
                )}
                {isUnavailable && (
                    <Box
                        sx={{
                            alignItems: "center",
                            color: spaceTextMuted,
                            display: "flex",
                            fontSize: 12,
                            fontWeight: 600,
                            height: "100%",
                            justifyContent: "center",
                            width: "100%",
                        }}
                    >
                        Post unavailable
                    </Box>
                )}
            </Box>
        </Box>
    );
};
