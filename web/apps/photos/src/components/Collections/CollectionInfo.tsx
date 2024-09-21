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
 * A component suitable for being used as a sticky header / summary view
 * (displayed below the gallery bar) when showing a list of photos (or other
 * items) in the gallery view.
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
 * A component suitable for wrapping a {@link CollectionInfo} in cases where
 * the actual gallery bar is not being displayed.
 */
export const CollectionInfoBarWrapper = styled(Box)`
    width: 100%;
    margin-bottom: 12px;
`;
