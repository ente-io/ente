import { SelectionBar } from "@/base/components/Navbar";
import { pt } from "@/base/i18n";
import {
    faceCrop,
    wipClusterDebugPageContents,
    type ClusterDebugPageContents,
} from "@/new/photos/services/ml";
import {
    type ClusteringOpts,
    type ClusteringProgress,
    type OnClusteringProgress,
} from "@/new/photos/services/ml/cluster";
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
import { useFormik, type FormikProps } from "formik";
import { useRouter } from "next/router";
import { AppContext } from "pages/_app";
import React, {
    memo,
    useContext,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";
import AutoSizer from "react-virtualized-auto-sizer";
import {
    areEqual,
    VariableSizeList,
    type ListChildComponentProps,
} from "react-window";

// TODO-Cluster Temporary component for debugging
export default function ClusterDebug() {
    const { startLoading, finishLoading, showNavBar } = useContext(AppContext);

    const [clusterRes, setClusterRes] = useState<
        ClusterDebugPageContents | undefined
    >();

    const cluster = async (
        opts: ClusteringOpts,
        onProgress: OnClusteringProgress,
    ) => {
        setClusterRes(undefined);
        startLoading();
        setClusterRes(await wipClusterDebugPageContents(opts, onProgress));
        finishLoading();
    };

    useEffect(() => showNavBar(true), []);

    return (
        <>
            <Container>
                <AutoSizer>
                    {({ height, width }) => (
                        <ClusterList {...{ width, height, clusterRes }}>
                            <OptionsForm onCluster={cluster} />
                        </ClusterList>
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

interface OptionsFormProps {
    onCluster: (
        opts: ClusteringOpts,
        onProgress: OnClusteringProgress,
    ) => Promise<void>;
}

const OptionsForm: React.FC<OptionsFormProps> = ({ onCluster }) => {
    const [progress, setProgress] = useState<ClusteringProgress>({
        completed: 0,
        total: 0,
    });

    // Formik converts nums to a string on edit.
    const toFloat = (n: number | string) =>
        typeof n == "string" ? parseFloat(n) : n;

    const formik = useFormik<ClusteringOpts>({
        initialValues: {
            method: "linear",
            minBlur: 10,
            minScore: 0.8,
            minClusterSize: 2,
            joinThreshold: 0.7,
            earlyExitThreshold: 0.2,
            batchSize: 10000,
            lookbackSize: 2500,
        },
        onSubmit: (values) =>
            onCluster(
                {
                    method: values.method,
                    minBlur: toFloat(values.minBlur),
                    minScore: toFloat(values.minScore),
                    minClusterSize: toFloat(values.minClusterSize),
                    joinThreshold: toFloat(values.joinThreshold),
                    earlyExitThreshold: toFloat(values.earlyExitThreshold),
                    batchSize: toFloat(values.batchSize),
                    lookbackSize: toFloat(values.lookbackSize),
                },
                (progress: ClusteringProgress) => setProgress(progress),
            ),
    });

    const Form = memo(
        ({
            values,
            handleSubmit,
            handleChange,
            isSubmitting,
        }: FormikProps<ClusteringOpts>) => (
            <form onSubmit={handleSubmit}>
                <Stack>
                    <Stack
                        direction="row"
                        gap={1}
                        sx={{ ".MuiFormControl-root": { flex: "1" } }}
                    >
                        <TextField
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
                            name="minBlur"
                            label="minBlur"
                            value={values.minBlur}
                            size="small"
                            onChange={handleChange}
                        />
                        <TextField
                            name="minScore"
                            label="minScore"
                            value={values.minScore}
                            size="small"
                            onChange={handleChange}
                        />
                        <TextField
                            name="minClusterSize"
                            label="minClusterSize"
                            value={values.minClusterSize}
                            size="small"
                            onChange={handleChange}
                        />
                    </Stack>
                    <Stack
                        direction="row"
                        gap={1}
                        sx={{ ".MuiFormControl-root": { flex: "1" } }}
                    >
                        <TextField
                            name="joinThreshold"
                            label="joinThreshold"
                            value={values.joinThreshold}
                            size="small"
                            onChange={handleChange}
                        />
                        <TextField
                            name="earlyExitThreshold"
                            label="earlyExitThreshold"
                            value={values.earlyExitThreshold}
                            size="small"
                            onChange={handleChange}
                        />
                        <TextField
                            name="batchSize"
                            label="batchSize"
                            value={values.batchSize}
                            size="small"
                            onChange={handleChange}
                        />
                        <TextField
                            name="lookbackSize"
                            label="lookbackSize"
                            value={values.lookbackSize}
                            size="small"
                            onChange={handleChange}
                        />
                    </Stack>
                    <Box marginInlineStart={"auto"} p={1}>
                        <Button
                            color="secondary"
                            type="submit"
                            disabled={isSubmitting}
                        >
                            Cluster
                        </Button>
                    </Box>
                </Stack>
            </form>
        ),
    );

    return (
        <Stack>
            <Typography paddingInline={1}>Parameters</Typography>
            <Form {...formik} />
            {formik.isSubmitting && <Loader {...progress} />}
        </Stack>
    );
};

const Loader: React.FC<ClusteringProgress> = ({ completed, total }) => (
    <VerticallyCentered mt={4}>
        <EnteSpinner />
        <Typography>{`${completed} / ${total}`}</Typography>
    </VerticallyCentered>
);

type ClusterListProps = ClusterResHeaderProps & {
    height: number;
    width: number;
};

const ClusterList: React.FC<React.PropsWithChildren<ClusterListProps>> = ({
    width,
    height,
    clusterRes,
    children,
}) => {
    const [items, setItems] = useState<Item[]>([]);
    const listRef = useRef(null);

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

    const itemSize = (index: number) =>
        index === 0
            ? 200
            : index === 1
              ? 130
              : Array.isArray(items[index - 2])
                ? listItemHeight
                : 36;

    return (
        <VariableSizeList
            height={height}
            width={width}
            ref={listRef}
            itemData={{ items, clusterRes, columns, shrinkRatio, children }}
            itemCount={2 + items.length}
            itemSize={itemSize}
            overscanCount={3}
        >
            {ClusterListItemRenderer}
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

// It in necessary to define the item renderer otherwise it gets recreated every
// time the parent rerenders, causing the form to lose its submitting state.
const ClusterListItemRenderer = React.memo<ListChildComponentProps>(
    ({ index, style, data }) => {
        const { clusterRes, columns, shrinkRatio, items, children } = data;

        if (index == 0) return <div style={style}>{children}</div>;

        if (index == 1)
            return (
                <div style={style}>
                    <ClusterResHeader clusterRes={clusterRes} />
                </div>
            );

        const item = items[index - 2];
        return (
            <ListItem style={style}>
                <ListContainer columns={columns} shrinkRatio={shrinkRatio}>
                    {!Array.isArray(item) ? (
                        <LabelContainer span={columns}>{item}</LabelContainer>
                    ) : (
                        item.map((f, i) => (
                            <FaceItem key={i.toString()} faceWithFile={f} />
                        ))
                    )}
                </ListContainer>
            </ListItem>
        );
    },
    areEqual,
);

interface ClusterResHeaderProps {
    clusterRes: ClusterDebugPageContents | undefined;
}

const ClusterResHeader: React.FC<ClusterResHeaderProps> = ({ clusterRes }) => {
    if (!clusterRes) return null;

    const {
        totalFaceCount,
        filteredFaceCount,
        clusteredFaceCount,
        unclusteredFaceCount,
        timeTakenMs,
        clusters,
    } = clusterRes;

    return (
        <Stack m={1}>
            <Typography mb={1} variant="small">
                {`${clusters.length} clusters in ${(timeTakenMs / 1000).toFixed(0)} seconds • ${totalFaceCount} faces ${filteredFaceCount} filtered ${clusteredFaceCount} clustered ${unclusteredFaceCount} unclustered`}
            </Typography>
            <Typography variant="small" color="text.muted">
                Showing only top 30 clusters, bottom 30 clusters, and
                unclustered faces.
            </Typography>
            <Typography variant="small" color="text.muted">
                For each cluster showing only up to 50 faces, sorted by cosine
                similarity to highest scoring face in the cluster.
            </Typography>
            <Typography variant="small" color="text.muted">
                Below each face is its{" "}
                <b>blur - score - cosineSimilarity - direction</b>.
            </Typography>
            <Typography variant="small" color="text.muted">
                Faces added to the cluster as a result of next batch merging are
                outlined.
            </Typography>
        </Stack>
    );
};

const ListItem = styled("div")`
    display: flex;
    justify-content: center;
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
