import { useRedirectIfNeedsCredentials } from "@/accounts/components/utils/use-redirect";
import { ActivityErrorIndicator } from "@/base/components/ErrorIndicator";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { CenteredFill } from "@/base/components/mui/Container";
import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import {
    OverflowMenu,
    OverflowMenuOption,
} from "@/base/components/OverflowMenu";
import { Ellipsized2LineTypography } from "@/base/components/Typography";
import { errorDialogAttributes } from "@/base/components/utils/dialog";
import { pt } from "@/base/i18n";
import log from "@/base/log";
import { formattedByteSize } from "@/new/photos/utils/units";
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
    Tooltip,
    Typography,
    type LinearProgressProps,
} from "@mui/material";
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
    DuplicateTileTextOverlay,
    ItemCard,
} from "../components/Tiles";
import {
    computeThumbnailGridLayoutParams,
    type ThumbnailGridLayoutParams,
} from "../components/utils/thumbnail-grid-layout";
import {
    deduceDuplicates,
    removeSelectedDuplicateGroups,
    type DuplicateGroup,
} from "../services/dedup";
import { useAppContext } from "../types/context";

const Page: React.FC = () => {
    const { showMiniDialog } = useAppContext();

    const [state, dispatch] = useReducer(dedupReducer, initialDedupState);

    useRedirectIfNeedsCredentials("/duplicates");

    useEffect(() => {
        dispatch({ type: "analyze" });
        void deduceDuplicates()
            .then((duplicateGroups) =>
                dispatch({ type: "analysisCompleted", duplicateGroups }),
            )
            .catch((e: unknown) => {
                log.error("Failed to detect duplicates", e);
                dispatch({ type: "analysisFailed" });
            });
    }, []);

    const handleRemoveDuplicates = useCallback(() => {
        dispatch({ type: "dedupe" });
        void removeSelectedDuplicateGroups(
            state.duplicateGroups,
            (duplicateGroup: DuplicateGroup) =>
                dispatch({ type: "didRemoveDuplicateGroup", duplicateGroup }),
        ).then((allSuccess) => {
            dispatch({ type: "dedupeCompleted" });
            if (!allSuccess) {
                const msg = pt(
                    "Some errors occurred when trying to remove duplicates.",
                );
                showMiniDialog(errorDialogAttributes(msg));
            }
        });
    }, [state.duplicateGroups, showMiniDialog]);

    const contents = (() => {
        switch (state.status) {
            case undefined:
            case "analyzing":
                return <Loading />;
            case "analysisFailed":
                return <LoadFailed />;
            case "analysisCompleted":
                if (state.duplicateGroups.length == 0) {
                    return <NoDuplicatesFound />;
                } else {
                    return (
                        <Duplicates
                            duplicateGroups={state.duplicateGroups}
                            sortOrder={state.sortOrder}
                            onToggleSelection={(index) =>
                                dispatch({ type: "toggleSelection", index })
                            }
                            prunableCount={state.prunableCount}
                            prunableSize={state.prunableSize}
                            isDeduping={state.isDeduping}
                            onRemoveDuplicates={handleRemoveDuplicates}
                        />
                    );
                }
            default:
                return <Loading />;
        }
    })();

    return (
        <Stack sx={{ flex: 1 }}>
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

type SortOrder = "prunableCount" | "prunableSize";

interface DedupState {
    /** Status of the screen, between initial state => analysis */
    status: undefined | "analyzing" | "analysisFailed" | "analysisCompleted";
    /** `true` if a dedupe is in progress. */
    isDeduping: boolean;
    /**
     * Groups of duplicates.
     *
     * These are groups of files that our algorithm has detected as exact
     * duplicates, augmented with UI state and various cached properties to make
     * them more amenable to be directly used by the UI component.
     *
     * These are sorted in order of display, reflecting the {@link sortType}
     * user preference.
     */
    duplicateGroups: DuplicateGroup[];
    /**
     * The attribute to use for sorting {@link duplicateGroups}.
     */
    sortOrder: SortOrder;
    /**
     * The number of files that will be pruned if the user decides to dedup the
     * current selection.
     */
    prunableCount: number;
    /**
     * The size (in bytes) that can be saved if the user decides to dedup the
     * current selection.
     */
    prunableSize: number;
}

type DedupAction =
    | { type: "analyze" }
    | { type: "analysisFailed" }
    | { type: "analysisCompleted"; duplicateGroups: DuplicateGroup[] }
    | { type: "changeSortOrder"; sortOrder: SortOrder }
    | { type: "toggleSelection"; index: number }
    | { type: "deselectAll" }
    | { type: "dedupe" }
    | { type: "didRemoveDuplicateGroup"; duplicateGroup: DuplicateGroup }
    | { type: "dedupeCompleted" };

const initialDedupState: DedupState = {
    status: undefined,
    isDeduping: false,
    duplicateGroups: [],
    sortOrder: "prunableSize",
    prunableCount: 0,
    prunableSize: 0,
};

const dedupReducer: React.Reducer<DedupState, DedupAction> = (
    state,
    action,
) => {
    switch (action.type) {
        case "analyze":
            return { ...state, status: "analyzing" };
        case "analysisFailed":
            return { ...state, status: "analysisFailed" };
        case "analysisCompleted": {
            const duplicateGroups = sortedCopyOfDuplicateGroups(
                action.duplicateGroups,
                state.sortOrder,
            );
            const selected = duplicateGroups.map(() => true);
            const { prunableCount, prunableSize } =
                deducePrunableCountAndSize(duplicateGroups);
            return {
                ...state,
                status: "analysisCompleted",
                duplicateGroups,
                selected,
                prunableCount,
                prunableSize,
            };
        }

        case "changeSortOrder": {
            const sortOrder = action.sortOrder;
            const duplicateGroups = sortedCopyOfDuplicateGroups(
                state.duplicateGroups,
                sortOrder,
            );
            return {
                ...state,
                sortOrder,
                duplicateGroups,
            };
        }

        case "toggleSelection": {
            const duplicateGroups = [...state.duplicateGroups];
            const duplicateGroup = duplicateGroups[action.index]!;
            duplicateGroup.isSelected = !duplicateGroup.isSelected;
            const { prunableCount, prunableSize } =
                deducePrunableCountAndSize(duplicateGroups);
            return {
                ...state,
                duplicateGroups,
                prunableCount,
                prunableSize,
            };
        }

        case "deselectAll": {
            const duplicateGroups = state.duplicateGroups.map(
                (duplicateGroup) => ({ ...duplicateGroup, isSelected: false }),
            );
            const { prunableCount, prunableSize } =
                deducePrunableCountAndSize(duplicateGroups);
            return {
                ...state,
                duplicateGroups,
                prunableCount,
                prunableSize,
            };
        }

        case "dedupe":
            return { ...state, isDeduping: true };

        case "didRemoveDuplicateGroup": {
            const duplicateGroups = state.duplicateGroups.filter(
                ({ id }) => id != action.duplicateGroup.id,
            );
            const { prunableCount, prunableSize } =
                deducePrunableCountAndSize(duplicateGroups);
            return {
                ...state,
                duplicateGroups,
                prunableCount,
                prunableSize,
            };
        }

        case "dedupeCompleted":
            return { ...state, isDeduping: false };
    }
};

/**
 * Return a copy of the given {@link duplicateGroups}, also sorting them as per
 * the given {@link sortOrder}.
 *
 * Helper method for the reducer */
const sortedCopyOfDuplicateGroups = (
    duplicateGroups: DuplicateGroup[],
    sortOrder: DedupState["sortOrder"],
) =>
    [...duplicateGroups].sort((a, b) =>
        sortOrder == "prunableSize"
            ? b.prunableSize - a.prunableSize
            : b.prunableCount - a.prunableCount,
    );

/** Helper method for the reducer */
const deducePrunableCountAndSize = (duplicateGroups: DuplicateGroup[]) => {
    const prunableCount = duplicateGroups.reduce(
        (sum, { prunableCount, isSelected }) =>
            sum + (isSelected ? prunableCount : 0),
        0,
    );
    const prunableSize = duplicateGroups.reduce(
        (sum, { prunableSize, isSelected }) =>
            sum + (isSelected ? prunableSize : 0),
        0,
    );
    return { prunableCount, prunableSize };
};

interface NavbarProps {
    /**
     * The current sort order.
     */
    sortOrder: SortOrder;
    /**
     * Called when the user changes the sort order using the sort order menu
     * visible via the navbar.
     */
    onChangeSortOrder: (sortOrder: SortOrder) => void;
    /**
     * Called when the user selects the deselect all option.
     */
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
                borderBottom: `1px solid ${theme.palette.divider}`,
            })}
        >
            <Box sx={{ minWidth: "100px" /* 2 icons + gap */ }}>
                <IconButton onClick={router.back}>
                    <ArrowBackIcon />
                </IconButton>
            </Box>
            <Typography variant="large">{pt("Remove duplicates")}</Typography>
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
        ariaID="duplicates-sort"
        triggerButtonIcon={
            <Tooltip title={pt("Sort")}>
                <SortIcon />
            </Tooltip>
        }
    >
        <OverflowMenuOption
            endIcon={sortOrder == "prunableSize" ? <DoneIcon /> : undefined}
            onClick={() => onChangeSortOrder("prunableSize")}
        >
            {pt("Total size")}
        </OverflowMenuOption>
        <OverflowMenuOption
            endIcon={sortOrder == "prunableCount" ? <DoneIcon /> : undefined}
            onClick={() => onChangeSortOrder("prunableCount")}
        >
            {pt("Count")}
        </OverflowMenuOption>
    </OverflowMenu>
);

type OptionsMenuProps = Pick<NavbarProps, "onDeselectAll">;

const OptionsMenu: React.FC<OptionsMenuProps> = ({ onDeselectAll }) => (
    <OverflowMenu ariaID="duplicates-options">
        <OverflowMenuOption
            startIcon={<RemoveCircleOutlineIcon />}
            onClick={onDeselectAll}
        >
            {pt("Deselect all")}
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

const NoDuplicatesFound: React.FC = () => (
    <CenteredFill>
        <Typography color="text.muted" sx={{ textAlign: "center" }}>
            {pt("No duplicates")}
        </Typography>
    </CenteredFill>
);

type DuplicatesProps = Pick<
    DuplicatesListProps,
    "duplicateGroups" | "sortOrder" | "onToggleSelection"
> &
    DeduplicateButtonProps;

const Duplicates: React.FC<DuplicatesProps> = ({
    duplicateGroups,
    sortOrder,
    onToggleSelection,
    ...deduplicateButtonProps
}) => (
    <Stack sx={{ flex: 1 }}>
        <Box sx={{ flex: 1, overflow: "hidden", paddingBlockEnd: 1 }}>
            <Autosizer>
                {({ width, height }) => (
                    <DuplicatesList
                        {...{
                            width,
                            height,
                            duplicateGroups,
                            sortOrder,
                            onToggleSelection,
                        }}
                    />
                )}
            </Autosizer>
        </Box>
        <Stack sx={{ margin: 1 }}>
            <DeduplicateButton {...deduplicateButtonProps} />
        </Stack>
    </Stack>
);

interface DuplicatesListProps {
    /**
     * The width (px) that the list should size itself to.
     */
    width: number;
    /**
     * The height (px) that the list should size itself to.
     */
    height: number;
    /**
     * Groups of duplicates. Guaranteed to be non-empty.
     */
    duplicateGroups: DuplicateGroup[];
    /**
     * The current {@link SortOrder} that is being used for sorting {@link duplicateGroups}.
     */
    sortOrder: SortOrder;
    /**
     * Called when the user toggles the selection for the duplicate group at the
     * given {@link index}.
     */
    onToggleSelection: (index: number) => void;
}

type DuplicatesListItemData = Pick<
    DuplicatesListProps,
    "duplicateGroups" | "onToggleSelection"
> & {
    layoutParams: ThumbnailGridLayoutParams;
};

const DuplicatesList: React.FC<DuplicatesListProps> = ({
    width,
    height,
    duplicateGroups,
    sortOrder,
    onToggleSelection,
}) => {
    const layoutParams = useMemo(
        () => computeThumbnailGridLayoutParams(width),
        [width],
    );

    const itemData = { layoutParams, duplicateGroups, onToggleSelection };
    const itemCount = duplicateGroups.length;
    const itemSize = (index: number) => {
        // The height of the header is driven by the height of the Checkbox,
        // which is 42px high, and the divider, which is 1px. The rest of the
        // height comes from the fixed paddings, margins on the header, the
        // divider, and on the row itself.
        const fixedHeight = 24 + 42 + 4 + 1 + 20 + 16;

        const duplicateGroup = duplicateGroups[index]!;
        const rowCount = Math.ceil(
            duplicateGroup.items.length / layoutParams.columns,
        );
        const rowHeight = layoutParams.itemHeight + layoutParams.gap;

        return fixedHeight + rowCount * rowHeight;
    };
    const itemKey = (index: number, itemData: DuplicatesListItemData) =>
        itemData.duplicateGroups[index]!.id;

    // Derive a key based on aspects whose change should cause the list to be
    // recreated. This is the easiest way I've found to get react-window to
    // invalidate `itemSize` values when, say, the width changes.
    const key = `${width}-${sortOrder}`;

    return (
        <VariableSizeList
            key={key}
            {...{ height, width, itemData, itemCount, itemSize, itemKey }}
        >
            {ListItem}
        </VariableSizeList>
    );
};

const ListItem: React.FC<ListChildComponentProps<DuplicatesListItemData>> =
    memo(({ index, style, data }) => {
        const { layoutParams, duplicateGroups, onToggleSelection } = data;

        // For smaller screens, hide to divider to reduce visual noise. For
        // larger screens, the divider is helpful in guiding the user's eyes to
        // the checkbox which is otherwise at the right end of the header.
        const hideDivider = layoutParams.isSmallerLayout;

        const duplicateGroup = duplicateGroups[index]!;
        const items = duplicateGroup.items;
        const count = items.length;
        const itemSize = formattedByteSize(duplicateGroup.itemSize);
        const checked = duplicateGroup.isSelected;
        const onChange = () => onToggleSelection(index);

        return (
            <Stack
                {...{ style }}
                sx={{ paddingBlockEnd: "16px", opacity: checked ? 1 : 0.8 }}
            >
                <Stack
                    direction="row"
                    sx={{
                        justifyContent: "space-between",
                        alignItems: "center",
                        marginInline: 1,
                        paddingInline: `${layoutParams.paddingInline}px`,
                        paddingBlock: "24px 0px",
                    }}
                >
                    <Typography color={checked ? "text.base" : "text.muted"}>
                        {pt(`${count} items, ${itemSize} each`)}
                    </Typography>
                    {/* The size of this Checkbox is 42px. */}
                    <Checkbox {...{ checked, onChange }} />
                </Stack>
                <Divider
                    variant="middle"
                    sx={{
                        opacity: hideDivider ? 0 : 0.8,
                        marginBlock: "4px 20px",
                    }}
                />
                <ItemGrid {...{ layoutParams }}>
                    {items.map((item, j) => (
                        <ItemCard
                            key={j}
                            TileComponent={DuplicateItemTile}
                            coverFile={item.file}
                        >
                            <DuplicateTileTextOverlay>
                                <Ellipsized2LineTypography color="text.muted">
                                    {item.collectionName}
                                </Ellipsized2LineTypography>
                            </DuplicateTileTextOverlay>
                        </ItemCard>
                    ))}
                </ItemGrid>
            </Stack>
        );
    }, areEqual);

type ItemGridProps = Pick<DuplicatesListItemData, "layoutParams">;

const ItemGrid = styled("div", {
    shouldForwardProp: (prop) => prop != "layoutParams",
})<ItemGridProps>(
    ({ layoutParams }) => `
    display: grid;
    padding-inline: ${layoutParams.paddingInline}px;
    grid-template-columns: repeat(${layoutParams.columns}, ${layoutParams.itemWidth}px);
    grid-auto-rows: ${layoutParams.itemHeight}px;
    gap: ${layoutParams.gap}px;
`,
);

interface DeduplicateButtonProps {
    /**
     * See {@link prunableCount} in {@link DedupState}.
     */
    prunableCount: number;
    /**
     * See {@link prunableSize} in {@link DedupState}.
     */
    prunableSize: number;
    /**
     * `true` if a deduplication is in progress
     */
    isDeduping: DedupState["isDeduping"];
    /**
     * Called when the user presses the button to remove duplicates.
     */
    onRemoveDuplicates: () => void;
}

const DeduplicateButton: React.FC<DeduplicateButtonProps> = ({
    prunableCount,
    prunableSize,
    isDeduping,
    onRemoveDuplicates,
}) => (
    <FocusVisibleButton
        sx={{ minWidth: "min(100%, 320px)", margin: "auto" }}
        disabled={prunableCount == 0 || isDeduping}
        onClick={onRemoveDuplicates}
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
            {isDeduping ? (
                <LinearProgressWithLabel value={50} />
            ) : (
                <>
                    <Typography>
                        {pt(`Delete ${prunableCount} items`)}
                    </Typography>
                    <Typography variant="small" fontWeight={"normal"}>
                        {formattedByteSize(prunableSize)}
                    </Typography>
                </>
            )}
        </Stack>
    </FocusVisibleButton>
);

interface LinearProgressWithLabelProps {
    value: Exclude<LinearProgressProps["value"], undefined>;
}

export const LinearProgressWithLabel: React.FC<
    LinearProgressWithLabelProps
> = ({ value }) => (
    <Stack direction="row" sx={{ flex: 1, gap: 2, alignItems: "center" }}>
        <LinearProgress sx={{ flex: 1 }} variant="determinate" value={value} />
        <Typography sx={{ minWidth: "3ex" }}>`{Math.round(value)}%</Typography>
    </Stack>
);
