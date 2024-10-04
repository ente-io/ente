import { CollectionsSortOptions } from "@/new/photos/components/CollectionsSortOptions";
import { FilledIconButton } from "@/new/photos/components/mui";
import { SlideUpTransition } from "@/new/photos/components/mui/SlideUpTransition";
import type { CollectionSummary } from "@/new/photos/types/collection";
import { CollectionsSortBy } from "@/new/photos/types/collection";
import { FlexWrapper, FluidContainer } from "@ente/shared/components/Container";
import Close from "@mui/icons-material/Close";
import {
    Box,
    DialogTitle,
    Divider,
    Stack,
    Typography,
    useMediaQuery,
} from "@mui/material";
import { AllCollectionDialog } from "components/Collections/AllCollections/dialog";
import { t } from "i18next";
import AllCollectionContent from "./content";

interface AllCollectionsProps {
    open: boolean;
    onClose: () => void;
    collectionSummaries: CollectionSummary[];
    onSelectCollectionID: (id: number) => void;
    collectionsSortBy: CollectionsSortBy;
    onChangeCollectionsSortBy: (by: CollectionsSortBy) => void;
    isInHiddenSection: boolean;
}

export default function AllCollections(props: AllCollectionsProps) {
    const {
        collectionSummaries,
        open,
        onClose,
        onSelectCollectionID,
        collectionsSortBy,
        onChangeCollectionsSortBy,
        isInHiddenSection,
    } = props;
    const isMobile = useMediaQuery("(max-width: 428px)");

    const onCollectionClick = (collectionID: number) => {
        onSelectCollectionID(collectionID);
        onClose();
    };

    return (
        <AllCollectionDialog
            position="flex-end"
            TransitionComponent={SlideUpTransition}
            onClose={onClose}
            open={open}
            fullScreen={isMobile}
            fullWidth={true}
        >
            <AllCollectionsHeader
                {...{
                    isInHiddenSection,
                    onClose,
                    collectionsSortBy,
                    onChangeCollectionsSortBy,
                }}
                collectionCount={props.collectionSummaries.length}
            />
            <Divider />
            <AllCollectionContent
                collectionSummaries={collectionSummaries}
                onCollectionClick={onCollectionClick}
            />
        </AllCollectionDialog>
    );
}

const AllCollectionsHeader = ({
    onClose,
    collectionCount,
    collectionsSortBy,
    onChangeCollectionsSortBy,
    isInHiddenSection,
}) => (
    <DialogTitle>
        <FlexWrapper>
            <FluidContainer mr={1.5}>
                <Box>
                    <Typography variant="h3">
                        {isInHiddenSection
                            ? t("all_hidden_albums")
                            : t("all_albums")}
                    </Typography>
                    <Typography
                        variant="small"
                        fontWeight={"normal"}
                        color={"text.muted"}
                    >
                        {t("albums_count", { count: collectionCount })}
                    </Typography>
                </Box>
            </FluidContainer>
            <Stack direction="row" spacing={1.5}>
                <CollectionsSortOptions
                    activeSortBy={collectionsSortBy}
                    onChangeSortBy={onChangeCollectionsSortBy}
                    nestedInDialog
                />
                <FilledIconButton onClick={onClose}>
                    <Close />
                </FilledIconButton>
            </Stack>
        </FlexWrapper>
    </DialogTitle>
);
