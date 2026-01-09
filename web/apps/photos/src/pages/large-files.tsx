import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import CheckBoxIcon from "@mui/icons-material/CheckBox";
import ImageIcon from "@mui/icons-material/Image";
import RemoveCircleOutlineIcon from "@mui/icons-material/RemoveCircleOutline";
import SortIcon from "@mui/icons-material/Sort";
import VideocamIcon from "@mui/icons-material/Videocam";
import {
    Box,
    Chip,
    IconButton,
    LinearProgress,
    Stack,
    styled,
    Tooltip,
    Typography,
} from "@mui/material";
import { useRedirectIfNeedsCredentials } from "ente-accounts/components/utils/use-redirect";
import { CenteredFill, Overlay } from "ente-base/components/containers";
import { ActivityErrorIndicator } from "ente-base/components/ErrorIndicator";
import { ActivityIndicator } from "ente-base/components/mui/ActivityIndicator";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import {
    OverflowMenu,
    OverflowMenuOption,
} from "ente-base/components/OverflowMenu";
import { useBaseContext } from "ente-base/context";
import log from "ente-base/log";
import { FileViewer } from "ente-gallery/components/viewer/FileViewer";
import { formattedByteSize } from "ente-gallery/utils/units";
import {
    ItemCard,
    LargeFileTileOverlay,
} from "ente-new/photos/components/Tiles";
import {
    computeThumbnailGridLayoutParams,
    type ThumbnailGridLayoutParams,
} from "ente-new/photos/components/utils/thumbnail-grid-layout";
import {
    deleteSelectedLargeFiles,
    findLargeFiles,
    largeFilesInitialState,
    largeFilesReducer,
    type LargeFileFilter,
    type LargeFileItem,
    type SortOrder,
} from "ente-new/photos/services/large-files";
import { t } from "i18next";
import { useRouter } from "next/router";
import React, {
    memo,
    useCallback,
    useEffect,
    useMemo,
    useReducer,
    useState,
} from "react";
import Autosizer from "react-virtualized-auto-sizer";
import {
    areEqual,
    VariableSizeList,
    type ListChildComponentProps,
} from "react-window";

const Page: React.FC = () => {
    const { onGenericError } = useBaseContext();

    const [state, dispatch] = useReducer(
        largeFilesReducer,
        largeFilesInitialState,
    );
    const [openFileViewer, setOpenFileViewer] = useState(false);
    const [currentIndex, setCurrentIndex] = useState(0);

    useRedirectIfNeedsCredentials("/large-files");

    useEffect(() => {
        dispatch({ type: "analyze" });
        void findLargeFiles(state.filter)
            .then((largeFiles) =>
                dispatch({ type: "analysisCompleted", largeFiles }),
            )
            .catch((e: unknown) => {
                log.error("Failed to find large files", e);
                dispatch({ type: "analysisFailed" });
            });
    }, [state.filter]);

    const handleDeleteFiles = useCallback(() => {
        dispatch({ type: "delete" });
        void deleteSelectedLargeFiles(state.largeFiles, (progress: number) =>
            dispatch({ type: "setDeleteProgress", progress }),
        )
            .then((removedIDs) =>
                dispatch({ type: "deleteCompleted", removedIDs }),
            )
            .catch((e: unknown) => {
                onGenericError(e);
                dispatch({ type: "deleteFailed" });
            });
    }, [state.largeFiles, onGenericError]);

    const handleOpenViewer = useCallback((index: number) => {
        setCurrentIndex(index);
        setOpenFileViewer(true);
    }, []);

    const handleCloseViewer = useCallback(() => {
        setOpenFileViewer(false);
    }, []);

    // Extract files for the FileViewer.
    const files = useMemo(
        () => state.largeFiles.map((item) => item.file),
        [state.largeFiles],
    );

    const contents = (() => {
        switch (state.analysisStatus) {
            case undefined:
            case "started":
                return <Loading />;
            case "failed":
                return <LoadFailed />;
            case "completed":
                if (state.largeFiles.length == 0) {
                    return <NoLargeFilesFound />;
                } else {
                    return (
                        <LargeFiles
                            largeFiles={state.largeFiles}
                            onToggleSelection={(index) =>
                                dispatch({ type: "toggleSelection", index })
                            }
                            onOpenViewer={handleOpenViewer}
                            selectedCount={state.selectedCount}
                            selectedSize={state.selectedSize}
                            deleteProgress={state.deleteProgress}
                            onDeleteFiles={handleDeleteFiles}
                        />
                    );
                }
        }
    })();

    return (
        <Stack sx={{ height: "100vh" }}>
            <Navbar
                filter={state.filter}
                onChangeFilter={(filter) =>
                    dispatch({ type: "changeFilter", filter })
                }
                sortOrder={state.sortOrder}
                onChangeSortOrder={(sortOrder) =>
                    dispatch({ type: "changeSortOrder", sortOrder })
                }
                onDeselectAll={() => dispatch({ type: "deselectAll" })}
                onSelectAll={() => dispatch({ type: "selectAll" })}
            />
            {contents}
            <FileViewer
                open={openFileViewer}
                onClose={handleCloseViewer}
                files={files}
                initialIndex={currentIndex}
                onVisualFeedback={() => {
                    // No-op: Large files viewer is read-only
                }}
            />
        </Stack>
    );
};

export default Page;

interface NavbarProps {
    filter: LargeFileFilter;
    onChangeFilter: (filter: LargeFileFilter) => void;
    sortOrder: SortOrder;
    onChangeSortOrder: (sortOrder: SortOrder) => void;
    onDeselectAll: () => void;
    onSelectAll: () => void;
}

const Navbar: React.FC<NavbarProps> = ({
    filter,
    onChangeFilter,
    sortOrder,
    onChangeSortOrder,
    onDeselectAll,
    onSelectAll,
}) => {
    const router = useRouter();

    const handleToggleSortOrder = () => {
        onChangeSortOrder(sortOrder === "desc" ? "asc" : "desc");
    };

    const sortTooltip =
        sortOrder === "desc"
            ? t("sort_largest_first")
            : t("sort_smallest_first");

    return (
        <Stack
            sx={(theme) => ({
                borderBottom: `1px solid ${theme.vars.palette.divider}`,
            })}
        >
            <Stack
                direction="row"
                sx={{
                    alignItems: "center",
                    justifyContent: "space-between",
                    padding: "8px 4px",
                }}
            >
                <Box sx={{ minWidth: "100px" }}>
                    <IconButton onClick={router.back}>
                        <ArrowBackIcon />
                    </IconButton>
                </Box>
                <Typography variant="h6">{t("large_files_title")}</Typography>
                <Stack
                    direction="row"
                    sx={{
                        gap: "4px",
                        minWidth: "100px",
                        justifyContent: "flex-end",
                    }}
                >
                    <Tooltip title={sortTooltip}>
                        <IconButton onClick={handleToggleSortOrder}>
                            <SortIcon
                                sx={{
                                    transform:
                                        sortOrder === "asc"
                                            ? "scaleY(-1)"
                                            : "none",
                                }}
                            />
                        </IconButton>
                    </Tooltip>
                    <OptionsMenu {...{ onDeselectAll, onSelectAll }} />
                </Stack>
            </Stack>
            <FilterChips {...{ filter, onChangeFilter }} />
        </Stack>
    );
};

interface FilterChipsProps {
    filter: LargeFileFilter;
    onChangeFilter: (filter: LargeFileFilter) => void;
}

const FilterChips: React.FC<FilterChipsProps> = ({
    filter,
    onChangeFilter,
}) => (
    <Stack direction="row" sx={{ gap: 1, px: 3, pb: 1.5, flexWrap: "wrap" }}>
        <Chip
            label={t("all")}
            variant={filter === "all" ? "filled" : "outlined"}
            color={filter === "all" ? "primary" : "default"}
            onClick={() => onChangeFilter("all")}
        />
        <Chip
            icon={<ImageIcon sx={{ fontSize: "18px !important" }} />}
            label={t("photos")}
            variant={filter === "photos" ? "filled" : "outlined"}
            color={filter === "photos" ? "primary" : "default"}
            onClick={() => onChangeFilter("photos")}
            sx={{ px: 1 }}
        />
        <Chip
            icon={<VideocamIcon sx={{ fontSize: "18px !important" }} />}
            label={t("videos")}
            variant={filter === "videos" ? "filled" : "outlined"}
            color={filter === "videos" ? "primary" : "default"}
            onClick={() => onChangeFilter("videos")}
            sx={{ px: 1 }}
        />
    </Stack>
);

interface OptionsMenuProps {
    onDeselectAll: () => void;
    onSelectAll: () => void;
}

const OptionsMenu: React.FC<OptionsMenuProps> = ({
    onDeselectAll,
    onSelectAll,
}) => (
    <OverflowMenu ariaID="large-files-options">
        <OverflowMenuOption startIcon={<CheckBoxIcon />} onClick={onSelectAll}>
            {t("select_all")}
        </OverflowMenuOption>
        <OverflowMenuOption
            startIcon={<RemoveCircleOutlineIcon />}
            onClick={onDeselectAll}
        >
            {t("deselect_all")}
        </OverflowMenuOption>
    </OverflowMenu>
);

const Loading: React.FC = () => (
    <CenteredFill>
        <ActivityIndicator />
    </CenteredFill>
);

const LoadFailed: React.FC = () => (
    <CenteredFill>
        <ActivityErrorIndicator />
    </CenteredFill>
);

const NoLargeFilesFound: React.FC = () => (
    <CenteredFill>
        <Typography color="text.muted" sx={{ textAlign: "center" }}>
            {t("no_large_files")}
        </Typography>
    </CenteredFill>
);

interface LargeFilesProps {
    largeFiles: LargeFileItem[];
    onToggleSelection: (index: number) => void;
    onOpenViewer: (index: number) => void;
    selectedCount: number;
    selectedSize: number;
    deleteProgress: number | undefined;
    onDeleteFiles: () => void;
}

const LargeFiles: React.FC<LargeFilesProps> = ({
    largeFiles,
    onToggleSelection,
    onOpenViewer,
    selectedCount,
    selectedSize,
    deleteProgress,
    onDeleteFiles,
}) => (
    <Stack sx={{ flex: 1 }}>
        <Box sx={{ flex: 1, overflow: "hidden", paddingBlockEnd: 1 }}>
            <Autosizer>
                {({ width, height }) => (
                    <LargeFilesGrid
                        {...{
                            width,
                            height,
                            largeFiles,
                            onToggleSelection,
                            onOpenViewer,
                        }}
                    />
                )}
            </Autosizer>
        </Box>
        <Stack sx={{ margin: 1 }}>
            <DeleteButton
                {...{
                    selectedCount,
                    selectedSize,
                    deleteProgress,
                    onDeleteFiles,
                }}
            />
        </Stack>
    </Stack>
);

interface LargeFilesGridProps {
    width: number;
    height: number;
    largeFiles: LargeFileItem[];
    onToggleSelection: (index: number) => void;
    onOpenViewer: (index: number) => void;
}

interface LargeFilesGridItemData {
    largeFiles: LargeFileItem[];
    onToggleSelection: (index: number) => void;
    onOpenViewer: (index: number) => void;
    layoutParams: ThumbnailGridLayoutParams;
}

const LargeFilesGrid: React.FC<LargeFilesGridProps> = ({
    width,
    height,
    largeFiles,
    onToggleSelection,
    onOpenViewer,
}) => {
    const layoutParams = useMemo(
        () => computeThumbnailGridLayoutParams(width),
        [width],
    );

    const columns = layoutParams.columns;
    const rowCount = Math.ceil(largeFiles.length / columns);

    const itemData: LargeFilesGridItemData = {
        largeFiles,
        onToggleSelection,
        onOpenViewer,
        layoutParams,
    };

    const itemSize = () => layoutParams.itemHeight + layoutParams.gap;

    const itemKey = (index: number) => `row-${index}`;

    // Key based on width to force re-render when layout changes
    const key = `${width}`;

    return (
        <VariableSizeList
            key={key}
            style={
                {
                    "--et-padding-inline": `${layoutParams.paddingInline}px`,
                } as React.CSSProperties
            }
            {...{
                height,
                width,
                itemData,
                itemCount: rowCount,
                itemSize,
                itemKey,
            }}
        >
            {GridRow}
        </VariableSizeList>
    );
};

const GridRow: React.FC<ListChildComponentProps<LargeFilesGridItemData>> = memo(
    ({ index: rowIndex, style, data }) => {
        const { largeFiles, onToggleSelection, onOpenViewer, layoutParams } =
            data;
        const columns = layoutParams.columns;

        // Calculate which items are in this row
        const startIndex = rowIndex * columns;
        const endIndex = Math.min(startIndex + columns, largeFiles.length);
        const rowItems = largeFiles.slice(startIndex, endIndex);

        return (
            <ItemGrid layoutParams={layoutParams} style={style}>
                {rowItems.map((item, colIndex) => {
                    const itemIndex = startIndex + colIndex;
                    return (
                        <GridItem
                            key={item.id}
                            item={item}
                            onToggle={() => onToggleSelection(itemIndex)}
                            onOpen={() => onOpenViewer(itemIndex)}
                        />
                    );
                })}
            </ItemGrid>
        );
    },
    areEqual,
);

interface GridItemProps {
    item: LargeFileItem;
    onToggle: () => void;
    onOpen: () => void;
}

const GridItem: React.FC<GridItemProps> = memo(({ item, onToggle, onOpen }) => {
    const checked = item.isSelected;

    const handleCheckboxChange: React.ChangeEventHandler<HTMLInputElement> = (
        e,
    ) => {
        e.stopPropagation();
        onToggle();
    };

    return (
        <TileContainer onClick={onOpen}>
            <ItemCard TileComponent={LargeFileTile} coverFile={item.file}>
                <LargeFileTileOverlay>
                    <SizeLabel>{formattedByteSize(item.size)}</SizeLabel>
                </LargeFileTileOverlay>
            </ItemCard>
            <Check
                type="checkbox"
                checked={checked}
                onChange={handleCheckboxChange}
                onClick={(e) => e.stopPropagation()}
            />
            {checked && <SelectedOverlay />}
            <HoverOverlay className="hover-overlay" $checked={checked} />
        </TileContainer>
    );
});

interface DeleteButtonProps {
    selectedCount: number;
    selectedSize: number;
    deleteProgress: number | undefined;
    onDeleteFiles: () => void;
}

const DeleteButton: React.FC<DeleteButtonProps> = ({
    selectedCount,
    selectedSize,
    deleteProgress,
    onDeleteFiles,
}) => (
    <FocusVisibleButton
        sx={{ minWidth: "min(100%, 320px)", margin: "auto" }}
        disabled={selectedCount == 0 || deleteProgress !== undefined}
        color="critical"
        onClick={onDeleteFiles}
    >
        <Stack
            sx={{
                gap: 1,
                minHeight: "45px",
                justifyContent: "center",
                flex: 1,
            }}
        >
            {deleteProgress !== undefined ? (
                <LinearProgress
                    sx={{ borderRadius: "4px" }}
                    variant={
                        deleteProgress === 0 ? "indeterminate" : "determinate"
                    }
                    value={deleteProgress}
                    color="inherit"
                />
            ) : (
                <>
                    <Typography>
                        {t("delete_files_button", { count: selectedCount })}
                    </Typography>
                    <Typography variant="small" fontWeight="regular">
                        {formattedByteSize(selectedSize)}
                    </Typography>
                </>
            )}
        </Stack>
    </FocusVisibleButton>
);

// --- Styled Components ---

interface ItemGridProps {
    layoutParams: ThumbnailGridLayoutParams;
    style?: React.CSSProperties;
}

const ItemGrid = styled("div", {
    shouldForwardProp: (prop) => prop !== "layoutParams",
})<ItemGridProps>(
    ({ layoutParams }) => `
    display: grid;
    padding-inline: ${layoutParams.paddingInline}px;
    grid-template-columns: repeat(${layoutParams.columns}, ${layoutParams.itemWidth}px);
    grid-auto-rows: ${layoutParams.itemHeight}px;
    gap: ${layoutParams.gap}px;
`,
);

const TileContainer = styled("div")`
    position: relative;
    cursor: pointer;
    border-radius: 4px;
    overflow: hidden;
    width: 100%;
    height: 100%;
    user-select: none;

    @media (pointer: fine) {
        &:hover {
            input[type="checkbox"] {
                visibility: visible;
                opacity: 0.5;
            }

            .hover-overlay {
                opacity: 1;
            }
        }
    }
`;

const LargeFileTile = styled("div")`
    display: flex;
    position: relative;
    border-radius: 4px;
    overflow: hidden;
    width: 100%;
    height: 100%;
    & > img {
        object-fit: cover;
        width: 100%;
        height: 100%;
        pointer-events: none;
    }
`;

const SizeLabel = styled(Typography)`
    position: absolute;
    bottom: 4px;
    left: 4px;
    background-color: rgba(0, 0, 0, 0.6);
    color: white;
    padding: 2px 4px;
    border-radius: 4px;
    font-size: 0.65rem;
`;

const Check = styled("input")(
    ({ theme }) => `
    appearance: none;
    -webkit-appearance: none;
    -moz-appearance: none;
    position: absolute;
    z-index: 10;
    top: 0;
    left: 0;
    outline: none;
    cursor: pointer;
    width: 31px;
    height: 31px;
    box-sizing: border-box;

    @media (pointer: coarse) {
        pointer-events: none;
    }

    &::before {
        content: "";
        display: block; /* Critical for Safari */
        width: 19px;
        height: 19px;
        background-color: #ddd;
        border-radius: 50%;
        margin: 6px;
        transition: background-color 0.3s ease, opacity 0.3s ease;
        position: relative; /* Important for Safari */
    }

    &::after {
        content: "";
        display: block; /* Critical for Safari */
        position: absolute;
        top: 50%;
        left: 50%;
        width: 5px;
        height: 11px;
        border: solid #333;
        border-width: 0 2px 2px 0;
        transform: translate(-50%, -60%) rotate(45deg);
        transition: border-color 0.3s ease, opacity 0.3s ease;
        transform-origin: center;
    }

    /* Default state - hidden */
    visibility: hidden;

    /* Hover state - show with reduced opacity */
    &:hover {
        visibility: visible;
        opacity: 0.7;
    }

    /* Checked state - fully visible and colored */
    &:checked {
        visibility: visible;
        opacity: 1 !important;
    }

    &:checked::before {
        background-color: ${theme.vars.palette.accent.main};
    }

    &:checked::after {
        border-color: #ddd;
    }
`,
);

const SelectedOverlay = styled(Overlay)(
    ({ theme }) => `
    border: 2px solid ${theme.vars.palette.accent.main};
    border-radius: 4px;
    pointer-events: none;
`,
);

const HoverOverlay = styled("div")<{ $checked: boolean }>`
    opacity: 0;
    left: 0;
    top: 0;
    outline: none;
    height: 40%;
    width: 100%;
    position: absolute;
    pointer-events: none;
    ${(props) =>
        !props.$checked &&
        "background: linear-gradient(rgba(0, 0, 0, 0.2), rgba(0, 0, 0, 0));"}
`;
