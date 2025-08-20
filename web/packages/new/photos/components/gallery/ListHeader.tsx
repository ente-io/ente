import {
    Box,
    Stack,
    styled,
    Typography,
    type TypographyProps,
} from "@mui/material";
import { t } from "i18next";
import React from "react";

interface GalleryItemsSummaryProps {
    /**
     * The name / title for the items that are being shown.
     */
    name: string;
    /**
     * Optional extra props to pass to the {@link Typography} component that
     * shows {@link name}
     */
    nameProps?: TypographyProps;
    /**
     * The number of items being shown.
     */
    fileCount: number;
    /**
     * An optional element, usually an icon, placed after the file count.
     */
    endIcon?: React.ReactNode;
    /**
     * An optional click handler for the name.
     *
     * Note: Do not use this as the primary / only mechanism for the
     * corresponding functionality to be invoked, since this click handler will
     * be accessible only to sighted mouse users. However, it is fine to use it
     * as an alternate means of invoking some function.
     */
    onNameClick?: () => void;
}

/**
 * A component suitable for being used as a summary displayed on top of the of a
 * list of photos (or other items) shown in the gallery.
 */
export const GalleryItemsSummary: React.FC<GalleryItemsSummaryProps> = ({
    name,
    nameProps,
    fileCount,
    endIcon,
    onNameClick,
}) => (
    <div>
        <Typography variant="h3" {...(nameProps ?? {})} onClick={onNameClick}>
            {name}
        </Typography>

        <Stack
            direction="row"
            sx={{
                gap: 1.5,
                // Keep height the same even when there is no endIcon
                minHeight: "24px",
            }}
        >
            <Typography variant="small" sx={{ color: "text.muted" }}>
                {t("photos_count", { count: fileCount })}
            </Typography>
            {endIcon && (
                <Box sx={{ svg: { fontSize: "17px", color: "text.muted" } }}>
                    {endIcon}
                </Box>
            )}
        </Stack>
    </div>
);

/**
 * A component suitable for wrapping a component which is acting like a gallery
 * items header so that it fills the entire width (and acts like a "header")
 * when it is displayed in the gallery view.
 *
 * The header view (e.g. a {@link GalleryItemsSummary}) is displayed as part of
 * the gallery items list itself so that it scrolls alongwith the items. This
 * wrapper makes it take the full width of the "row" that it occupies.
 */
export const GalleryItemsHeaderAdapter = styled("div")`
    width: 100%;
    margin-bottom: 12px;
`;
