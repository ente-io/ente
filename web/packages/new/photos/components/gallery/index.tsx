/**
 * @file code that really belongs to pages/gallery.tsx itself (or related
 * files), but it written here in a separate file so that we can write in this
 * package that has TypeScript strict mode enabled.
 *
 * Once the original gallery.tsx is strict mode, this code can be inlined back
 * there.
 */

import { CenteredFill } from "@/base/components/containers";
import type { SearchSuggestion } from "@/new/photos/services/search/types";
import { Paper, Stack, Typography } from "@mui/material";
import { t } from "i18next";
import React, { useState } from "react";
import { enableML } from "../../services/ml";
import { EnableML, FaceConsent } from "../sidebar/MLSettings";
import { useMLStatusSnapshot } from "../utils/use-snapshot";
import { useWrapAsyncOperation } from "../utils/use-wrap-async";
import { GalleryItemsHeaderAdapter, GalleryItemsSummary } from "./ListHeader";

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
            <Paper sx={{ maxWidth: "390px", padding: "4px", mb: "2rem" }}>
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
