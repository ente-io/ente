/**
 * @file code that really belongs to pages/gallery.tsx itself, but written here
 * in a separate file so that we can write in this package that has TypeScript
 * strict mode enabled. Once the original gallery.tsx is strict mode, this code
 * can be inlined back there.
 */

import type { SearchOption } from "@/new/photos/services/search/types";
import { Typography } from "@mui/material";
import { t } from "i18next";
import React from "react";
import { GalleryItemsHeaderAdapter, GalleryItemsSummary } from "./ListHeader";

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
