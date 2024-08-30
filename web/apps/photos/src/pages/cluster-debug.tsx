import { SelectionBar } from "@/base/components/Navbar";
import { pt } from "@/base/i18n";
import {
    faceCrop,
    wipClusterDebugPageContents,
    type ClusterDebugPageContents,
} from "@/new/photos/services/ml";
import { type ClusteringOpts } from "@/new/photos/services/ml/cluster";
import { faceDirection, type Face } from "@/new/photos/services/ml/face";
import type { EnteFile } from "@/new/photos/types/file";
import {
    FlexWrapper,
    FluidContainer,
    VerticallyCentered,
} from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import BackButton from "@mui/icons-material/ArrowBackOutlined";
import {
    Box,
    Button,
    IconButton,
    MenuItem,
    Stack,
    styled,
    TextField,
    Typography,
} from "@mui/material";
import { useFormik } from "formik";
import { useRouter } from "next/router";
import { AppContext } from "pages/_app";
import React, {
    useCallback,
    useContext,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import { VariableSizeList } from "react-window";

// TODO-Cluster Temporary component for debugging
export default function ClusterDebug() {
    const { startLoading, finishLoading, showNavBar } = useContext(AppContext);

    const [clusteringOptions, setClusteringOptions] = useState<ClusteringOpts>({
        method: "linear",
        minBlur: 10,
        minScore: 0.8,
        joinThreshold: 0.7,
        batchSize: 12500,
    });
    const [clusterRes, setClusterRes] = useState<
        ClusterDebugPageContents | undefined
    >();

    const cluster = useCallback((opts: ClusteringOpts) => {
        return new Promise<boolean>((resolve) => {
            setClusteringOptions(opts);
            setClusterRes(undefined);
            startLoading();
            wipClusterDebugPageContents(opts).then((v) => {
                setClusterRes(v);
                finishLoading();
                resolve(true);
            });
        });
    }, []);

    useEffect(() => {
        showNavBar(true);
    }, []);

    return (
        <>
            <Container>
                <AutoSizer>
                    {({ height, width }) => (
                        <ClusterList
                            {...{
                                width,
                                height,
                                clusteringOptions,
                                clusterRes,
                                onCluster: cluster,
                            }}
                        />
                    )}
                </AutoSizer>
            </Container>
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
                <Box sx={{ marginInline: "auto" }}>{pt("Face Clusters")}</Box>
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

type ClusterListProps = Header1Props &
    Header2Props & {
        height: number;
        width: number;
    };

const ClusterList: React.FC<ClusterListProps> = ({
    width,
    height,
    clusteringOptions,
    onCluster,
    clusterRes,
}) => {
    const [items, setItems] = useState<Item[]>([]);
    const listRef = useRef(null);

    const columns = useMemo(
        () => Math.max(Math.floor(getFractionFittableColumns(width)), 4),
        [width],
    );

    const Header1Memo = React.memo(Header1);
    const Header2Memo = React.memo(Header2);

    const shrinkRatio = getShrinkRatio(width, columns);
    const listItemHeight = 120 * shrinkRatio + 24 + 4;

    useEffect(() => {
        setItems(clusterRes ? itemsFromClusterRes(clusterRes, columns) : []);
    }, [columns, clusterRes]);

    useEffect(() => {
        listRef.current?.resetAfterIndex(0);
    }, [items]);

    const itemKey = (index: number) =>
        index === 0 || index === 1 ? `header-${index}` : `item-${index}`;

    const getItemSize = (index: number) =>
        index === 0
            ? 140
            : index === 1
              ? 130
              : Array.isArray(items[index - 1 - 1])
                ? listItemHeight
                : 36;

    return (
        <VariableSizeList
            height={height}
            width={width}
            itemKey={itemKey}
            ref={listRef}
            itemCount={1 + 1 + items.length}
            itemSize={getItemSize}
            overscanCount={3}
        >
            {({ index, style }) => {
                if (index === 0)
                    return (
                        <div style={style}>
                            <Header1Memo
                                {...{ clusteringOptions, onCluster }}
                            />
                        </div>
                    );

                if (index === 1)
                    return (
                        <div style={style}>
                            <Header2Memo clusterRes={clusterRes} />
                        </div>
                    );

                const item = items[index - 2];
                return (
                    <ListItem style={style}>
                        <ListContainer
                            columns={columns}
                            shrinkRatio={shrinkRatio}
                        >
                            {!Array.isArray(item) ? (
                                <LabelContainer span={columns}>
                                    {item}
                                </LabelContainer>
                            ) : (
                                item.map((f, i) => (
                                    <FaceItem
                                        key={i.toString()}
                                        faceWithFile={f}
                                    />
                                ))
                            )}
                        </ListContainer>
                    </ListItem>
                );
            }}
        </VariableSizeList>
    );
};

type Item = string | FaceWithFile[];

const itemsFromClusterRes = (
    clusterRes: ClusterDebugPageContents,
    columns: number,
) => {
    const { clusterPreviewsWithFile, unclusteredFacesWithFile } = clusterRes;

    const result: Item[] = [];
    for (let index = 0; index < clusterPreviewsWithFile.length; index++) {
        const { clusterSize, faces } = clusterPreviewsWithFile[index];
        result.push(`cluster size ${clusterSize.toFixed(2)}`);
        let lastIndex = 0;
        while (lastIndex < faces.length) {
            result.push(faces.slice(lastIndex, lastIndex + columns));
            lastIndex += columns;
        }
    }

    if (unclusteredFacesWithFile.length) {
        result.push(`•• unclustered faces ${unclusteredFacesWithFile.length}`);
        let lastIndex = 0;
        while (lastIndex < unclusteredFacesWithFile.length) {
            result.push(
                unclusteredFacesWithFile.slice(lastIndex, lastIndex + columns),
            );
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

interface Header1Props {
    clusteringOptions: ClusteringOpts;
    onCluster: (opts: ClusteringOpts) => Promise<boolean>;
}

const Header1: React.FC<Header1Props> = ({ clusteringOptions, onCluster }) => {
    const toFloat = (n: number | string) =>
        typeof n == "string" ? parseFloat(n) : n;
    const { values, handleSubmit, handleChange, isSubmitting } =
        useFormik<ClusteringOpts>({
            initialValues: clusteringOptions,
            onSubmit: (values) =>
                onCluster({
                    method: values.method,
                    minBlur: toFloat(values.minBlur),
                    minScore: toFloat(values.minScore),
                    joinThreshold: toFloat(values.joinThreshold),
                    batchSize: toFloat(values.batchSize),
                }),
        });

    return (
        <form onSubmit={handleSubmit}>
            <Stack>
                <Typography paddingInline={1}>Parameters</Typography>
                <Stack direction="row" gap={1}>
                    <TextField
                        id="method"
                        name="method"
                        label="method"
                        value={values.method}
                        select
                        size="small"
                        onChange={handleChange}
                    >
                        {["hdbscan", "linear"].map((v) => (
                            <MenuItem key={v} value={v}>
                                {v}
                            </MenuItem>
                        ))}
                    </TextField>
                    <TextField
                        id="minBlur"
                        name="minBlur"
                        label="minBlur"
                        value={values.minBlur}
                        size="small"
                        onChange={handleChange}
                    />
                    <TextField
                        id="minScore"
                        name="minScore"
                        label="minScore"
                        value={values.minScore}
                        size="small"
                        onChange={handleChange}
                    />
                    <TextField
                        id="joinThreshold"
                        name="joinThreshold"
                        label="joinThreshold"
                        value={values.joinThreshold}
                        size="small"
                        onChange={handleChange}
                    />
                    <TextField
                        id="batchSize"
                        name="batchSize"
                        label="batchSize"
                        value={values.batchSize}
                        size="small"
                        onChange={handleChange}
                    />
                </Stack>
                <Box marginInlineStart={"auto"} p={1}>
                    <Button color="secondary" type="submit">
                        Cluster
                    </Button>
                </Box>
                {isSubmitting && <Loader />}
            </Stack>
        </form>
    );
};

interface Header2Props {
    clusterRes: ClusterDebugPageContents | undefined;
}

const Header2: React.FC<Header2Props> = ({ clusterRes }) => {
    return (
        clusterRes && (
            <Stack m={1}>
                <Typography variant="small" mb={1}>
                    {`${clusterRes.clusters.length} clusters from ${clusterRes.clusteredFaceCount} faces in ${(clusterRes.timeTakenMs / 1000).toFixed(0)} seconds. ${clusterRes.unclusteredFaceCount} unclustered faces.`}
                </Typography>
                <Typography variant="small" color="text.muted">
                    Showing only top 30 and bottom 30 clusters.
                </Typography>
                <Typography variant="small" color="text.muted">
                    For each cluster showing only up to 50 faces, sorted by
                    cosine similarity to highest scoring face in the cluster.
                </Typography>
                <Typography variant="small" color="text.muted">
                    Below each face is its{" "}
                    <b>blur - score - cosineSimilarity - direction</b>.
                </Typography>
                <Typography variant="small" color="text.muted">
                    Faces added to the cluster as a result of merging are
                    outlined.
                </Typography>
            </Stack>
        )
    );
};

const Loader = () => (
    <VerticallyCentered mt={4}>
        <EnteSpinner />
    </VerticallyCentered>
);

interface FaceItemProps {
    faceWithFile: FaceWithFile;
}

interface FaceWithFile {
    face: Face;
    enteFile: EnteFile;
    cosineSimilarity?: number;
    wasMerged?: boolean;
}

const FaceItem: React.FC<FaceItemProps> = ({ faceWithFile }) => {
    const { face, enteFile, cosineSimilarity, wasMerged } = faceWithFile;
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

    const fd = faceDirection(face.detection);
    const d = fd == "straight" ? "•" : fd == "left" ? "←" : "→";
    return (
        <FaceChip
            style={{
                outline: wasMerged ? `1px solid gray` : undefined,
                outlineOffset: "2px",
            }}
        >
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
            <Stack direction="row" justifyContent="space-between">
                <Typography variant="small" color="text.muted">
                    {`b${face.blur.toFixed(0)} `}
                </Typography>
                <Typography variant="small" color="text.muted">
                    {`s${face.score.toFixed(1)}`}
                </Typography>
                {cosineSimilarity && (
                    <Typography variant="small" color="text.muted">
                        {`c${cosineSimilarity.toFixed(1)}`}
                    </Typography>
                )}
                <Typography variant="small" color="text.muted">
                    {`d${d}`}
                </Typography>
            </Stack>
        </FaceChip>
    );
};

const FaceChip = styled(Box)`
    width: 120px;
    height: 120px;
`;
