/**
 * @file code that really belongs to pages/gallery.tsx itself (or related
 * files), but it written here in a separate file so that we can write in this
 * package that has TypeScript strict mode enabled.
 *
 * Once the original gallery.tsx is strict mode, this code can be inlined back
 * there.
 */

import { pt } from "@/base/i18n";
import type { SearchOption } from "@/new/photos/services/search/types";
import { VerticallyCentered } from "@ente/shared/components/Container";
import { Typography } from "@mui/material";
import { t } from "i18next";
import React from "react";
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

export const PeopleEmptyState: React.FC = () => (
    <VerticallyCentered>
        <Typography
            color="text.muted"
            sx={{
                // Approximately compensate for the hidden section bar
                paddingBlockEnd: "86px",
            }}
        >
            {pt("People will appear here once indexing completes")}
        </Typography>
    </VerticallyCentered>
);
