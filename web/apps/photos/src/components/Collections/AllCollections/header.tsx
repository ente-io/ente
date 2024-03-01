import {
    FlexWrapper,
    FluidContainer,
    IconButtonWithBG,
} from "@ente/shared/components/Container";
import Close from "@mui/icons-material/Close";
import { Box, DialogTitle, Stack, Typography } from "@mui/material";
import CollectionListSortBy from "components/Collections/CollectionListSortBy";
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
                                ? t("ALL_HIDDEN_ALBUMS")
                                : t("ALL_ALBUMS")}
                        </Typography>
                        <Typography variant="small" color={"text.muted"}>
                            {t("albums", { count: collectionCount })}
                        </Typography>
                    </Box>
                </FluidContainer>
                <Stack direction="row" spacing={1.5}>
                    <CollectionListSortBy
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
