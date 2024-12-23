import { useRedirectIfNeedsCredentials } from "@/accounts/components/utils/use-redirect";
import { ActivityErrorIndicator } from "@/base/components/ErrorIndicator";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { CenteredFill } from "@/base/components/mui/Container";
import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import {
    OverflowMenu,
    OverflowMenuOption,
} from "@/base/components/OverflowMenu";
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
    IconButton,
    Stack,
    styled,
    Tooltip,
    Typography,
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
    computeThumbnailGridLayoutParams,
    type ThumbnailGridLayoutParams,
} from "../components/utils/thumbnail-grid-layout";
import { deduceDuplicates, type DuplicateGroup } from "../services/dedup";
import { useAppContext } from "../types/context";

const Page: React.FC = () => {
    const { showNavBar } = useAppContext();

    const [state, dispatch] = useReducer(dedupReducer, initialDedupState);

    useRedirectIfNeedsCredentials("/duplicates");

    useEffect(() => {
        // TODO: Remove me
        showNavBar(false);

        dispatch({ type: "analyze" });
        void deduceDuplicates()
            .then((duplicateGroups) =>
                dispatch({ type: "analysisCompleted", duplicateGroups }),
            )
            .catch((e: unknown) => {
                log.error("Failed to detect duplicates", e);
                dispatch({ type: "analysisFailed" });
            });
    }, [showNavBar]);

    const handleRemoveDuplicates = useCallback(() => {
        dispatch({ type: "dedupe" });
    }, []);

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
                            onToggleSelection={(index) =>
                                dispatch({ type: "toggleSelection", index })
                            }
                            prunableCount={state.prunableCount}
                            prunableSize={state.prunableSize}
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
    status:
        | undefined
        | "analyzing"
        | "analysisFailed"
        | "analysisCompleted"
        | "dedupe"
        | "dedupeFailed";
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
    | { type: "dedupeCompleted" }
    | { type: "dedupeFailed" };

const initialDedupState: DedupState = {
    status: undefined,
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
            const duplicateGroups = action.duplicateGroups;
            sortDuplicateGroups(duplicateGroups, state.sortOrder);
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
            const duplicateGroups = state.duplicateGroups;
            sortDuplicateGroups(duplicateGroups, sortOrder);
            return {
                ...state,
                sortOrder,
                duplicateGroups,
            };
        }

        case "toggleSelection": {
            const duplicateGroups = state.duplicateGroups;
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
                (duplicateGroup) => ({ ...duplicateGroup, selected: false }),
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

        default:
            return state;
    }
};

/** Helper method for the reducer */
const sortDuplicateGroups = (
    duplicateGroups: DuplicateGroup[],
    sortOrder: DedupState["sortOrder"],
) =>
    duplicateGroups.sort((a, b) =>
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

type DuplicatesProps = DuplicatesListProps & DeduplicateButtonProps;

const Duplicates: React.FC<DuplicatesProps> = ({
    duplicateGroups,
    onToggleSelection,
    ...deduplicateButtonProps
}) => {
    return (
        <Stack sx={{ flex: 1 }}>
            <Box sx={{ flex: 1, overflow: "hidden", paddingBlock: 1 }}>
                <Autosizer>
                    {({ width, height }) => (
                        <DuplicatesList
                            {...{
                                width,
                                height,
                                duplicateGroups,
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
};

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
    onToggleSelection,
}) => {
    const layoutParams = useMemo(
        () => computeThumbnailGridLayoutParams(width),
        [width],
    );

    const itemCount = duplicateGroups.length;
    const itemSize = (index: number) => {
        // The height of the header is driven by the height of the Checkbox, and
        // currently it is always a fixed 42 px high.
        const headerHeight = 42;

        const duplicateGroup = duplicateGroups[index]!;
        const rowCount = Math.ceil(
            duplicateGroup.items.length / layoutParams.columns,
        );
        const rowHeight = layoutParams.itemHeight + layoutParams.gap;

        return headerHeight + rowCount * rowHeight;
    };
    const itemData = { layoutParams, duplicateGroups, onToggleSelection };

    return (
        <VariableSizeList {...{ height, width, itemCount, itemSize, itemData }}>
            {ListItem}
        </VariableSizeList>
    );
};

const ListItem: React.FC<ListChildComponentProps<DuplicatesListItemData>> =
    memo(({ index, style, data }) => {
        const { duplicateGroups, onToggleSelection } = data;

        const duplicateGroup = duplicateGroups[index]!;
        const items = duplicateGroup.items;
        const count = items.length;
        const itemSize = formattedByteSize(duplicateGroup.itemSize);
        const checked = duplicateGroup.isSelected;
        const onChange = () => onToggleSelection(index);

        return (
            <Stack {...{ style }}>
                <Stack
                    direction="row"
                    sx={{
                        justifyContent: "space-between",
                        alignItems: "center",
                        paddingInline: 1,
                    }}
                >
                    <Typography color={checked ? "text.base" : "text.muted"}>
                        {pt(`${count} items, ${itemSize} each`)}
                    </Typography>
                    {/*
                      The size of this Checkbox, 42px, drives the height of
                      the header.
                     */}
                    <Checkbox {...{ checked, onChange }} />
                </Stack>
                <ItemGrid>
                    {items.map((item, j) => (
                        <div
                            key={j}
                            style={{
                                background: "red",
                                border: "2px solid green",
                            }}
                        >
                            {item.collectionName}
                        </div>
                    ))}
                </ItemGrid>
            </Stack>
        );
    }, areEqual);

const ItemGrid = styled("div")`
    display: grid;
    grid-template-columns: 200px 200px 200px;
`;

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
     * Called when the user presses the button to remove duplicates.
     */
    onRemoveDuplicates: () => void;
}

const DeduplicateButton: React.FC<DeduplicateButtonProps> = ({
    prunableCount,
    prunableSize,
    onRemoveDuplicates,
}) => (
    <FocusVisibleButton
        sx={{ minWidth: "min(100%, 320px)", margin: "auto" }}
        disabled={prunableCount == 0}
        onClick={onRemoveDuplicates}
    >
        <Stack sx={{ gap: 1 }}>
            <Typography>{pt(`Delete ${prunableCount} items`)}</Typography>
            <Typography variant="small" fontWeight={"normal"}>
                {formattedByteSize(prunableSize)}
            </Typography>
        </Stack>
    </FocusVisibleButton>
);
