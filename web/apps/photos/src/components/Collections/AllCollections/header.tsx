import {
    FlexWrapper,
    FluidContainer,
    IconButtonWithBG,
} from "@ente/shared/components/Container";
import Close from "@mui/icons-material/Close";
import { Box, DialogTitle, Stack, Typography } from "@mui/material";
import { CollectionsSortOptions } from "components/Collections/CollectionListSortOptions";
import { t } from "i18next";

export default function AllCollectionsHeader({
    onClose,
    collectionCount,
    collectionSortBy,
    setCollectionSortBy,
    isInHiddenSection,
}) {
    return (
        <DialogTitle>
            <FlexWrapper>
                <FluidContainer mr={1.5}>
                    <Box>
                        <Typography variant="h3">
                            {isInHiddenSection
                                ? t("all_hidden_albums")
                                : t("all_albums")}
                        </Typography>
                        <Typography variant="small" color={"text.muted"}>
                            {t("albums_count", { count: collectionCount })}
                        </Typography>
                    </Box>
                </FluidContainer>
                <Stack direction="row" spacing={1.5}>
                    <CollectionsSortOptions
                        activeSortBy={collectionSortBy}
                        setSortBy={setCollectionSortBy}
                        nestedInDialog
                    />
                    <IconButtonWithBG onClick={onClose}>
                        <Close />
                    </IconButtonWithBG>
                </Stack>
            </FlexWrapper>
        </DialogTitle>
    );
}
