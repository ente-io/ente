import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import DoneIcon from "@mui/icons-material/Done";
import RemoveCircleOutlineIcon from "@mui/icons-material/RemoveCircleOutline";
import SortIcon from "@mui/icons-material/Sort";
import {
    Box,
    Checkbox,
    Divider,
    IconButton,
    LinearProgress,
    Stack,
    styled,
    Tab,
    Tabs,
    Tooltip,
    Typography,
} from "@mui/material";
import { useRedirectIfNeedsCredentials } from "ente-accounts/components/utils/use-redirect";
import { CenteredFill, SpacedRow } from "ente-base/components/containers";
import { ActivityErrorIndicator } from "ente-base/components/ErrorIndicator";
import { ActivityIndicator } from "ente-base/components/mui/ActivityIndicator";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import {
    OverflowMenu,
    OverflowMenuOption,
} from "ente-base/components/OverflowMenu";
import { Ellipsized2LineTypography } from "ente-base/components/Typography";
import { useBaseContext } from "ente-base/context";
import log from "ente-base/log";
import { formattedByteSize } from "ente-gallery/utils/units";
import { t } from "i18next";
import { useRouter } from "next/router";
import React, {
    memo,
    useCallback,
    useEffect,
    useMemo,
    useReducer,
} from "react";
import Autosizer from "react-virtualized-auto-sizer";
import {
    areEqual,
    VariableSizeList,
    type ListChildComponentProps,
} from "react-window";
import {
    DuplicateItemTile,
    ItemCard,
    TileBottomTextOverlay,
} from "../components/Tiles";
import {
    computeThumbnailGridLayoutParams,
    type ThumbnailGridLayoutParams,
} from "../components/utils/thumbnail-grid-layout";
import {
    filterGroupsByCategory,
    getSimilarImages,
} from "../services/similar-images";
import {
    CATEGORY_THRESHOLD_RELATED,
} from "../services/similar-images-types";
import {
    calculateDeletedFileCount,
    calculateFreedSpace,
    removeSelectedSimilarImageGroups,
} from "../services/similar-images-delete";
import type { SimilarImageGroup } from "../services/similar-images-types";

const Page: React.FC = () => {
    const { onGenericError } = useBaseContext();

    const [state, dispatch] = useReducer(
        similarImagesReducer,
        initialSimilarImagesState,
    );

    useRedirectIfNeedsCredentials("/similar-images");

    const analyze = useCallback(() => {
        dispatch({ type: "analyze" });
        void getSimilarImages({
            distanceThreshold: CATEGORY_THRESHOLD_RELATED, // Max threshold, filter client-side by category
            onProgress: (progress) =>
                dispatch({ type: "setAnalysisProgress", progress }),
        })
            .then(({ groups }) =>
                dispatch({
                    type: "analysisCompleted",
                    groups,
                }),
            )
            .catch((e: unknown) => {
                log.error("Failed to detect similar images", e);
                dispatch({ type: "analysisFailed" });
            });
    }, []);

    useEffect(() => {
        analyze();
    }, [analyze]);

    const filteredGroups = useMemo(
        () =>
            filterGroupsByCategory(
                state.allSimilarImageGroups,
                state.categoryFilter,
            ),
        [state.allSimilarImageGroups, state.categoryFilter],
    );

    const handleRemoveSimilarImages = useCallback(() => {
        dispatch({ type: "remove" });
        void removeSelectedSimilarImageGroups(
            filteredGroups,
            (progress: number) =>
                dispatch({ type: "setRemoveProgress", progress }),
        )
            .then(({ deletedFileIDs, fullyRemovedGroupIDs }) =>
                dispatch({
                    type: "removeCompleted",
                    deletedFileIDs,
                    fullyRemovedGroupIDs,
                }),
            )
            .catch((e: unknown) => {
                onGenericError(e);
                dispatch({ type: "removeFailed" });
            });
    }, [filteredGroups, onGenericError]);

    const contents = (() => {
        switch (state.analysisStatus) {
            case undefined:
            case "started":
                return <Loading />;
            case "failed":
                return <LoadFailed />;
            case "completed":
                if (filteredGroups.length === 0) {
                    return (
                        <NoSimilarImagesFound
                            categoryFilter={state.categoryFilter}
                            hasAnyGroups={
                                state.allSimilarImageGroups.length > 0
                            }
                        />
                    );
                } else {
                    return (
                        <SimilarImages
                            similarImageGroups={filteredGroups}
                            sortOrder={state.sortOrder}
                            categoryFilter={state.categoryFilter}
                            onCategoryFilterChange={(filter) =>
                                dispatch({
                                    type: "changeCategoryFilter",
                                    categoryFilter: filter,
                                })
                            }
                            onToggleSelection={(index) =>
                                dispatch({ type: "toggleSelection", index })
                            }
                            onToggleItemSelection={(groupIndex, itemIndex) =>
                                dispatch({
                                    type: "toggleItemSelection",
                                    groupIndex,
                                    itemIndex,
                                })
                            }
                            deletableCount={state.deletableCount}
                            deletableSize={state.deletableSize}
                            removeProgress={state.removeProgress}
                            onRemoveSimilarImages={handleRemoveSimilarImages}
                        />
                    );
                }
        }
    })();

    return (
        <Stack sx={{ height: "100vh" }}>
            <Navbar
                sortOrder={state.sortOrder}
                onChangeSortOrder={(sortOrder) =>
                    dispatch({ type: "changeSortOrder", sortOrder })
                }
                onDeselectAll={() => dispatch({ type: "deselectAll" })}
            />
            {contents}
        </Stack>
    );
};

export default Page;

type SortOrder = "size" | "count" | "distance";
type CategoryFilter = "close" | "similar" | "related";

interface SimilarImagesState {
    /** Status of the analysis ("loading") process. */
    analysisStatus: undefined | "started" | "failed" | "completed";
    /** Progress of the analysis (0-100). */
    analysisProgress: number;
    /** All groups of similar images (unfiltered). */
    allSimilarImageGroups: SimilarImageGroup[];
    /** The attribute to use for sorting. */
    sortOrder: SortOrder;
    /** Category filter (close/similar/related). */
    categoryFilter: CategoryFilter;
    /** The number of files that will be deleted. */
    deletableCount: number;
    /** The size (in bytes) that can be freed. */
    deletableSize: number;
    /** If a remove is in progress, then this will indicate its progress percentage. */
    removeProgress: number | undefined;
}

type SimilarImagesAction =
    | { type: "analyze" }
    | { type: "setAnalysisProgress"; progress: number }
    | { type: "analysisFailed" }
    | {
        type: "analysisCompleted";
        groups: SimilarImageGroup[];
    }
    | { type: "changeSortOrder"; sortOrder: SortOrder }
    | { type: "changeCategoryFilter"; categoryFilter: CategoryFilter }
    | { type: "toggleSelection"; index: number }
    | { type: "toggleItemSelection"; groupIndex: number; itemIndex: number }
    | { type: "toggleSelectAll" }
    | { type: "deselectAll" }
    | { type: "remove" }
    | { type: "setRemoveProgress"; progress: number }
    | { type: "removeFailed" }
    | {
        type: "removeCompleted";
        deletedFileIDs: Set<number>;
        fullyRemovedGroupIDs: Set<string>;
    };

const initialSimilarImagesState: SimilarImagesState = {
    analysisStatus: undefined,
    analysisProgress: 0,
    allSimilarImageGroups: [],
    sortOrder: "size",
    categoryFilter: "close",
    deletableCount: 0,
    deletableSize: 0,
    removeProgress: undefined,
};



const similarImagesReducer: React.Reducer<
    SimilarImagesState,
    SimilarImagesAction
> = (state, action) => {
    switch (action.type) {
        case "analyze":
            return { ...state, analysisStatus: "started", analysisProgress: 0 };

        case "setAnalysisProgress":
            return { ...state, analysisProgress: action.progress };

        case "analysisFailed":
            return { ...state, analysisStatus: "failed", analysisProgress: 0 };

        case "analysisCompleted": {
            const allSimilarImageGroups = sortedCopyOfSimilarImageGroups(
                action.groups,
                state.sortOrder,
            ).map((group) => {
                const items = group.items.map((item, index) => ({
                    ...item,
                    // Select all except the first one by default
                    isSelected: index > 0,
                }));
                return {
                    ...group,
                    items,
                    // Group is selected if all deletable items (index > 0) are selected
                    isSelected:
                        items.length > 1 &&
                        items.slice(1).every((i) => i.isSelected),
                };
            });
            const filteredGroups = filterGroupsByCategory(
                allSimilarImageGroups,
                state.categoryFilter,
            );
            const { deletableCount, deletableSize } =
                calculateDeletableStats(filteredGroups);
            return {
                ...state,
                analysisStatus: "completed",
                allSimilarImageGroups,
                deletableCount,
                deletableSize,
                analysisProgress: 100,
            };
        }

        case "changeSortOrder": {
            const sortOrder = action.sortOrder;
            const allSimilarImageGroups = sortedCopyOfSimilarImageGroups(
                state.allSimilarImageGroups,
                sortOrder,
            );
            return { ...state, sortOrder, allSimilarImageGroups };
        }

        case "changeCategoryFilter": {
            const categoryFilter = action.categoryFilter;
            const filteredGroups = filterGroupsByCategory(
                state.allSimilarImageGroups,
                categoryFilter,
            );
            const { deletableCount, deletableSize } =
                calculateDeletableStats(filteredGroups);
            return { ...state, categoryFilter, deletableCount, deletableSize };
        }

        case "toggleSelection": {
            const allSimilarImageGroups = [...state.allSimilarImageGroups];
            const filteredGroups = filterGroupsByCategory(
                allSimilarImageGroups,
                state.categoryFilter,
            );
            const group = filteredGroups[action.index]!;

            // Toggle group state
            const newIsSelected = !group.isSelected;
            group.isSelected = newIsSelected;

            // Update items: if selecting group, select all items EXCEPT first
            // if deselecting group, deselect all items
            // (Unless we want "select all" to include first? Standard dedup behavior is keep 1)
            group.items = group.items.map((item, idx) => ({
                ...item,
                isSelected: idx === 0 ? false : newIsSelected,
            }));

            const { deletableCount, deletableSize } =
                calculateDeletableStats(filteredGroups);
            return {
                ...state,
                allSimilarImageGroups,
                deletableCount,
                deletableSize,
            };
        }

        case "toggleItemSelection": {
            // Prevent toggling the first item (best photo)
            if (action.itemIndex === 0) {
                return state;
            }

            const allSimilarImageGroups = [...state.allSimilarImageGroups];
            const filteredGroups = filterGroupsByCategory(
                allSimilarImageGroups,
                state.categoryFilter,
            );
            const group = { ...filteredGroups[action.groupIndex]! }; // Shallow copy group
            const items = [...group.items]; // Shallow copy items array
            const item = { ...items[action.itemIndex]! }; // Shallow copy item

            // Toggle item (on the copy)
            item.isSelected = !item.isSelected;
            items[action.itemIndex] = item; // Update items array with new item
            group.items = items; // Update group with new items array

            // Update the group in the allSimilarImageGroups array
            // Optimization: filteredGroups is derived, but we need to update the source
            // Since we don't know the index in allSimilarImageGroups easily without searching,
            // we can fallback to mapping. Or since we know filteredGroups is a subset,
            // we can find the group by ID.
            const updatedAllGroups = allSimilarImageGroups.map(g =>
                g.id === group.id ? group : g
            );

            // Update group selection state (checked if all deletable items are selected)
            // We ignore the first item for "group selected" definition typically
            const deletableItems = items.slice(1);
            group.isSelected =
                deletableItems.length > 0 &&
                deletableItems.every((i) => i.isSelected);

            // Recompute filtered groups from updatedAllGroups to get accurate stats
            const updatedFilteredGroups = filterGroupsByCategory(
                updatedAllGroups,
                state.categoryFilter,
            );
            const { deletableCount, deletableSize } =
                calculateDeletableStats(updatedFilteredGroups);
            return {
                ...state,
                allSimilarImageGroups: updatedAllGroups,
                deletableCount,
                deletableSize,
            };
        }

        case "toggleSelectAll": {
            const allSimilarImageGroups = [...state.allSimilarImageGroups];
            const filteredGroups = filterGroupsByCategory(
                allSimilarImageGroups,
                state.categoryFilter,
            );

            // Check if all filtered groups are currently selected
            const areAllSelected =
                filteredGroups.length > 0 &&
                filteredGroups.every((g) => g.isSelected);

            // Toggle state
            const targetState = !areAllSelected;

            filteredGroups.forEach((group) => {
                group.isSelected = targetState;
                group.items = group.items.map((item, idx) => ({
                    ...item,
                    // If selecting: select all except first. If deselecting: deselect all.
                    isSelected: targetState ? idx > 0 : false,
                }));
            });

            const { deletableCount, deletableSize } =
                calculateDeletableStats(filteredGroups);

            return {
                ...state,
                allSimilarImageGroups,
                deletableCount,
                deletableSize,
            };
        }

        case "deselectAll": {
            const allSimilarImageGroups = state.allSimilarImageGroups.map(
                (group) => ({
                    ...group,
                    isSelected: false,
                    items: group.items.map((item) => ({
                        ...item,
                        isSelected: false,
                    })),
                }),
            );
            const filteredGroups = filterGroupsByCategory(
                allSimilarImageGroups,
                state.categoryFilter,
            );
            const { deletableCount, deletableSize } =
                calculateDeletableStats(filteredGroups);
            return {
                ...state,
                allSimilarImageGroups,
                deletableCount,
                deletableSize,
            };
        }

        case "remove":
            return { ...state, removeProgress: 0 };

        case "setRemoveProgress":
            return { ...state, removeProgress: action.progress };

        case "removeFailed":
            return { ...state, removeProgress: undefined };

        case "removeCompleted": {
            // Filter out fully removed groups and remove deleted files from remaining groups
            const allSimilarImageGroups = state.allSimilarImageGroups
                .filter(({ id }) => !action.fullyRemovedGroupIDs.has(id))
                .map((group) => ({
                    ...group,
                    isSelected: false,
                    items: group.items
                        .filter(
                            (item) => !action.deletedFileIDs.has(item.file.id),
                        )
                        .map((item) => ({ ...item, isSelected: false })),
                }))
                .filter((group) => group.items.length > 1); // Remove groups with only 1 item left
            const filteredGroups = filterGroupsByCategory(
                allSimilarImageGroups,
                state.categoryFilter,
            );
            const { deletableCount, deletableSize } =
                calculateDeletableStats(filteredGroups);
            return {
                ...state,
                allSimilarImageGroups,
                deletableCount,
                deletableSize,
                removeProgress: undefined,
            };
        }
    }
};

const sortedCopyOfSimilarImageGroups = (
    groups: SimilarImageGroup[],
    sortOrder: SortOrder,
) =>
    [...groups].sort((a, b) => {
        switch (sortOrder) {
            case "size":
                return b.totalSize - a.totalSize;
            case "count":
                return b.items.length - a.items.length;
            case "distance":
                return a.furthestDistance - b.furthestDistance;
        }
    });

const calculateDeletableStats = (groups: SimilarImageGroup[]) => {
    return {
        deletableCount: calculateDeletedFileCount(groups),
        deletableSize: calculateFreedSpace(groups),
    };
};

interface NavbarProps {
    sortOrder: SortOrder;
    onChangeSortOrder: (sortOrder: SortOrder) => void;
    onDeselectAll: () => void;
}

const Navbar: React.FC<NavbarProps> = ({
    sortOrder,
    onChangeSortOrder,
    onDeselectAll,
}) => {
    const router = useRouter();

    return (
        <Stack
            direction="row"
            sx={(theme) => ({
                alignItems: "center",
                justifyContent: "space-between",
                padding: "8px 4px",
                borderBottom: `1px solid ${theme.vars.palette.divider}`,
            })}
        >
            <Box sx={{ minWidth: "100px" /* 2 icons + gap */ }}>
                <IconButton onClick={router.back}>
                    <ArrowBackIcon />
                </IconButton>
            </Box>
            <Typography variant="h6">{t("similar_images")}</Typography>
            <Stack direction="row" sx={{ gap: "4px" }}>
                <SortMenu {...{ sortOrder, onChangeSortOrder }} />
                <OptionsMenu {...{ onDeselectAll }} />
            </Stack>
        </Stack>
    );
};

type SortMenuProps = Pick<NavbarProps, "sortOrder" | "onChangeSortOrder">;

const SortMenu: React.FC<SortMenuProps> = ({
    sortOrder,
    onChangeSortOrder,
}) => (
    <OverflowMenu
        ariaID="similar-images-sort"
        triggerButtonIcon={
            <Tooltip title={t("sort_by")}>
                <SortIcon />
            </Tooltip>
        }
    >
        <OverflowMenuOption
            endIcon={sortOrder == "size" ? <DoneIcon /> : undefined}
            onClick={() => onChangeSortOrder("size")}
        >
            {t("total_size")}
        </OverflowMenuOption>
        <OverflowMenuOption
            endIcon={sortOrder == "count" ? <DoneIcon /> : undefined}
            onClick={() => onChangeSortOrder("count")}
        >
            {t("count")}
        </OverflowMenuOption>
        <OverflowMenuOption
            endIcon={sortOrder == "distance" ? <DoneIcon /> : undefined}
            onClick={() => onChangeSortOrder("distance")}
        >
            {t("similarity")}
        </OverflowMenuOption>
    </OverflowMenu>
);

type OptionsMenuProps = Pick<NavbarProps, "onDeselectAll">;

const OptionsMenu: React.FC<OptionsMenuProps> = ({ onDeselectAll }) => (
    <OverflowMenu ariaID="similar-images-options">
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

interface NoSimilarImagesFoundProps {
    categoryFilter: CategoryFilter;
    hasAnyGroups: boolean;
}

const NoSimilarImagesFound: React.FC<NoSimilarImagesFoundProps> = ({
    categoryFilter,
    hasAnyGroups,
}) => {
    // If there are no groups at all, show generic message
    if (!hasAnyGroups) {
        return (
            <CenteredFill>
                <Typography color="text.secondary" sx={{ textAlign: "center" }}>
                    {t("no_similar_images_found")}
                </Typography>
            </CenteredFill>
        );
    }

    // If there are groups but none in this category, show category-specific message
    const categoryDisplayName =
        categoryFilter === "close" ? "close" : categoryFilter;

    return (
        <CenteredFill>
            <Typography color="text.secondary" sx={{ textAlign: "center" }}>
                {t("no_category_images_found", { category: categoryDisplayName })}
            </Typography>
            <Typography
                color="text.secondary"
                variant="small"
                sx={{ textAlign: "center", mt: 1 }}
            >
                {t("try_checking_other_categories")}
            </Typography>
        </CenteredFill>
    );
};

interface SimilarImagesProps {
    similarImageGroups: SimilarImageGroup[];
    sortOrder: SortOrder;
    categoryFilter: CategoryFilter;
    onCategoryFilterChange: (filter: CategoryFilter) => void;
    onToggleSelection: (index: number) => void;
    onToggleItemSelection: (groupIndex: number, itemIndex: number) => void;
    deletableCount: number;
    deletableSize: number;
    removeProgress: number | undefined;
    onRemoveSimilarImages: () => void;
}

const SimilarImages: React.FC<SimilarImagesProps> = ({
    similarImageGroups,
    categoryFilter,
    onCategoryFilterChange,
    onToggleSelection,
    onToggleItemSelection,
    deletableCount,
    deletableSize,
    removeProgress,
    onRemoveSimilarImages,
}) => {
    const isDeletionInProgress = removeProgress !== undefined;

    return (
        <Stack sx={{ flex: 1 }}>
            <CategoryTabs
                categoryFilter={categoryFilter}
                onCategoryFilterChange={onCategoryFilterChange}
            />
            <Box sx={{ flex: 1, overflow: "hidden", paddingBlockEnd: 1 }}>
                <Autosizer>
                    {({ width, height }) => (
                        <SimilarImagesList
                            {...{
                                width,
                                height,
                                similarImageGroups,
                                onToggleSelection,
                                onToggleItemSelection,
                                categoryFilter,
                            }}
                        />
                    )}
                </Autosizer>
            </Box>
            <Stack sx={{ margin: 1 }}>
                <RemoveButton
                    disabled={deletableCount === 0 || isDeletionInProgress}
                    deletableCount={deletableCount}
                    deletableSize={deletableSize}
                    progress={removeProgress}
                    onRemove={onRemoveSimilarImages}
                />
            </Stack>
        </Stack>
    );
};

interface CategoryTabsProps {
    categoryFilter: CategoryFilter;
    onCategoryFilterChange: (filter: CategoryFilter) => void;
}

const CategoryTabs: React.FC<CategoryTabsProps> = ({
    categoryFilter,
    onCategoryFilterChange,
}) => (
    <Box sx={{ borderBottom: 1, borderColor: "divider" }}>
        <Tabs
            value={categoryFilter}
            onChange={(_, newValue) =>
                onCategoryFilterChange(newValue as CategoryFilter)
            }
            centered
        >
            <Tab label={t("close_by")} value="close" />
            <Tab label={t("similar")} value="similar" />
            <Tab label={t("related")} value="related" />
        </Tabs>
    </Box>
);

interface SimilarImagesListProps {
    width: number;
    height: number;
    similarImageGroups: SimilarImageGroup[];
    onToggleSelection: (index: number) => void;
    onToggleItemSelection: (groupIndex: number, itemIndex: number) => void;
    categoryFilter: CategoryFilter;
}

const SimilarImagesList: React.FC<SimilarImagesListProps> = ({
    width,
    height,
    similarImageGroups,
    onToggleSelection,
    onToggleItemSelection,
    categoryFilter,
}) => {
    const layoutParams = useMemo(
        () => computeThumbnailGridLayoutParams(width),
        [width],
    );

    const [expandedGroups, setExpandedGroups] = React.useState<Set<string>>(
        new Set(),
    );

    const toggleExpanded = useCallback((groupId: string) => {
        setExpandedGroups((prev) => {
            const next = new Set(prev);
            if (next.has(groupId)) {
                next.delete(groupId);
            } else {
                next.add(groupId);
            }
            return next;
        });
    }, []);

    const itemData = useMemo(
        () => ({
            layoutParams,
            similarImageGroups,
            onToggleSelection,
            onToggleItemSelection,
            expandedGroups,
            toggleExpanded,
        }),
        [
            layoutParams,
            similarImageGroups,
            onToggleSelection,
            onToggleItemSelection,
            expandedGroups,
            toggleExpanded,
        ],
    );

    const itemCount = similarImageGroups.length;

    // Height constants for group list items
    // Breakdown: paddingBlockStart(24) + checkbox(42) + paddingBlock(4) + divider(1) + paddingBlockEnd(20) + itemPadding(16)
    const GROUP_HEADER_HEIGHT = 107;

    const itemSize = useCallback(
        (index: number) => {
            const group = similarImageGroups[index];
            if (!group) return 0;

            const fixedHeight = GROUP_HEADER_HEIGHT;
            const isExpanded = expandedGroups.has(group.id);

            let cellCount = group.items.length;
            if (!isExpanded && cellCount > 6) {
                // 6 items + 1 "more" button
                cellCount = 7;
            }

            const rows = Math.ceil(cellCount / layoutParams.columns);
            const gridHeight =
                rows * layoutParams.itemHeight + (rows - 1) * layoutParams.gap;

            return fixedHeight + gridHeight + 8;
        },
        [similarImageGroups, expandedGroups, layoutParams],
    );

    const listRef = React.useRef<VariableSizeList>(null);

    // Reset cache when expanded groups or data changes
    React.useEffect(() => {
        listRef.current?.resetAfterIndex(0);
    }, [expandedGroups, similarImageGroups]);

    // Scroll to top when category filter changes
    React.useEffect(() => {
        listRef.current?.scrollTo(0);
    }, [categoryFilter]);

    return (
        <VariableSizeList
            ref={listRef}
            width={width}
            height={height}
            itemCount={itemCount}
            itemSize={itemSize}
            itemKey={(index) => similarImageGroups[index]?.id || index}
            itemData={itemData}
        >
            {SimilarImagesListRow}
        </VariableSizeList>
    );
};

type SimilarImagesListItemData = Pick<
    SimilarImagesListProps,
    "similarImageGroups" | "onToggleSelection" | "onToggleItemSelection"
> & {
    layoutParams: ThumbnailGridLayoutParams;
    expandedGroups: Set<string>;
    toggleExpanded: (groupId: string) => void;
};

const SimilarImagesListRow = memo(
    ({
        index,
        style,
        data,
    }: ListChildComponentProps<SimilarImagesListItemData>) => {
        const {
            layoutParams,
            similarImageGroups,
            onToggleSelection,
            onToggleItemSelection,
            expandedGroups,
            toggleExpanded,
        } = data;
        const group = similarImageGroups[index]!;
        const { isSelected } = group;

        const hideDivider = layoutParams.isSmallerLayout;

        return (
            <Box style={style}>
                <GroupHeader
                    group={group}
                    isSelected={isSelected}
                    onToggle={() => onToggleSelection(index)}
                />
                <Divider
                    sx={[
                        { marginX: 1 },
                        hideDivider ? { opacity: 0 } : { opacity: 0.8 },
                    ]}
                />
                <GroupContent
                    group={group}
                    groupIndex={index}
                    layoutParams={layoutParams}
                    onToggleItemSelection={onToggleItemSelection}
                    isExpanded={expandedGroups.has(group.id)}
                    onToggleExpanded={() => toggleExpanded(group.id)}
                />
            </Box>
        );
    },
    areEqual,
);

interface GroupHeaderProps {
    group: SimilarImageGroup;
    isSelected: boolean;
    onToggle: () => void;
}

const GroupHeader: React.FC<GroupHeaderProps> = ({
    group,
    isSelected,
    onToggle,
}) => {
    const { items, totalSize } = group;
    const deletableCount = Math.max(0, items.length - 1);

    return (
        <SpacedRow sx={{ padding: 1 }}>
            <Stack direction="row" spacing={2} alignItems="baseline" sx={{ flex: 1 }}>
                <Typography color={isSelected ? "text.primary" : "text.secondary"}>
                    {items.length} {t("photos")}
                </Typography>
                <Typography variant="body" color="text.secondary">
                    {t("similarity")}:{" "}
                    {(100 * (1 - group.furthestDistance)).toFixed(0)}%
                </Typography>
                <Typography variant="body" color="text.secondary">
                    {formattedByteSize(totalSize)}
                </Typography>
                {deletableCount > 0 && (
                    <Typography variant="body" color="error.main">
                        -
                        {formattedByteSize(
                            totalSize - (items[0]?.file.info?.fileSize || 0),
                        )}
                    </Typography>
                )}
            </Stack>
            <Checkbox checked={isSelected} onChange={onToggle} />
        </SpacedRow>
    );
};

interface GroupContentProps {
    group: SimilarImageGroup;
    groupIndex: number;
    layoutParams: ThumbnailGridLayoutParams;
    onToggleItemSelection: (groupIndex: number, itemIndex: number) => void;
    isExpanded: boolean;
    onToggleExpanded: () => void;
}

type SimilarImagesItemGridProps = Pick<
    SimilarImagesListItemData,
    "layoutParams"
>;

const ItemGrid = styled("div", {
    shouldForwardProp: (prop) => prop != "layoutParams",
})<SimilarImagesItemGridProps>(
    ({ layoutParams }) => `
                                                display: grid;
                                                padding-inline: ${layoutParams.paddingInline}px;
                                                grid-template-columns: repeat(${layoutParams.columns}, ${layoutParams.itemWidth}px);
                                                grid-auto-rows: ${layoutParams.itemHeight}px;
                                                gap: ${layoutParams.gap}px;
                                                `,
);

const GroupContent: React.FC<GroupContentProps> = ({
    group,
    groupIndex,
    layoutParams,
    onToggleItemSelection,
    isExpanded,
    onToggleExpanded,
}) => {
    const { items } = group;

    const visibleItems = isExpanded ? items : items.slice(0, 6);
    const remainingCount = items.length - 6;

    return (
        <ItemGrid {...{ layoutParams }}>
            {visibleItems.map((item, itemIndex) => (
                <Box
                    key={item.file.id}
                    sx={{ position: "relative", cursor: "pointer" }}
                    onClick={() => onToggleItemSelection(groupIndex, itemIndex)}
                >
                    <ItemCard
                        TileComponent={DuplicateItemTile}
                        coverFile={item.file}
                        sx={(theme) => ({
                            // Visual feedback for selected items:
                            // Match 'duplicates' behavior: opacity 0.5 and border
                            opacity: item.isSelected ? 0.5 : 1,
                            outline: item.isSelected
                                ? `2px solid ${theme.vars.palette.primary.main}`
                                : "none",
                            transition:
                                "opacity 0.2s ease-in-out, outline 0.2s ease-in-out",
                            "&:hover": {
                                opacity: item.isSelected ? 0.4 : 0.9,
                            },
                        })}
                    >
                        <Box
                            sx={{
                                position: "absolute",
                                top: 8,
                                right: 8,
                                zIndex: 1,
                            }}
                        >
                            <Checkbox
                                checked={item.isSelected || false}
                                onClick={(e) => {
                                    e.stopPropagation();
                                    onToggleItemSelection(
                                        groupIndex,
                                        itemIndex,
                                    );
                                }}
                                sx={{
                                    color: "white",
                                    backgroundColor: "rgba(0, 0, 0, 0.5)",
                                    borderRadius: "4px",
                                    padding: "4px",
                                    "&.Mui-checked": { color: "primary.main" },
                                    // Make checkbox always visible or visible on hover/selected
                                    // Based on mobile standard, usually always visible provides better affordance
                                }}
                            />
                        </Box>
                        <TileBottomTextOverlay>
                            <Ellipsized2LineTypography variant="body">
                                {item.collectionName}
                            </Ellipsized2LineTypography>
                            <Typography
                                variant="small"
                                sx={{ opacity: 0.7, fontSize: "0.75rem" }}
                            >
                                {formattedByteSize(
                                    item.file.info?.fileSize ?? 0,
                                )}
                            </Typography>
                        </TileBottomTextOverlay>
                    </ItemCard>
                </Box>
            ))
            }
            {
                remainingCount > 0 && !isExpanded && (
                    <Box
                        sx={{
                            position: "relative",
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            backgroundColor: "rgba(128, 128, 128, 0.2)",
                            borderRadius: 1,
                            cursor: "pointer",
                            "&:hover": {
                                backgroundColor: "rgba(128, 128, 128, 0.3)",
                            },
                        }}
                        onClick={onToggleExpanded}
                    >
                        <Typography variant="h6" color="text.secondary">
                            +{remainingCount} {t("more")}
                        </Typography>
                    </Box>
                )
            }
        </ItemGrid>
    );
};

interface RemoveButtonProps {
    disabled: boolean;
    deletableCount: number;
    deletableSize: number;
    progress: number | undefined;
    onRemove: () => void;
}

const RemoveButton: React.FC<RemoveButtonProps> = ({
    disabled,
    deletableCount,
    deletableSize,
    progress,
    onRemove,
}) => (
    <FocusVisibleButton
        sx={{ minWidth: "min(100%, 320px)", margin: "auto" }}
        disabled={disabled}
        onClick={onRemove}
    >
        <Stack
            sx={{
                gap: 1,
                // Prevent a layout shift by giving a minHeight that is larger
                // than all expected states.
                minHeight: "45px",
                justifyContent: "center",
                flex: 1,
            }}
        >
            {progress !== undefined ? (
                <LinearProgress
                    sx={{ borderRadius: "4px" }}
                    variant={progress === 0 ? "indeterminate" : "determinate"}
                    value={progress}
                />
            ) : (
                <>
                    <Typography>
                        {t("remove_similar_images_count", {
                            count: deletableCount,
                        })}
                    </Typography>
                    <Typography variant="small" fontWeight="regular">
                        {formattedByteSize(deletableSize)}
                    </Typography>
                </>
            )}
        </Stack>
    </FocusVisibleButton>
);
