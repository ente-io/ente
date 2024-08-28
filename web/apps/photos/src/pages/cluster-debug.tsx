import { SelectionBar } from "@/base/components/Navbar";
import { pt } from "@/base/i18n";
import { faceCrop, wipClusterPageContents } from "@/new/photos/services/ml";
import type { Face } from "@/new/photos/services/ml/face";
import { EnteFile } from "@/new/photos/types/file";
import {
    FlexWrapper,
    FluidContainer,
    VerticallyCentered,
} from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import BackButton from "@mui/icons-material/ArrowBackOutlined";
import { Box, IconButton, styled } from "@mui/material";
import { useRouter } from "next/router";
import { AppContext } from "pages/_app";
import React, { useContext, useEffect, useMemo, useRef, useState } from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import { VariableSizeList } from "react-window";

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

    const close = () => router.push("/gallery");

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

    const columns = useMemo(
        () => Math.max(Math.floor(getFractionFittableColumns(width)), 4),
        [width],
    );

    const shrinkRatio = getShrinkRatio(width, columns);
    const listItemHeight = 120 * shrinkRatio + 4;

    useEffect(() => {
        setItemList(itemListFromClusters(clusters, columns));
    }, [columns, clusters]);

    useEffect(() => {
        listRef.current?.resetAfterIndex(0);
    }, [itemList]);

    const getItemSize = (i: number) =>
        itemList[i].score !== undefined ? 36 : listItemHeight;

    const generateKey = (i: number) =>
        itemList[i].score !== undefined
            ? `${itemList[i].score}-${i}`
            : `${itemList[i].files[0].id}-${itemList[i].files.slice(-1)[0].id}`;

    return (
        <VariableSizeList
            key={`${0}`}
            itemData={{ itemList, columns, shrinkRatio }}
            ref={listRef}
            itemSize={getItemSize}
            height={height}
            width={width}
            itemCount={itemList.length}
            itemKey={generateKey}
            overscanCount={3}
            useIsScrolling
        >
            {({ index, style, data }) => {
                const { itemList, columns, shrinkRatio } = data;
                const item = itemList[index];
                return (
                    <ListItem style={style}>
                        <ListContainer
                            columns={columns}
                            shrinkRatio={shrinkRatio}
                        >
                            {item.score !== undefined ? (
                                <LabelContainer span={columns}>
                                    {`${item.fileCount} files, score ${item.score.toFixed(2)}`}
                                </LabelContainer>
                            ) : (
                                item.files.map((enteFile) => (
                                    <FaceChip key={`${enteFile.id}`}>
                                        <FaceCropImageView
                                            enteFile={enteFile}
                                            faceID={item.face?.faceID}
                                        />
                                    </FaceChip>
                                ))
                            )}
                        </ListContainer>
                    </ListItem>
                );
            }}
        </VariableSizeList>
    );
};

const FaceChip = styled(Box)`
    width: 120px;
    height: 120px;
`;

interface FaceCropImageViewProps {
    faceID: string;
    enteFile: EnteFile;
}

const FaceCropImageView: React.FC<FaceCropImageViewProps> = ({
    faceID,
    enteFile,
}) => {
    const [objectURL, setObjectURL] = useState<string | undefined>();

    useEffect(() => {
        let didCancel = false;
        let thisObjectURL: string | undefined;

        void faceCrop(faceID, enteFile).then((blob) => {
            if (blob && !didCancel)
                setObjectURL((thisObjectURL = URL.createObjectURL(blob)));
        });

        return () => {
            didCancel = true;
            if (thisObjectURL) URL.revokeObjectURL(thisObjectURL);
        };
    }, [faceID, enteFile]);

    return objectURL ? (
        <img
            style={{ objectFit: "cover", width: "100%", height: "100%" }}
            src={objectURL}
        />
    ) : (
        <div />
    );
};

const ListContainer = styled(Box)<{
    columns: number;
    shrinkRatio: number;
}>`
    display: grid;
    grid-template-columns: ${({ columns, shrinkRatio }) =>
        `repeat(${columns},${120 * shrinkRatio}px)`};
    grid-column-gap: 4px;
    width: 100%;
    padding: 4px;
`;

const ListItemContainer = styled(FlexWrapper)<{ span: number }>`
    grid-column: span ${(props) => props.span};
`;

const LabelContainer = styled(ListItemContainer)`
    color: ${({ theme }) => theme.colors.text.muted};
    height: 32px;
`;

interface ItemListItem {
    score?: number;
    face?: Face;
    files?: EnteFile[];
    itemStartIndex?: number;
    fileCount?: number;
}

const ListItem = styled("div")`
    display: flex;
    justify-content: center;
`;

function getFractionFittableColumns(width: number): number {
    return (width - 2 * getGapFromScreenEdge(width) + 4) / (120 + 4);
}

const getGapFromScreenEdge = (width: number) => (width > 4 * 120 ? 24 : 4);

function getShrinkRatio(width: number, columns: number) {
    return (
        (width - 2 * getGapFromScreenEdge(width) - (columns - 1) * 4) /
        (columns * 120)
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
                face: dupes.face,
                itemStartIndex: index,
            });
            lastIndex += columns;
        }
    }
    return result;
};
