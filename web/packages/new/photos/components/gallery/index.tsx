/**
 * @file code that really belongs to pages/gallery.tsx itself (or related
 * files), but it written here in a separate file so that we can write in this
 * package that has TypeScript strict mode enabled.
 *
 * Once the original gallery.tsx is strict mode, this code can be inlined back
 * there.
 */

import { CenteredBox } from "@/base/components/mui/Container";
import type { SearchOption } from "@/new/photos/services/search/types";
import { Typography } from "@mui/material";
import { t } from "i18next";
import React from "react";
import { useMLStatusSnapshot } from "../utils/use-snapshot";
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
    selectedOption: SearchOption;
}

export const SearchResultsHeader: React.FC<SearchResultsHeaderProps> = ({
    selectedOption,
}) => (
    <GalleryItemsHeaderAdapter>
        <Typography color="text.muted" variant="large">
            {t("search_results")}
        </Typography>
        <GalleryItemsSummary
            name={selectedOption.suggestion.label}
            fileCount={selectedOption.fileCount}
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

export const PeopleEmptyStateDisabled: React.FC = () => (
    <CenteredBox>
        <Typography
            color="text.muted"
            sx={{
                mx: 1,
                // Approximately compensate for the hidden section bar (86px),
                // and then add a bit extra padding so that the message appears
                // visually off the center, towards the top.
                paddingBlockEnd: "126px",
            }}
        >
            {"disabeld"}
        </Typography>
    </CenteredBox>
);

export const PeopleEmptyStateMessage: React.FC<React.PropsWithChildren> = ({
    children,
}) => (
    <CenteredBox>
        <Typography
            color="text.muted"
            sx={{
                mx: 1,
                // Approximately compensate for the hidden section bar (86px),
                // and then add a bit extra padding so that the message appears
                // visually off the center, towards the top.
                paddingBlockEnd: "126px",
            }}
        >
            {children}
        </Typography>
    </CenteredBox>
);
