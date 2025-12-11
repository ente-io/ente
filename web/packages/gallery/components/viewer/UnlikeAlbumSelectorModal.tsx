import CloseIcon from "@mui/icons-material/Close";
import { Box, Dialog, IconButton, styled, Typography } from "@mui/material";
import { type ModalVisibilityProps } from "ente-base/components/utils/modal";
import React from "react";

// =============================================================================
// Icons
// =============================================================================

const HeartFilledIcon: React.FC<{ size?: number; color?: string }> = ({
    size = 18,
    color = "#08C225",
}) => (
    <svg
        width={size}
        height={(size * 15) / 18}
        viewBox="0 0 18 15"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        style={{ display: "block" }}
    >
        <path
            d="M7.40825 13.8538C5.15122 12.1661 0.679688 8.30753 0.679688 4.83524C0.679688 2.54019 2.3639 0.679688 4.67969 0.679688C5.87969 0.679688 7.07969 1.07969 8.67969 2.67969C10.2797 1.07969 11.4797 0.679688 12.6797 0.679688C14.9954 0.679688 16.6797 2.54019 16.6797 4.83524C16.6797 8.30753 12.2082 12.1661 9.95113 13.8538C9.19161 14.4218 8.16777 14.4218 7.40825 13.8538Z"
            fill={color}
            stroke={color}
            strokeWidth="1.36"
            strokeLinecap="round"
            strokeLinejoin="round"
        />
    </svg>
);

const HeartOutlineIcon: React.FC<{ size?: number; color?: string }> = ({
    size = 18,
    color = "#08C225",
}) => (
    <svg
        width={size}
        height={(size * 15) / 18}
        viewBox="0 0 18 15"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        style={{ display: "block" }}
    >
        <path
            d="M7.40825 13.8538C5.15122 12.1661 0.679688 8.30753 0.679688 4.83524C0.679688 2.54019 2.3639 0.679688 4.67969 0.679688C5.87969 0.679688 7.07969 1.07969 8.67969 2.67969C10.2797 1.07969 11.4797 0.679688 12.6797 0.679688C14.9954 0.679688 16.6797 2.54019 16.6797 4.83524C16.6797 8.30753 12.2082 12.1661 9.95113 13.8538C9.19161 14.4218 8.16777 14.4218 7.40825 13.8538Z"
            stroke={color}
            strokeWidth="1.36"
            strokeLinecap="round"
            strokeLinejoin="round"
        />
    </svg>
);

const UnlikePhotoIllustration: React.FC = () => (
    <svg
        width="126"
        height="121"
        viewBox="0 0 126 121"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
    >
        <path
            d="M84.7129 23.0781C96.7222 23.0784 105.29 32.8476 105.29 44.499C105.29 53.3449 99.7258 62.2116 93.4453 69.4932C87.0622 76.8936 79.4391 83.2238 74.3574 87.0557C69.973 90.3616 64.031 90.3614 59.6465 87.0557C54.5648 83.2238 46.9408 76.8937 40.5576 69.4932C34.2771 62.2116 28.7129 53.3449 28.7129 44.499C28.713 32.8474 37.2813 23.0781 49.291 23.0781C54.9545 23.0782 60.4297 24.9062 67.001 30.9004C73.5726 24.9056 79.0491 23.0781 84.7129 23.0781Z"
            fill="none"
            stroke="#888"
            strokeWidth="5.73358"
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeDasharray="10 10"
        />
    </svg>
);

// =============================================================================
// Types
// =============================================================================

interface Album {
    id: number;
    name: string;
}

export interface UnlikeAlbumSelectorModalProps extends ModalVisibilityProps {
    /**
     * List of all albums the file belongs to.
     */
    albums: Album[];
    /**
     * Set of album IDs where the photo is currently liked.
     */
    likedAlbumIDs: Set<number>;
    /**
     * Called when user clicks on an album to toggle like status.
     * @param albumId The album ID
     * @param isCurrentlyLiked Whether the album is currently liked
     */
    onToggleAlbum: (albumId: number, isCurrentlyLiked: boolean) => void;
    /**
     * Called when user clicks "Unlike all" to remove likes from all albums.
     */
    onUnlikeAll: () => void;
}

/**
 * Modal dialog for managing likes across albums.
 * Shown when the like button is clicked and the photo is liked
 * in multiple albums (from gallery view).
 */
export const UnlikeAlbumSelectorModal: React.FC<
    UnlikeAlbumSelectorModalProps
> = ({ open, onClose, albums, likedAlbumIDs, onToggleAlbum, onUnlikeAll }) => {
    const likedCount = likedAlbumIDs.size;

    return (
        <StyledDialog open={open} onClose={onClose}>
            <DialogWrapper>
                <CloseButton onClick={onClose}>
                    <CloseIcon sx={{ fontSize: 20 }} />
                </CloseButton>

                <ContentContainer>
                    <IllustrationWrapper>
                        <UnlikePhotoIllustration />
                    </IllustrationWrapper>

                    <TitleSection>
                        <Title>Unlike photo</Title>
                        <Subtitle>
                            Select the album to unlike the photo from
                        </Subtitle>
                    </TitleSection>

                    <AlbumsSection>
                        <AlbumsHeader>
                            <AlbumsCount>{albums.length} Albums</AlbumsCount>
                            <UnlikeAllButton
                                onClick={likedCount > 0 ? onUnlikeAll : undefined}
                                sx={{ opacity: likedCount > 0 ? 1 : 0.5, cursor: likedCount > 0 ? "pointer" : "default" }}
                            >
                                <Typography
                                    sx={(theme) => ({
                                        fontWeight: 500,
                                        fontSize: 14,
                                        color: "#000",
                                        ...theme.applyStyles("dark", {
                                            color: "#fff",
                                        }),
                                    })}
                                >
                                    Unlike all
                                </Typography>
                                <HeartFilledIcon
                                    size={16}
                                    color="var(--mui-palette-text-base)"
                                />
                            </UnlikeAllButton>
                        </AlbumsHeader>

                        <AlbumsList>
                            {albums.map((album) => {
                                const isLiked = likedAlbumIDs.has(album.id);
                                return (
                                    <AlbumItem key={album.id}>
                                        <AlbumName>{album.name}</AlbumName>
                                        <HeartButton
                                            onClick={() =>
                                                onToggleAlbum(album.id, isLiked)
                                            }
                                        >
                                            {isLiked ? (
                                                <HeartFilledIcon />
                                            ) : (
                                                <HeartOutlineIcon />
                                            )}
                                        </HeartButton>
                                    </AlbumItem>
                                );
                            })}
                        </AlbumsList>
                    </AlbumsSection>
                </ContentContainer>
            </DialogWrapper>
        </StyledDialog>
    );
};

// =============================================================================
// Styled Components
// =============================================================================

const StyledDialog = styled(Dialog)(({ theme }) => ({
    "& .MuiDialog-paper": {
        width: 381,
        maxWidth: "calc(100% - 32px)",
        borderRadius: 28,
        backgroundColor: "#fff",
        padding: 0,
        margin: 16,
        overflow: "visible",
        boxShadow: "none",
        border: "1px solid #E0E0E0",
        ...theme.applyStyles("dark", {
            backgroundColor: "#1b1b1b",
            border: "1px solid rgba(255, 255, 255, 0.18)",
        }),
    },
    "& .MuiBackdrop-root": { backgroundColor: "rgba(0, 0, 0, 0.5)" },
}));

const DialogWrapper = styled(Box)(() => ({
    position: "relative",
    padding: "58px 24px 24px 24px",
}));

const CloseButton = styled(IconButton)(({ theme }) => ({
    position: "absolute",
    top: 11,
    right: 12,
    backgroundColor: "#FAFAFA",
    color: "#000",
    padding: 10,
    "&:hover": { backgroundColor: "#F0F0F0" },
    ...theme.applyStyles("dark", {
        backgroundColor: "rgba(255, 255, 255, 0.12)",
        color: "#fff",
        "&:hover": { backgroundColor: "rgba(255, 255, 255, 0.16)" },
    }),
}));

const ContentContainer = styled(Box)(() => ({
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    gap: 16,
}));

const IllustrationWrapper = styled(Box)(() => ({
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
    marginBottom: -12,
}));

const TitleSection = styled(Box)(() => ({
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    gap: 9,
    textAlign: "center",
    marginBottom: 14,
}));

const Title = styled(Typography)(({ theme }) => ({
    fontWeight: 600,
    fontSize: 24,
    lineHeight: "22px",
    letterSpacing: "-0.48px",
    color: "#000",
    ...theme.applyStyles("dark", { color: "#fff" }),
}));

const Subtitle = styled(Typography)(({ theme }) => ({
    fontWeight: 500,
    fontSize: 14,
    lineHeight: "17px",
    color: "#666666",
    maxWidth: 295,
    ...theme.applyStyles("dark", { color: "rgba(255, 255, 255, 0.7)" }),
}));

const AlbumsSection = styled(Box)(({ theme }) => ({
    width: "100%",
    backgroundColor: "rgba(162, 162, 162, 0.12)",
    borderRadius: 27,
    padding: "16px 0 0 0",
    maxHeight: 313,
    display: "flex",
    flexDirection: "column",
    overflow: "hidden",
    ...theme.applyStyles("dark", {
        backgroundColor: "rgba(162, 162, 162, 0.12)",
    }),
}));

const AlbumsHeader = styled(Box)(() => ({
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    padding: "0 16px 0 25px",
    marginBottom: 16,
}));

const AlbumsCount = styled(Typography)(({ theme }) => ({
    fontWeight: 500,
    fontSize: 14,
    lineHeight: "17px",
    color: "#000",
    ...theme.applyStyles("dark", { color: "#fff" }),
}));

const UnlikeAllButton = styled(Box)(({ theme }) => ({
    display: "flex",
    alignItems: "center",
    gap: 10,
    padding: 10,
    backgroundColor: "#fff",
    borderRadius: 14,
    cursor: "pointer",
    "&:hover": { backgroundColor: "#EBEBEB" },
    ...theme.applyStyles("dark", {
        backgroundColor: "#1b1b1b",
        "&:hover": { backgroundColor: "#252525" },
    }),
}));

const AlbumsList = styled(Box)(({ theme }) => ({
    display: "flex",
    flexDirection: "column",
    gap: 6,
    padding: "0 12px 12px 12px",
    overflowY: "auto",
    maxHeight: 241,
    "&::-webkit-scrollbar": { width: 6 },
    "&::-webkit-scrollbar-track": { background: "transparent" },
    "&::-webkit-scrollbar-thumb": {
        background: "rgba(0, 0, 0, 0.2)",
        borderRadius: 3,
    },
    ...theme.applyStyles("dark", {
        "&::-webkit-scrollbar-thumb": {
            background: "rgba(255, 255, 255, 0.2)",
        },
    }),
}));

const AlbumItem = styled(Box)(({ theme }) => ({
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    gap: 12,
    padding: "10px 10px 10px 16px",
    backgroundColor: "#fff",
    borderRadius: 16,
    ...theme.applyStyles("dark", { backgroundColor: "#212121" }),
}));

const AlbumName = styled(Typography)(({ theme }) => ({
    fontWeight: 500,
    fontSize: 14,
    lineHeight: "17px",
    color: "#000",
    flex: 1,
    ...theme.applyStyles("dark", { color: "#fff" }),
}));

const HeartButton = styled(Box)(() => ({
    width: 32,
    height: 32,
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "rgba(8, 194, 37, 0.06)",
    borderRadius: 9.6,
    cursor: "pointer",
    "&:hover": { backgroundColor: "rgba(8, 194, 37, 0.12)" },
}));
