import { FlexWrapper } from "@ente/shared/components/Container";
import { Box, styled, Typography } from "@mui/material";
import { t } from "i18next";
import React from "react";

interface CollectionInfoProps {
    name: string;
    fileCount: number;
    endIcon?: React.ReactNode;
}

/**
 * A component suitable for being used as a (non-sticky) header / summary view
 * displayed on top of the of a list of photos (or other items) being displayed
 * in the gallery view.
 */
export const CollectionInfo: React.FC<CollectionInfoProps> = ({
    name,
    fileCount,
    endIcon,
}) => {
    return (
        <div>
            <Typography variant="h3">{name}</Typography>

            <FlexWrapper>
                <Typography variant="small" color="text.muted">
                    {t("photos_count", { count: fileCount })}
                </Typography>
                {endIcon && (
                    <Box
                        sx={{ svg: { fontSize: "17px", color: "text.muted" } }}
                        ml={1.5}
                    >
                        {endIcon}
                    </Box>
                )}
            </FlexWrapper>
        </div>
    );
};

/**
 * A component suitable for wrapping a {@link GalleryItemsSummary} so that it
 * fills the entire width (and acts like a "header") when it is displayed in the
 * gallery view.
 *
 * The {@link GalleryItemsSummary} is displayed as part of the actual gallery
 * items list itself so that it scrolls alongwith the items. This wrapper makes
 * it take the full width of the conceptual "row" that it occupies.
 */
export const CollectionInfoBarWrapper = styled(Box)`
    width: 100%;
    margin-bottom: 12px;
`;
