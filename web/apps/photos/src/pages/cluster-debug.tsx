import { SelectionBar } from "@/base/components/Navbar";
import { pt } from "@/base/i18n";
import {
    faceCrop,
    wipClusterPageContents,
    type FaceFileNeighbour,
    type FaceFileNeighbours,
} from "@/new/photos/services/ml";
import {
    FlexWrapper,
    FluidContainer,
    VerticallyCentered,
} from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import BackButton from "@mui/icons-material/ArrowBackOutlined";
import { Box, IconButton, styled, Typography } from "@mui/material";
import { useRouter } from "next/router";
import { AppContext } from "pages/_app";
import React, { useContext, useEffect, useMemo, useRef, useState } from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import { VariableSizeList } from "react-window";

// TODO-Cluster Temporary component for debugging
export default function ClusterDebug() {
    const { startLoading, finishLoading, showNavBar } = useContext(AppContext);
    const [faceFNs, setFaceFNs] = useState<FaceFileNeighbours[]>(null);

    useEffect(() => {
        showNavBar(true);
        cluster();
    }, []);

    const cluster = async () => {
        startLoading();
        setFaceFNs(await wipClusterPageContents());
        finishLoading();
    };

    return (
        <>
            {faceFNs ? (
                <Container>
                    <AutoSizer>
                        {({ height, width }) => (
                            <ClusterPhotoList
                                width={width}
                                height={height}
                                faceFNs={faceFNs}
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
    faceFNs: FaceFileNeighbours[];
}

const ClusterPhotoList: React.FC<ClusterPhotoListProps> = ({
    height,
    width,
    faceFNs,
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
        setItemList(itemListFromFaceFNs(faceFNs, columns));
    }, [columns, faceFNs]);

    useEffect(() => {
        listRef.current?.resetAfterIndex(0);
    }, [itemList]);

    const getItemSize = (i: number) =>
        typeof itemList[i] == "number" ? 36 : listItemHeight;

    const generateKey = (i: number) =>
        typeof itemList[i] == "number"
            ? `${itemList[i]}-${i}`
            : `${itemList[i][0].enteFile.id}/${itemList[i][0].face.faceID}-${itemList[i].slice(-1)[0].enteFile.id}/${itemList[i].slice(-1)[0].face.faceID}-${i}`;

    return (
        <VariableSizeList
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
                            {typeof item == "number" ? (
                                <LabelContainer span={columns}>
                                    {`score ${item.toFixed(2)}`}
                                </LabelContainer>
                            ) : (
                                item.map((ffn, i) => (
                                    <FaceItem key={i.toString()} {...ffn} />
                                ))
                            )}
                        </ListContainer>
                    </ListItem>
                );
            }}
        </VariableSizeList>
    );
};

type ItemListItem = number | FaceFileNeighbour[];

const itemListFromFaceFNs = (
    faceFNs: FaceFileNeighbours[],
    columns: number,
) => {
    const result: ItemListItem[] = [];
    for (let index = 0; index < faceFNs.length; index++) {
        const { face, neighbours } = faceFNs[index];
        result.push(face.score);
        let lastIndex = 0;
        while (lastIndex < neighbours.length) {
            result.push(neighbours.slice(lastIndex, lastIndex + columns));
            lastIndex += columns;
        }
    }
    return result;
};

const getFractionFittableColumns = (width: number) =>
    (width - 2 * getGapFromScreenEdge(width) + 4) / (120 + 4);

const getGapFromScreenEdge = (width: number) => (width > 4 * 120 ? 24 : 4);

const getShrinkRatio = (width: number, columns: number) =>
    (width - 2 * getGapFromScreenEdge(width) - (columns - 1) * 4) /
    (columns * 120);

const FaceItem: React.FC<FaceFileNeighbour> = ({
    face,
    enteFile,
    cosineSimilarity,
}) => {
    const { faceID } = face;

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

    return (
        <FaceChip>
            {objectURL && (
                <img
                    style={{
                        objectFit: "cover",
                        width: "100%",
                        height: "100%",
                    }}
                    src={objectURL}
                />
            )}
            <Typography variant="small" textAlign="right">
                {cosineSimilarity.toFixed(2)}
            </Typography>
        </FaceChip>
    );
};

const FaceChip = styled(Box)`
    width: 120px;
    height: 120px;
`;

const ListContainer = styled(Box, {
    shouldForwardProp: (propName) => propName != "shrinkRatio",
})<{
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

const ListItem = styled("div")`
    display: flex;
    justify-content: center;
`;
