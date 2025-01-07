import { FilledIconButton } from "@/base/components/mui";
import { CollectionsSortOptions } from "@/new/photos/components/CollectionsSortOptions";
import { SlideUpTransition } from "@/new/photos/components/mui/SlideUpTransition";
import type { CollectionSummary } from "@/new/photos/services/collection/ui";
import { CollectionsSortBy } from "@/new/photos/services/collection/ui";
import { FlexWrapper, FluidContainer } from "@ente/shared/components/Container";
import CloseIcon from "@mui/icons-material/Close";
import {
    Box,
    Dialog,
    DialogTitle,
    Divider,
    Stack,
    styled,
    Typography,
    useMediaQuery,
} from "@mui/material";
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
            open={open}
            onClose={onClose}
            TransitionComponent={SlideUpTransition}
            fullScreen={isMobile}
            fullWidth
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

export const AllCollectionMobileBreakpoint = 559;

const AllCollectionDialog = styled(Dialog)(({ theme }) => ({
    "& .MuiDialog-container": {
        justifyContent: "flex-end",
    },
    "& .MuiPaper-root": {
        maxWidth: "494px",
    },
    "& .MuiDialogTitle-root": {
        padding: theme.spacing(2),
        paddingRight: theme.spacing(1),
    },
    "& .MuiDialogContent-root": {
        padding: theme.spacing(2),
    },
    [theme.breakpoints.down(AllCollectionMobileBreakpoint)]: {
        "& .MuiPaper-root": {
            width: "324px",
        },
        "& .MuiDialogContent-root": {
            padding: 6,
        },
    },
}));

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
                        sx={{ fontWeight: "normal", color: "text.muted" }}
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
                    <CloseIcon />
                </FilledIconButton>
            </Stack>
        </FlexWrapper>
    </DialogTitle>
);
