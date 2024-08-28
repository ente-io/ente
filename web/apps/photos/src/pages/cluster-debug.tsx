import { SelectionBar } from "@/base/components/Navbar";
import { pt } from "@/base/i18n";
import { wipClusterPageContents } from "@/new/photos/services/ml";
import type { Face } from "@/new/photos/services/ml/face";
import { EnteFile } from "@/new/photos/types/file";
import {
    FlexWrapper,
    FluidContainer,
    VerticallyCentered,
} from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import BackButton from "@mui/icons-material/ArrowBackOutlined";
import { Box, IconButton, styled } from "@mui/material";
import PreviewCard from "components/pages/gallery/PreviewCard";
import {
    DATE_CONTAINER_HEIGHT,
    GAP_BTW_TILES,
    IMAGE_CONTAINER_MAX_HEIGHT,
    IMAGE_CONTAINER_MAX_WIDTH,
    MIN_COLUMNS,
    SIZE_AND_COUNT_CONTAINER_HEIGHT,
} from "constants/gallery";
import { t } from "i18next";
import { useRouter } from "next/router";
import { AppContext } from "pages/_app";
import React, { useContext, useEffect, useMemo, useRef, useState } from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import { VariableSizeList as List } from "react-window";

export interface UICluster {
    files: EnteFile[];
    face: Face;
}

// TODO-Cluster Temporary component for debugging
export default function Deduplicate() {
    const { startLoading, finishLoading, showNavBar } = useContext(AppContext);
    const [clusters, setClusters] = useState<UICluster[]>(null);

    useEffect(() => {
        showNavBar(true);
        cluster();
    }, []);

    const cluster = async () => {
        startLoading();
        const faceAndFiles = await wipClusterPageContents();
        setClusters(
            faceAndFiles.map(({ face, file }) => ({
                files: [file],
                face,
            })),
        );
        finishLoading();
    };

    return (
        <>
            {clusters ? (
                <Container>
                    <AutoSizer>
                        {({ height, width }) => (
                            <ClusterPhotoList
                                width={width}
                                height={height}
                                clusters={clusters}
                            />
                        )}
                    </AutoSizer>
                </Container>
            ) : (
                <VerticallyCentered>
                    <EnteSpinner />
                </VerticallyCentered>
            )}
            <Options />
        </>
    );
}

const Options: React.FC = () => {
    const router = useRouter();

    const close = () => {
        router.push(PAGES.GALLERY);
    };

    return (
        <SelectionBar>
            <FluidContainer>
                <IconButton onClick={close}>
                    <BackButton />
                </IconButton>
                <Box sx={{ marginInline: "auto" }}>{pt("Faces")}</Box>
            </FluidContainer>
        </SelectionBar>
    );
};

const Container = styled("div")`
    display: block;
    flex: 1;
    width: 100%;
    flex-wrap: wrap;
    margin: 0 auto;
    overflow: hidden;
    .pswp-thumbnail {
        display: inline-block;
    }
`;

interface ClusterPhotoListProps {
    height: number;
    width: number;
    clusters: UICluster[];
}

const ClusterPhotoList: React.FC<ClusterPhotoListProps> = ({
    height,
    width,
    clusters,
}) => {
    const [itemList, setItemList] = useState<ItemListItem[]>([]);
    const listRef = useRef(null);

    const getThumbnail = (
        item: EnteFile,
        index: number,
        isScrolling: boolean,
    ) => (
        <PreviewCard
            key={`tile-${item.id}`}
            file={item}
            updateURL={() => {}}
            onClick={() => {}}
            selectable={false}
            onSelect={() => {}}
            selected={false}
            selectOnClick={false}
            onHover={() => {}}
            onRangeSelect={() => {}}
            isRangeSelectActive={false}
            isInsSelectRange={false}
            activeCollectionID={0}
            showPlaceholder={isScrolling}
        />
    );

    const columns = useMemo(() => {
        const fittableColumns = getFractionFittableColumns(width);
        let columns = Math.floor(fittableColumns);
        if (columns < MIN_COLUMNS) {
            columns = MIN_COLUMNS;
        }
        return columns;
    }, [width]);

    const shrinkRatio = getShrinkRatio(width, columns);
    const listItemHeight =
        IMAGE_CONTAINER_MAX_HEIGHT * shrinkRatio + GAP_BTW_TILES;

    useEffect(() => {
        setItemList(itemListFromClusters(clusters, columns));
    }, [columns, clusters]);

    useEffect(() => {
        listRef.current?.resetAfterIndex(0);
    }, [itemList]);

    const getItemSize = (i: number) =>
        itemList[i].score !== undefined
            ? SIZE_AND_COUNT_CONTAINER_HEIGHT
            : listItemHeight;

    const generateKey = (i: number) =>
        itemList[i].score !== undefined
            ? `${itemList[i].score}-${i}`
            : `${itemList[i].files[0].id}-${itemList[i].files.slice(-1)[0].id}`;

    const renderListItem = (listItem: ItemListItem, isScrolling: boolean) =>
        listItem.score !== undefined ? (
            <SizeAndCountContainer span={columns}>
                {listItem.fileCount} {t("FILES")},{" score "}
                {listItem.score.toFixed(2)}
            </SizeAndCountContainer>
        ) : (
            listItem.files.map((item, idx) =>
                getThumbnail(item, listItem.itemStartIndex + idx, isScrolling),
            )
        );

    return (
        <List
            key={`${0}`}
            itemData={{ itemList, columns, shrinkRatio, renderListItem }}
            ref={listRef}
            itemSize={getItemSize}
            height={height}
            width={width}
            itemCount={itemList.length}
            itemKey={generateKey}
            overscanCount={3}
            useIsScrolling
        >
            {({ index, style, isScrolling, data }) => {
                const { itemList, columns, shrinkRatio, renderListItem } = data;
                return (
                    <ListItem style={style}>
                        <ListContainer
                            columns={columns}
                            shrinkRatio={shrinkRatio}
                        >
                            {renderListItem(itemList[index], isScrolling)}
                        </ListContainer>
                    </ListItem>
                );
            }}
        </List>
    );
};

const ListContainer = styled(Box)<{
    columns: number;
    shrinkRatio: number;
}>`
    display: grid;
    grid-template-columns: ${({ columns, shrinkRatio }) =>
        `repeat(${columns},${IMAGE_CONTAINER_MAX_WIDTH * shrinkRatio}px)`};
    grid-column-gap: ${GAP_BTW_TILES}px;
    width: 100%;
    color: #fff;
    padding: 0 24px;
    @media (max-width: ${IMAGE_CONTAINER_MAX_WIDTH * MIN_COLUMNS}px) {
        padding: 0 4px;
    }
`;

const ListItemContainer = styled(FlexWrapper)<{ span: number }>`
    grid-column: span ${(props) => props.span};
`;

const SizeAndCountContainer = styled(ListItemContainer)`
    height: ${DATE_CONTAINER_HEIGHT}px;
    color: ${({ theme }) => theme.colors.text.muted};
    margin-top: 1rem;
    height: ${SIZE_AND_COUNT_CONTAINER_HEIGHT}px;
`;

interface ItemListItem {
    score?: number;
    files?: EnteFile[];
    itemStartIndex?: number;
    fileCount?: number;
}

const ListItem = styled("div")`
    display: flex;
    justify-content: center;
`;

function getFractionFittableColumns(width: number): number {
    return (
        (width - 2 * getGapFromScreenEdge(width) + GAP_BTW_TILES) /
        (IMAGE_CONTAINER_MAX_WIDTH + GAP_BTW_TILES)
    );
}

function getGapFromScreenEdge(width: number) {
    if (width > MIN_COLUMNS * IMAGE_CONTAINER_MAX_WIDTH) {
        return 24;
    } else {
        return 4;
    }
}

function getShrinkRatio(width: number, columns: number) {
    return (
        (width -
            2 * getGapFromScreenEdge(width) -
            (columns - 1) * GAP_BTW_TILES) /
        (columns * IMAGE_CONTAINER_MAX_WIDTH)
    );
}

const itemListFromClusters = (clusters: UICluster[], columns: number) => {
    const result: ItemListItem[] = [];
    for (let index = 0; index < clusters.length; index++) {
        const dupes = clusters[index];
        result.push({
            score: dupes.face.score,
            fileCount: dupes.files.length,
        });
        let lastIndex = 0;
        while (lastIndex < dupes.files.length) {
            result.push({
                files: dupes.files.slice(lastIndex, lastIndex + columns),
                itemStartIndex: index,
            });
            lastIndex += columns;
        }
    }
    return result;
};
