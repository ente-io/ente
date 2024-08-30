import { SelectionBar } from "@/base/components/Navbar";
import { pt } from "@/base/i18n";
import {
    faceCrop,
    type ClusterDebugPageContents,
    type ClusterPreviewFaceWF,
} from "@/new/photos/services/ml";
import { faceDirection } from "@/new/photos/services/ml/face";
import { wait } from "@/utils/promise";
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
import React, { useContext, useEffect, useMemo, useRef, useState } from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import { VariableSizeList } from "react-window";

// TODO-Cluster Temporary component for debugging
export default function ClusterDebug() {
    const { showNavBar } = useContext(AppContext);

    useEffect(() => {
        showNavBar(true);
    }, []);

    return (
        <>
            <Container>
                <AutoSizer>
                    {({ height, width }) => (
                        <ClusterList width={width} height={height} />
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
    border: 1px solid tomato;
    flex: 1;
    width: 100%;
    flex-wrap: wrap;
    overflow: hidden;
    .pswp-thumbnail {
        display: inline-block;
    }
`;

interface ClusterListProps {
    height: number;
    width: number;
}

interface ClusteringOpts {
    method: "linear" | "hdbscan";
    batchSize: number;
    joinThreshold: number;
}

const ClusterList: React.FC<ClusterListProps> = ({ height, width }) => {
    const { startLoading, finishLoading } = useContext(AppContext);

    const [clusterRes, setClusterRes] = useState<
        ClusterDebugPageContents | undefined
    >();
    const [items, setItems] = useState<Item[]>([]);
    const listRef = useRef(null);

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const cluster = async (opts: ClusteringOpts) => {
        startLoading();
        // setClusterRes(await wipClusterDebugPageContents());
        console.log(opts);
        await wait(5000);
        setClusterRes({
            clusteredCount: 1,
            unclusteredCount: 2,
            clusterPreviewWFs: Array(100)
                .fill(0)
                .map(() => ({ clusterSize: 0, faces: [] })),
            clusters: [],
            clusterIDForFaceID: new Map(),
        });
        finishLoading();
    };

    const columns = useMemo(
        () => Math.max(Math.floor(getFractionFittableColumns(width)), 4),
        [width],
    );

    const shrinkRatio = getShrinkRatio(width, columns);
    const listItemHeight = 120 * shrinkRatio + 24 + 4;

    useEffect(() => {
        setItems(clusterRes ? itemsFromClusterRes(clusterRes, columns) : []);
    }, [columns, clusterRes]);

    useEffect(() => {
        listRef.current?.resetAfterIndex(0);
    }, [items]);

    const clusterIDForFaceID = clusterRes?.clusterIDForFaceID;

    const getItemSize = (index: number) =>
        index === 0
            ? 270
            : Array.isArray(items[index - 1])
              ? listItemHeight
              : 36;

    return (
        <VariableSizeList
            height={height}
            width={width}
            ref={listRef}
            itemCount={1 + items.length}
            itemSize={getItemSize}
            overscanCount={3}
        >
            {({ index, style }) => {
                if (index === 0)
                    return (
                        <div style={style}>
                            <Header
                                clusterRes={clusterRes}
                                onCluster={cluster}
                            />
                        </div>
                    );

                const item = items[index - 1];
                return (
                    <ListItem style={style}>
                        <ListContainer
                            columns={columns}
                            shrinkRatio={shrinkRatio}
                        >
                            {!Array.isArray(item) ? (
                                <LabelContainer span={columns}>
                                    {`cluster size ${item.toFixed(2)}`}
                                </LabelContainer>
                            ) : (
                                item.map((faceWF, i) => (
                                    <FaceItem
                                        key={i.toString()}
                                        {...{ faceWF, clusterIDForFaceID }}
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

type Item = number | ClusterPreviewFaceWF[];

const itemsFromClusterRes = (
    clusterRes: ClusterDebugPageContents,
    columns: number,
) => {
    const { clusterPreviewWFs } = clusterRes;

    const result: Item[] = [];
    for (let index = 0; index < clusterPreviewWFs.length; index++) {
        const { clusterSize, faces } = clusterPreviewWFs[index];
        result.push(clusterSize);
        let lastIndex = 0;
        while (lastIndex < faces.length) {
            result.push(faces.slice(lastIndex, lastIndex + columns));
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

interface HeaderProps {
    clusterRes: ClusterDebugPageContents | undefined;
    onCluster: (opts: ClusteringOpts) => Promise<void>;
}

const Header: React.FC<HeaderProps> = ({ clusterRes, onCluster }) => {
    const { values, handleSubmit, handleChange, isSubmitting } =
        useFormik<ClusteringOpts>({
            initialValues: {
                method: "hdbscan",
                joinThreshold: 0.7,
                batchSize: 2500,
            },
            onSubmit: onCluster,
        });

    const form = (
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
            </Stack>
        </form>
    );

    const clusterInfo = clusterRes && (
        <Stack m={1}>
            <Typography variant="small" mb={1}>
                {`${clusterRes.clusters.length} clusters from ${clusterRes.clusteredCount} faces. ${clusterRes.unclusteredCount} unclustered faces.`}
            </Typography>
            <Typography variant="small" color="text.muted">
                Showing only top 30 and bottom 30 clusters.
            </Typography>
            <Typography variant="small" color="text.muted">
                For each cluster showing only up to 50 faces, sorted by cosine
                similarity to highest scoring face in the cluster.
            </Typography>
            <Typography variant="small" color="text.muted">
                Below each face is its{" "}
                <b>blur - score - cosineSimilarity - direction</b>
            </Typography>
        </Stack>
    );

    return (
        <div>
            {form}
            {isSubmitting && <Loader />}
            {clusterInfo}
        </div>
    );
};

const Loader = () => (
    <VerticallyCentered mt={4}>
        <EnteSpinner />
    </VerticallyCentered>
);

interface FaceItemProps {
    faceWF: ClusterPreviewFaceWF;
    clusterIDForFaceID: Map<string, string> | undefined;
}

const FaceItem: React.FC<FaceItemProps> = ({ faceWF, clusterIDForFaceID }) => {
    const { face, enteFile, cosineSimilarity } = faceWF;
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
                outline: outlineForCluster(clusterIDForFaceID?.get(faceID)),
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
                <Typography variant="small" color="text.muted">
                    {`c${cosineSimilarity.toFixed(1)}`}
                </Typography>
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

const outlineForCluster = (clusterID: string | undefined) =>
    clusterID ? `1px solid oklch(0.8 0.2 ${hForID(clusterID)})` : undefined;

const hForID = (id: string) =>
    ([...id].reduce((s, c) => s + c.charCodeAt(0), 0) % 10) * 36;
