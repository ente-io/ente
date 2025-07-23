// TODO: Audit this file.
import CloseIcon from "@mui/icons-material/Close";
import {
    Box,
    Dialog,
    DialogContent,
    DialogTitle,
    Divider,
    Stack,
    styled,
    Typography,
    useMediaQuery,
} from "@mui/material";
import { FilledIconButton } from "ente-base/components/mui";
import { CollectionsSortOptions } from "ente-new/photos/components/CollectionsSortOptions";
import { SlideUpTransition } from "ente-new/photos/components/mui/SlideUpTransition";
import {
    ItemCard,
    LargeTileButton,
    LargeTileTextOverlay,
} from "ente-new/photos/components/Tiles";
import type {
    CollectionsSortBy,
    CollectionSummary,
} from "ente-new/photos/services/collection-summary";
import { t } from "i18next";
import memoize from "memoize-one";
import React, { useEffect, useRef, useState } from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import {
    areEqual,
    FixedSizeList,
    type ListChildComponentProps,
} from "react-window";

interface AllAlbums {
    open: boolean;
    onClose: () => void;
    collectionSummaries: CollectionSummary[];
    onSelectCollectionID: (id: number) => void;
    collectionsSortBy: CollectionsSortBy;
    onChangeCollectionsSortBy: (by: CollectionsSortBy) => void;
    isInHiddenSection: boolean;
}

/**
 * A modal showing the list of all the albums.
 */
export const AllAlbums: React.FC<AllAlbums> = ({
    collectionSummaries,
    open,
    onClose,
    onSelectCollectionID,
    collectionsSortBy,
    onChangeCollectionsSortBy,
    isInHiddenSection,
}) => {
    const fullScreen = useMediaQuery("(max-width: 428px)");

    const onCollectionClick = (collectionID: number) => {
        onSelectCollectionID(collectionID);
        onClose();
    };

    return (
        <AllAlbumsDialog
            {...{ open, onClose, fullScreen }}
            slots={{ transition: SlideUpTransition }}
            fullWidth
        >
            <Title
                {...{
                    isInHiddenSection,
                    onClose,
                    collectionsSortBy,
                    onChangeCollectionsSortBy,
                }}
                collectionCount={collectionSummaries.length}
            />
            <Divider />
            <AllAlbumsContent
                collectionSummaries={collectionSummaries}
                onCollectionClick={onCollectionClick}
            />
        </AllAlbumsDialog>
    );
};

const Column3To2Breakpoint = 559;

const AllAlbumsDialog = styled(Dialog)(({ theme }) => ({
    "& .MuiDialog-container": { justifyContent: "flex-end" },
    "& .MuiPaper-root": { maxWidth: "494px" },
    "& .MuiDialogTitle-root": {
        padding: theme.spacing(2),
        paddingRight: theme.spacing(1),
    },
    "& .MuiDialogContent-root": { padding: theme.spacing(2) },
    [theme.breakpoints.down(Column3To2Breakpoint)]: {
        "& .MuiPaper-root": { width: "324px" },
        "& .MuiDialogContent-root": { padding: 6 },
    },
}));

type TitleProps = { collectionCount: number } & Pick<
    AllAlbums,
    | "onClose"
    | "collectionsSortBy"
    | "onChangeCollectionsSortBy"
    | "isInHiddenSection"
>;

const Title: React.FC<TitleProps> = ({
    onClose,
    collectionCount,
    collectionsSortBy,
    onChangeCollectionsSortBy,
    isInHiddenSection,
}) => (
    <DialogTitle>
        <Stack direction="row" sx={{ gap: 1.5 }}>
            <Stack sx={{ flex: 1 }}>
                <Box>
                    <Typography variant="h5">
                        {isInHiddenSection
                            ? t("all_hidden_albums")
                            : t("all_albums")}
                    </Typography>
                    <Typography
                        variant="small"
                        sx={{
                            color: "text.muted",
                            // Undo the effects of DialogTitle.
                            fontWeight: "regular",
                        }}
                    >
                        {t("albums_count", { count: collectionCount })}
                    </Typography>
                </Box>
            </Stack>
            <CollectionsSortOptions
                activeSortBy={collectionsSortBy}
                onChangeSortBy={onChangeCollectionsSortBy}
                nestedInDialog
            />
            <FilledIconButton onClick={onClose}>
                <CloseIcon />
            </FilledIconButton>
        </Stack>
    </DialogTitle>
);

const CollectionRowItemSize = 154;

interface ItemData {
    collectionRowList: CollectionSummary[][];
    onCollectionClick: (id?: number) => void;
}

// This helper function memoizes incoming props,
// To avoid causing unnecessary re-renders pure Row components.
// This is only needed since we are passing multiple props with a wrapper object.
// If we were only passing a single, stable value (e.g. items),
// We could just pass the value directly.
const createItemData = memoize((collectionRowList, onCollectionClick) => ({
    // TODO:
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    collectionRowList,
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    onCollectionClick,
}));

//If list items are expensive to render,
// Consider using React.memo or shouldComponentUpdate to avoid unnecessary re-renders.
// https://reactjs.org/docs/react-api.html#reactmemo
// https://reactjs.org/docs/react-api.html#reactpurecomponent
const AlbumsRow = React.memo(
    ({
        data,
        index,
        style,
        isScrolling,
    }: ListChildComponentProps<ItemData>) => {
        const { collectionRowList, onCollectionClick } = data;
        const collectionRow = collectionRowList[index]!;
        return (
            <div style={style}>
                <Stack direction="row" sx={{ p: 2, gap: 0.5 }}>
                    {collectionRow.map((item) => (
                        <AlbumCard
                            isScrolling={isScrolling}
                            onCollectionClick={onCollectionClick}
                            collectionSummary={item}
                            key={item.id}
                        />
                    ))}
                </Stack>
            </div>
        );
    },
    areEqual,
);

interface AllAlbumsContentProps {
    collectionSummaries: CollectionSummary[];
    onCollectionClick: (id: number) => void;
}

const AllAlbumsContent: React.FC<AllAlbumsContentProps> = ({
    collectionSummaries,
    onCollectionClick,
}) => {
    const isTwoColumn = useMediaQuery(`(width < ${Column3To2Breakpoint}px)`);

    const refreshInProgress = useRef(false);
    const shouldRefresh = useRef(false);

    const [collectionRowList, setCollectionRowList] = useState<
        CollectionSummary[][]
    >([]);

    const columns = isTwoColumn ? 2 : 3;
    const maxListContentHeight =
        Math.ceil(collectionSummaries.length / columns) *
            CollectionRowItemSize +
        32; /* padding above first and below last row */

    useEffect(() => {
        const main = () => {
            if (refreshInProgress.current) {
                shouldRefresh.current = true;
                return;
            }
            refreshInProgress.current = true;

            const collectionRowList: CollectionSummary[][] = [];
            let index = 0;
            while (index < collectionSummaries.length) {
                const collectionRow: CollectionSummary[] = [];
                for (
                    let i = 0;
                    i < columns && index < collectionSummaries.length;
                    i++
                ) {
                    collectionRow.push(collectionSummaries[index++]!);
                }
                collectionRowList.push(collectionRow);
            }
            setCollectionRowList(collectionRowList);
            refreshInProgress.current = false;
            if (shouldRefresh.current) {
                shouldRefresh.current = false;
                setTimeout(main, 0);
            }
        };
        main();
    }, [collectionSummaries, columns]);

    // Bundle additional data to list items using the "itemData" prop.
    // It will be accessible to item renderers as props.data.
    // Memoize this data to avoid bypassing shouldComponentUpdate().
    const itemData = createItemData(collectionRowList, onCollectionClick);

    return (
        <DialogContent
            sx={{
                "&&": { padding: 0 },
                height: "min(80svh, var(--et-max-list-content-height))",
            }}
            style={
                {
                    "--et-max-list-content-height": `${maxListContentHeight}px`,
                } as React.CSSProperties
            }
        >
            <AutoSizer>
                {({ width, height }) => (
                    <FixedSizeList
                        {...{ width, height }}
                        itemCount={collectionRowList.length}
                        itemSize={CollectionRowItemSize}
                        itemData={itemData}
                    >
                        {AlbumsRow}
                    </FixedSizeList>
                )}
            </AutoSizer>
        </DialogContent>
    );
};

interface AlbumCardProps {
    collectionSummary: CollectionSummary;
    onCollectionClick: (collectionID: number) => void;
    isScrolling?: boolean;
}

const AlbumCard: React.FC<AlbumCardProps> = ({
    onCollectionClick,
    collectionSummary,
    isScrolling,
}) => (
    <ItemCard
        TileComponent={LargeTileButton}
        coverFile={collectionSummary.coverFile}
        onClick={() => onCollectionClick(collectionSummary.id)}
        isScrolling={isScrolling}
    >
        <LargeTileTextOverlay>
            <Typography>{collectionSummary.name}</Typography>
            <Typography variant="small" sx={{ opacity: 0.7 }}>
                {t("photos_count", { count: collectionSummary.fileCount })}
            </Typography>
        </LargeTileTextOverlay>
    </ItemCard>
);
