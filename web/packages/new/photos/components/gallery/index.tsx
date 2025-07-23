/**
 * @file code that really belongs to pages/gallery.tsx itself (or related
 * files), but it written here in a separate file so that we can write in this
 * package that has TypeScript strict mode enabled.
 *
 * Once the original gallery.tsx is strict mode, this code can be inlined back
 * there.
 */

import AddPhotoAlternateIcon from "@mui/icons-material/AddPhotoAlternateOutlined";
import FolderIcon from "@mui/icons-material/FolderOutlined";
import { Paper, Stack, styled, Typography } from "@mui/material";
import { CenteredFill } from "ente-base/components/containers";
import { EnteLogo } from "ente-base/components/EnteLogo";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { type UploadTypeSelectorIntent } from "ente-gallery/components/Upload";
import type { SearchSuggestion } from "ente-new/photos/services/search/types";
import { t } from "i18next";
import React, { useState } from "react";
import { Trans } from "react-i18next";
import { enableML } from "../../services/ml";
import { EnableML, FaceConsent } from "../sidebar/MLSettings";
import { useMLStatusSnapshot } from "../utils/use-snapshot";
import { useWrapAsyncOperation } from "../utils/use-wrap-async";
import { GalleryItemsHeaderAdapter, GalleryItemsSummary } from "./ListHeader";

/**
 * Options to customize the behaviour of the remote pull that gets triggered on
 * various actions within the gallery and its descendants.
 */
export interface RemotePullOpts {
    /**
     * Perform the pull without showing a global loading bar
     *
     * Default: `false`.
     */
    silent?: boolean;
}
/**
 * The context in which a selection was made.
 *
 * This allows us to reset the selection if user moves to a different context
 * and starts a new selection.
 * */
export type SelectionContext =
    | { mode: "albums" | "hidden-albums"; collectionID: number }
    | { mode: "people"; personID: string };

interface SearchResultsHeaderProps {
    searchSuggestion: SearchSuggestion;
    fileCount: number;
}

export const SearchResultsHeader: React.FC<SearchResultsHeaderProps> = ({
    searchSuggestion,
    fileCount,
}) => (
    <GalleryItemsHeaderAdapter>
        <Typography
            variant="h6"
            sx={{ fontWeight: "regular", color: "text.muted" }}
        >
            {t("search_results")}
        </Typography>
        <GalleryItemsSummary
            name={searchSuggestion.label}
            fileCount={fileCount}
        />
    </GalleryItemsHeaderAdapter>
);

interface GalleryEmptyStateProps {
    /**
     * If `true`, then an upload is already in progress (the empty state will
     * then disable the prompts for uploads).
     */
    isUploadInProgress: boolean;
    /**
     * Called when the user selects one of the upload buttons. It is passed the
     * "intent" of the user.
     */
    onUpload: (intent: UploadTypeSelectorIntent) => void;
}

export const GalleryEmptyState: React.FC<GalleryEmptyStateProps> = ({
    isUploadInProgress,
    onUpload,
}) => (
    <Stack sx={{ alignItems: "center" }}>
        <Stack
            sx={{
                alignItems: "center",
                textAlign: "center",
                paddingBlock: "12px 32px",
                userSelect: "none",
            }}
        >
            <Typography
                variant="h3"
                sx={{
                    color: "text.muted",
                    mb: 1,
                    svg: {
                        color: "text.base",
                        verticalAlign: "middle",
                        mb: "2px",
                    },
                }}
            >
                <Trans
                    i18nKey="welcome_to_ente_title"
                    components={{ a: <EnteLogo /> }}
                />
            </Typography>
            <Typography variant="h2">
                {t("welcome_to_ente_subtitle")}
            </Typography>
        </Stack>
        <NonDraggableImage
            height={287.57}
            alt=""
            src="/images/empty-state/ente_duck.png"
            srcSet="/images/empty-state/ente_duck@2x.png, /images/empty-state/ente_duck@3x.png"
        />
        <Stack sx={{ py: 3, width: 320, gap: 1 }}>
            <FocusVisibleButton
                color="accent"
                onClick={() => onUpload("upload")}
                disabled={isUploadInProgress}
                sx={{ p: 1 }}
            >
                <Stack direction="row" sx={{ gap: 1, alignItems: "center" }}>
                    <AddPhotoAlternateIcon />
                    {t("upload_first_photo")}
                </Stack>
            </FocusVisibleButton>
            <FocusVisibleButton
                onClick={() => onUpload("import")}
                disabled={isUploadInProgress}
                sx={{ p: 1 }}
            >
                <Stack direction="row" sx={{ gap: 1, alignItems: "center" }}>
                    <FolderIcon />
                    {t("import_your_folders")}
                </Stack>
            </FocusVisibleButton>
        </Stack>
    </Stack>
);

/**
 * Prevent the image from being selected _and_ dragged, since dragging it
 * triggers the our dropdown selector overlay.
 */
const NonDraggableImage = styled("img")`
    pointer-events: none;
    user-select: none;
`;

export const PeopleEmptyState: React.FC = () => {
    const mlStatus = useMLStatusSnapshot();

    switch (mlStatus?.phase) {
        case "disabled":
            return <PeopleEmptyStateDisabled />;
        case "done":
            return (
                <PeopleEmptyStateMessage>
                    {t("people_empty_too_few")}
                </PeopleEmptyStateMessage>
            );
        default:
            return (
                <PeopleEmptyStateMessage>
                    {t("syncing_wait")}
                </PeopleEmptyStateMessage>
            );
    }
};

export const PeopleEmptyStateMessage: React.FC<React.PropsWithChildren> = ({
    children,
}) => (
    <CenteredFill>
        <Typography
            sx={{
                color: "text.muted",
                mx: 1,
                // Approximately compensate for the hidden section bar (86px),
                // and then add a bit extra padding so that the message appears
                // visually off the center, towards the top.
                paddingBlockEnd: "126px",
            }}
        >
            {children}
        </Typography>
    </CenteredFill>
);

export const PeopleEmptyStateDisabled: React.FC = () => {
    const [showConsent, setShowConsent] = useState(false);

    const handleConsent = useWrapAsyncOperation(async () => {
        await enableML();
    });

    return (
        <Stack sx={{ alignItems: "center", flex: 1, overflow: "auto" }}>
            <Paper
                // Top margin is to prevent clipping of the shadow.
                sx={{ maxWidth: "390px", padding: "4px", mt: 1, mb: "2rem" }}
            >
                {!showConsent ? (
                    <EnableML onEnable={() => setShowConsent(true)} />
                ) : (
                    <FaceConsent
                        onConsent={handleConsent}
                        onCancel={() => setShowConsent(false)}
                    />
                )}
            </Paper>
        </Stack>
    );
};
