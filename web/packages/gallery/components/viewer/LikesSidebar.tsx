import CloseIcon from "@mui/icons-material/Close";
import {
    Avatar,
    Box,
    CircularProgress,
    Drawer,
    IconButton,
    Stack,
    styled,
    Typography,
} from "@mui/material";
import { type ModalVisibilityProps } from "ente-base/components/utils/modal";
import log from "ente-base/log";
import { downloadManager } from "ente-gallery/services/download";
import type { EnteFile } from "ente-media/file";
import { getCollectionByID } from "ente-new/photos/services/collection";
import type { CollectionSummaries } from "ente-new/photos/services/collection-summary";
import {
    getFileReactions,
    type Reaction,
} from "ente-new/photos/services/reaction";
import React, { useCallback, useEffect, useMemo, useState } from "react";

// =============================================================================
// Icons
// =============================================================================

const ChevronDownIcon: React.FC = () => (
    <svg
        width="22"
        height="22"
        viewBox="0 0 20 20"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        style={{ marginLeft: -6 }}
    >
        <path
            d="M10.0007 12.5004L6.46484 8.96544L7.64401 7.78711L10.0007 10.1438L12.3573 7.78711L13.5365 8.96544L10.0007 12.5004Z"
            fill="currentColor"
        />
    </svg>
);

const HeartFilledIcon: React.FC = () => (
    <svg
        width="18"
        height="16"
        viewBox="0 0 30 26"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
    >
        <path
            d="M12.4926 23.4794C8.64537 20.6025 1.02344 14.0254 1.02344 8.10676C1.02344 4.19475 3.89425 1.02344 7.84162 1.02344C9.88707 1.02344 11.9325 1.70526 14.6598 4.43253C17.3871 1.70526 19.4325 1.02344 21.478 1.02344C25.4253 1.02344 28.2962 4.19475 28.2962 8.10676C28.2962 14.0254 20.6743 20.6025 16.827 23.4794C15.5324 24.4474 13.7872 24.4474 12.4926 23.4794Z"
            fill="#08C225"
            stroke="#08C225"
            strokeWidth="2.04545"
            strokeLinecap="round"
            strokeLinejoin="round"
        />
    </svg>
);

// =============================================================================
// Types
// =============================================================================

/** A liker with display info. */
interface Liker {
    id: string;
    userID: number;
    userName: string;
}

/** Collection info for the dropdown. */
interface CollectionInfo {
    id: number;
    name: string;
    likeCount: number;
    coverFile?: EnteFile;
}

// =============================================================================
// Main Component
// =============================================================================

export interface LikesSidebarProps extends ModalVisibilityProps {
    /**
     * The file whose likes are being displayed.
     */
    file?: EnteFile;
    /**
     * The currently active collection ID (when viewing from within a collection).
     */
    activeCollectionID?: number;
    /**
     * A mapping from file IDs to the IDs of collections they belong to.
     */
    fileNormalCollectionIDs?: Map<number, number[]>;
    /**
     * Collection summaries indexed by their IDs.
     */
    collectionSummaries?: CollectionSummaries;
}

/**
 * A sidebar panel for displaying users who liked a file.
 */
export const LikesSidebar: React.FC<LikesSidebarProps> = ({
    open,
    onClose,
    file,
    activeCollectionID,
    fileNormalCollectionIDs,
    collectionSummaries,
}) => {
    const [loading, setLoading] = useState(false);
    const [collectionDropdownOpen, setCollectionDropdownOpen] = useState(false);

    // Reactions grouped by collection: collectionID -> reactions
    const [reactionsByCollection, setReactionsByCollection] = useState<
        Map<number, Reaction[]>
    >(new Map());

    // User ID to email mapping built from fetched collections
    const [userIDToEmail, setUserIDToEmail] = useState<Map<number, string>>(
        new Map(),
    );

    // Selected collection for viewing likes (when in gallery view)
    const [selectedCollectionID, setSelectedCollectionID] = useState<
        number | undefined
    >(undefined);

    // Thumbnail URLs for each collection's cover file: collectionID -> URL
    const [thumbnailURLs, setThumbnailURLs] = useState<Map<number, string>>(
        new Map(),
    );

    // Check if opened from a collection context
    const hasCollectionContext =
        activeCollectionID !== undefined && activeCollectionID !== 0;

    // Get all collections the file belongs to
    const fileCollectionIDs = useMemo(() => {
        if (!file) return [];
        return fileNormalCollectionIDs?.get(file.id) ?? [];
    }, [file, fileNormalCollectionIDs]);

    // Build collection info list with like counts and cover files
    const collectionsInfo = useMemo((): CollectionInfo[] => {
        return fileCollectionIDs.map((collectionID) => {
            const summary = collectionSummaries?.get(collectionID);
            return {
                id: collectionID,
                name: summary?.name ?? `Album ${collectionID}`,
                likeCount:
                    reactionsByCollection
                        .get(collectionID)
                        ?.filter((r) => r.reactionType === "green_heart")
                        .length ?? 0,
                coverFile: summary?.coverFile,
            };
        });
    }, [fileCollectionIDs, collectionSummaries, reactionsByCollection]);

    // Currently selected collection info
    const selectedCollectionInfo = useMemo(() => {
        const targetID = hasCollectionContext
            ? activeCollectionID
            : selectedCollectionID;
        return (
            collectionsInfo.find((c) => c.id === targetID) ?? collectionsInfo[0]
        );
    }, [
        hasCollectionContext,
        activeCollectionID,
        selectedCollectionID,
        collectionsInfo,
    ]);

    // Get likers for the selected collection
    const likers = useMemo((): Liker[] => {
        if (!selectedCollectionInfo) return [];
        const reactions =
            reactionsByCollection.get(selectedCollectionInfo.id) ?? [];
        return reactions
            .filter((r) => r.reactionType === "green_heart")
            .map((r) => ({
                id: r.id,
                userID: r.userID,
                userName: userIDToEmail.get(r.userID) ?? `User ${r.userID}`,
            }));
    }, [selectedCollectionInfo, reactionsByCollection, userIDToEmail]);

    // Fetch reactions when the sidebar opens or file changes
    const fetchReactions = useCallback(async () => {
        if (!file || !open) return;

        setLoading(true);
        const newReactionsByCollection = new Map<number, Reaction[]>();
        const newUserIDToEmail = new Map<number, string>();

        try {
            if (hasCollectionContext && activeCollectionID) {
                // Collection view: only fetch for the active collection
                const collection = await getCollectionByID(activeCollectionID);

                // Build user ID to email map from collection owner and sharees
                if (collection.owner.email) {
                    newUserIDToEmail.set(
                        collection.owner.id,
                        collection.owner.email,
                    );
                }
                for (const sharee of collection.sharees) {
                    if (sharee.email) {
                        newUserIDToEmail.set(sharee.id, sharee.email);
                    }
                }

                const reactions = await getFileReactions(
                    activeCollectionID,
                    file.id,
                    collection.key,
                );
                newReactionsByCollection.set(activeCollectionID, reactions);
            } else {
                // Gallery view: fetch for all collections the file belongs to
                for (const collectionID of fileCollectionIDs) {
                    try {
                        const collection =
                            await getCollectionByID(collectionID);

                        // Build user ID to email map from collection owner and sharees
                        if (collection.owner.email) {
                            newUserIDToEmail.set(
                                collection.owner.id,
                                collection.owner.email,
                            );
                        }
                        for (const sharee of collection.sharees) {
                            if (sharee.email) {
                                newUserIDToEmail.set(sharee.id, sharee.email);
                            }
                        }

                        const reactions = await getFileReactions(
                            collectionID,
                            file.id,
                            collection.key,
                        );
                        newReactionsByCollection.set(collectionID, reactions);
                    } catch (e) {
                        log.error(
                            `Failed to fetch reactions for collection ${collectionID}`,
                            e,
                        );
                    }
                }
            }
            setReactionsByCollection(newReactionsByCollection);
            setUserIDToEmail(newUserIDToEmail);
        } catch (e) {
            log.error("Failed to fetch reactions", e);
        } finally {
            setLoading(false);
        }
    }, [
        file,
        open,
        hasCollectionContext,
        activeCollectionID,
        fileCollectionIDs,
    ]);

    // Fetch reactions when the sidebar opens
    useEffect(() => {
        if (open) {
            void fetchReactions();
        }
    }, [open, fetchReactions]);

    // Set initial selected collection when file collection IDs are available
    useEffect(() => {
        if (
            open &&
            !hasCollectionContext &&
            selectedCollectionID === undefined &&
            fileCollectionIDs.length > 0
        ) {
            setSelectedCollectionID(fileCollectionIDs[0]);
        }
    }, [open, hasCollectionContext, selectedCollectionID, fileCollectionIDs]);

    // Fetch thumbnails for each collection's cover file
    useEffect(() => {
        // Only fetch when open, don't clear when closing (avoids flash during animation)
        if (!open || collectionsInfo.length === 0) {
            return;
        }

        let didCancel = false;

        const fetchThumbnails = async () => {
            const urls = new Map<number, string>();
            for (const collection of collectionsInfo) {
                if (collection.coverFile) {
                    try {
                        const url =
                            await downloadManager.renderableThumbnailURL(
                                collection.coverFile,
                            );
                        if (!didCancel && url) {
                            urls.set(collection.id, url);
                        }
                    } catch (e) {
                        log.warn(
                            `Failed to fetch thumbnail for collection ${collection.id}`,
                            e,
                        );
                    }
                }
            }
            if (!didCancel) {
                setThumbnailURLs(urls);
            }
        };

        void fetchThumbnails();

        return () => {
            didCancel = true;
        };
    }, [open, collectionsInfo]);

    const handleCollectionSelect = (collectionID: number) => {
        setSelectedCollectionID(collectionID);
        setCollectionDropdownOpen(false);
    };

    const showOverlay = collectionDropdownOpen;

    return (
        <SidebarDrawer open={open} onClose={onClose} anchor="right">
            <DrawerContentWrapper>
                {showOverlay && (
                    <ContextMenuOverlay
                        onClick={() => {
                            setCollectionDropdownOpen(false);
                        }}
                    />
                )}
                <Header>
                    {hasCollectionContext ? (
                        <Typography
                            sx={(theme) => ({
                                color: "#000",
                                fontWeight: 600,
                                ...theme.applyStyles("dark", { color: "#fff" }),
                            })}
                        >
                            {loading
                                ? "Loading..."
                                : `${likers.length} ${likers.length === 1 ? "like" : "likes"}`}
                        </Typography>
                    ) : collectionsInfo.length > 1 ? (
                        <Box
                            sx={{
                                position: "relative",
                                zIndex: collectionDropdownOpen ? 12 : "auto",
                            }}
                        >
                            <CollectionDropdownButton
                                onClick={() =>
                                    setCollectionDropdownOpen(
                                        !collectionDropdownOpen,
                                    )
                                }
                            >
                                <Box sx={{ position: "relative" }}>
                                    {selectedCollectionInfo &&
                                    thumbnailURLs.get(
                                        selectedCollectionInfo.id,
                                    ) ? (
                                        <CollectionThumbnail
                                            src={thumbnailURLs.get(
                                                selectedCollectionInfo.id,
                                            )}
                                            alt=""
                                        />
                                    ) : (
                                        <CollectionThumbnailPlaceholder />
                                    )}
                                    <CollectionBadge>
                                        {selectedCollectionInfo?.likeCount ?? 0}
                                    </CollectionBadge>
                                </Box>
                                <Typography
                                    sx={(theme) => ({
                                        color: "#000",
                                        fontWeight: 600,
                                        fontSize: 14,
                                        lineHeight: "20px",
                                        ...theme.applyStyles("dark", {
                                            color: "#fff",
                                        }),
                                    })}
                                >
                                    {selectedCollectionInfo?.name ?? "Album"}
                                </Typography>
                                <ChevronDownIcon />
                            </CollectionDropdownButton>
                            {collectionDropdownOpen && (
                                <CollectionDropdownMenu>
                                    {collectionsInfo.map((collection) => (
                                        <CollectionDropdownItem
                                            key={collection.id}
                                            onClick={() =>
                                                handleCollectionSelect(
                                                    collection.id,
                                                )
                                            }
                                        >
                                            <Box sx={{ position: "relative" }}>
                                                {thumbnailURLs.get(
                                                    collection.id,
                                                ) ? (
                                                    <CollectionThumbnail
                                                        src={thumbnailURLs.get(
                                                            collection.id,
                                                        )}
                                                        alt=""
                                                    />
                                                ) : (
                                                    <CollectionThumbnailPlaceholder />
                                                )}
                                                <CollectionBadge>
                                                    {collection.likeCount}
                                                </CollectionBadge>
                                            </Box>
                                            <Typography
                                                sx={(theme) => ({
                                                    color: "#000",
                                                    fontWeight: 600,
                                                    fontSize: 14,
                                                    lineHeight: "20px",
                                                    ...theme.applyStyles(
                                                        "dark",
                                                        { color: "#fff" },
                                                    ),
                                                })}
                                            >
                                                {collection.name}
                                            </Typography>
                                        </CollectionDropdownItem>
                                    ))}
                                </CollectionDropdownMenu>
                            )}
                        </Box>
                    ) : (
                        <Typography
                            sx={(theme) => ({
                                color: "#000",
                                fontWeight: 600,
                                ...theme.applyStyles("dark", { color: "#fff" }),
                            })}
                        >
                            {loading
                                ? "Loading..."
                                : `${likers.length} ${likers.length === 1 ? "like" : "likes"}`}
                        </Typography>
                    )}
                    <CloseButton onClick={onClose}>
                        <CloseIcon sx={{ fontSize: 22 }} />
                    </CloseButton>
                </Header>

                <LikersContainer>
                    {loading ? (
                        <LoadingContainer>
                            <CircularProgress size={32} />
                        </LoadingContainer>
                    ) : likers.length === 0 ? (
                        <EmptyMessage>No likes yet</EmptyMessage>
                    ) : (
                        likers.map((liker) => (
                            <LikerRow key={liker.id}>
                                <Avatar
                                    sx={(theme) => ({
                                        width: 32,
                                        height: 32,
                                        fontSize: 14,
                                        bgcolor: "#E0E0E0",
                                        color: "#666",
                                        ...theme.applyStyles("dark", {
                                            bgcolor:
                                                "rgba(255, 255, 255, 0.16)",
                                            color: "rgba(255, 255, 255, 0.7)",
                                        }),
                                    })}
                                >
                                    {liker.userName[0]?.toUpperCase() ?? "?"}
                                </Avatar>
                                <LikerName>{liker.userName}</LikerName>
                                <HeartFilledIcon />
                            </LikerRow>
                        ))
                    )}
                </LikersContainer>
            </DrawerContentWrapper>
        </SidebarDrawer>
    );
};

// =============================================================================
// Styled Components
// =============================================================================

// Drawer & Layout
const SidebarDrawer = styled(Drawer)(({ theme }) => ({
    "& .MuiDrawer-paper": {
        width: "23vw",
        minWidth: "520px",
        maxWidth: "calc(100% - 32px)",
        height: "calc(100% - 32px)",
        margin: "16px",
        borderRadius: "36px",
        backgroundColor: "#fff",
        padding: "24px 24px 32px 24px",
        boxShadow: "none",
        border: "1px solid #E0E0E0",
        display: "flex",
        flexDirection: "column",
        overflow: "visible",
        "@media (max-width: 450px)": {
            width: "100%",
            minWidth: "unset",
            maxWidth: "100%",
            height: "100%",
            margin: 0,
            borderRadius: 0,
        },
        ...theme.applyStyles("dark", {
            backgroundColor: "#1b1b1b",
            border: "1px solid rgba(255, 255, 255, 0.18)",
        }),
    },
    "& .MuiBackdrop-root": { backgroundColor: "transparent" },
}));

const DrawerContentWrapper = styled(Box)(() => ({
    position: "relative",
    display: "flex",
    flexDirection: "column",
    flex: 1,
    minHeight: 0,
}));

const Header = styled(Stack)(() => ({
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 48,
}));

const CloseButton = styled(IconButton)(({ theme }) => ({
    backgroundColor: "#F5F5F7",
    color: "#000",
    padding: "8px",
    "&:hover": { backgroundColor: "#E5E5E7" },
    ...theme.applyStyles("dark", {
        backgroundColor: "rgba(255, 255, 255, 0.12)",
        color: "#fff",
        "&:hover": { backgroundColor: "rgba(255, 255, 255, 0.16)" },
    }),
}));

// Collection Dropdown
const CollectionDropdownButton = styled(Box)(({ theme }) => ({
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    gap: 14,
    padding: "5px 6px 4px 6px",
    borderRadius: 12,
    backgroundColor: "#F0F0F0",
    cursor: "pointer",
    "&:hover": { backgroundColor: "#E8E8E8" },
    ...theme.applyStyles("dark", {
        backgroundColor: "#363636",
        "&:hover": { backgroundColor: "#404040" },
    }),
}));

const CollectionThumbnail = styled("img")(() => ({
    width: 24,
    height: 24,
    borderRadius: 5,
    objectFit: "cover",
}));

const CollectionThumbnailPlaceholder = styled(Box)(() => ({
    width: 24,
    height: 24,
    borderRadius: 5,
    backgroundColor: "#08C225",
}));

const CollectionBadge = styled(Box)(({ theme }) => ({
    position: "absolute",
    bottom: 2,
    right: -4,
    display: "inline-flex",
    padding: "3px 5px",
    justifyContent: "center",
    alignItems: "center",
    borderRadius: 34,
    backgroundColor: "#FFF",
    color: "#000",
    fontSize: 10,
    fontWeight: 600,
    lineHeight: 1,
    minWidth: 14,
    ...theme.applyStyles("dark", { backgroundColor: "#fff", color: "#000" }),
}));

const CollectionDropdownMenu = styled(Box)(({ theme }) => ({
    position: "absolute",
    top: "calc(100% + 8px)",
    left: 0,
    display: "flex",
    flexDirection: "column",
    justifyContent: "center",
    alignItems: "flex-start",
    width: 184,
    padding: 6,
    gap: 12,
    borderRadius: 12,
    border: "1px solid rgba(0, 0, 0, 0.08)",
    backgroundColor: "#F0F0F0",
    zIndex: 12,
    ...theme.applyStyles("dark", {
        border: "1px solid rgba(0, 0, 0, 0.08)",
        backgroundColor: "#363636",
    }),
}));

const CollectionDropdownItem = styled(Box)(({ theme }) => ({
    display: "flex",
    alignItems: "center",
    gap: 14,
    padding: "6px 6px 3px 6px",
    borderRadius: 8,
    cursor: "pointer",
    width: "100%",
    "&:hover": { backgroundColor: "#E8E8E8" },
    ...theme.applyStyles("dark", {
        "&:hover": { backgroundColor: "rgba(255, 255, 255, 0.16)" },
    }),
}));

const LikersContainer = styled(Box)(({ theme }) => ({
    flex: 1,
    overflow: "auto",
    marginRight: -24,
    paddingRight: 24,
    "&::-webkit-scrollbar": { width: "6px" },
    "&::-webkit-scrollbar-track": { background: "transparent" },
    "&::-webkit-scrollbar-thumb": {
        background: "rgba(0, 0, 0, 0.2)",
        borderRadius: "3px",
    },
    scrollbarWidth: "thin",
    scrollbarColor: "rgba(0, 0, 0, 0.2) transparent",
    ...theme.applyStyles("dark", {
        "&::-webkit-scrollbar-thumb": {
            background: "rgba(255, 255, 255, 0.2)",
        },
        scrollbarColor: "rgba(255, 255, 255, 0.2) transparent",
    }),
}));

const LikerRow = styled(Box)(() => ({
    display: "flex",
    alignItems: "center",
    gap: 12,
    padding: "10px 10px 10px 0",
}));

const LikerName = styled(Typography)(({ theme }) => ({
    flex: 1,
    fontWeight: 500,
    color: "#000",
    fontSize: 14,
    ...theme.applyStyles("dark", { color: "#fff" }),
}));

const LoadingContainer = styled(Box)(() => ({
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
    padding: "48px 0",
}));

const EmptyMessage = styled(Typography)(({ theme }) => ({
    textAlign: "center",
    padding: "48px 0",
    color: "#666",
    ...theme.applyStyles("dark", { color: "rgba(255, 255, 255, 0.5)" }),
}));

// Context Menu Overlay
const ContextMenuOverlay = styled(Box)(() => ({
    position: "absolute",
    top: -25,
    left: -25,
    right: -25,
    bottom: -33,
    backgroundColor: "rgba(0, 0, 0, 0.6)",
    zIndex: 10,
    borderRadius: "36px",
    "@media (max-width: 450px)": { borderRadius: 0 },
}));
