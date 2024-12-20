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
import TickIcon from "@mui/icons-material/Done";
import MoreHorizIcon from "@mui/icons-material/MoreHoriz";
import SortIcon from "@mui/icons-material/Sort";
import { Box, IconButton, Stack, Tooltip, Typography } from "@mui/material";
import { useRouter } from "next/router";
import React, { useCallback, useEffect, useReducer } from "react";
import Autosizer from "react-virtualized-auto-sizer";
import { FixedSizeList, type ListChildComponentProps } from "react-window";
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
    | { type: "select"; index: number }
    | { type: "deselect"; index: number }
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
            const prunableCount = duplicateGroups.reduce(
                (sum, { prunableCount }) => sum + prunableCount,
                0,
            );
            const prunableSize = duplicateGroups.reduce(
                (sum, { prunableSize }) => sum + prunableSize,
                0,
            );
            return {
                ...state,
                status: "analysisCompleted",
                duplicateGroups,
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

        default:
            return state;
    }
};

const sortDuplicateGroups = (
    duplicateGroups: DuplicateGroup[],
    sortOrder: DedupState["sortOrder"],
) =>
    duplicateGroups.sort((a, b) =>
        sortOrder == "prunableSize"
            ? b.prunableSize - a.prunableSize
            : b.prunableCount - a.prunableCount,
    );

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
}

const Navbar: React.FC<NavbarProps> = ({ sortOrder, onChangeSortOrder }) => {
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
                <IconButton>
                    <MoreHorizIcon />
                </IconButton>
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
            endIcon={sortOrder == "prunableSize" ? <TickIcon /> : undefined}
            onClick={() => onChangeSortOrder("prunableSize")}
        >
            {pt("Total size")}
        </OverflowMenuOption>
        <OverflowMenuOption
            endIcon={sortOrder == "prunableCount" ? <TickIcon /> : undefined}
            onClick={() => onChangeSortOrder("prunableCount")}
        >
            {pt("Count")}
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
    ...deduplicateButtonProps
}) => {
    return (
        <Stack sx={{ flex: 1 }}>
            <Box sx={{ flex: 1, overflow: "hidden" }}>
                <DuplicatesList {...{ duplicateGroups }} />
            </Box>
            <Stack sx={{ margin: 1 }}>
                <DeduplicateButton {...deduplicateButtonProps} />
            </Stack>
        </Stack>
    );
};

interface DuplicatesListProps {
    /**
     * Groups of duplicates. Guaranteed to be non-empty.
     */
    duplicateGroups: DuplicateGroup[];
}

const DuplicatesList: React.FC<DuplicatesListProps> = ({ duplicateGroups }) => {
    const itemCount = duplicateGroups.length;
    const itemSize = 100;

    return (
        <Autosizer>
            {({ height, width }) => (
                <FixedSizeList
                    {...{ height, width, itemCount, itemSize }}
                    itemData={{ duplicateGroups }}
                >
                    {ListItem}
                </FixedSizeList>
            )}
        </Autosizer>
    );
};

const ListItem: React.FC<ListChildComponentProps<DuplicatesListProps>> = ({
    index,
    style,
    data,
}) => {
    const { duplicateGroups } = data;
    const duplicateGroup = duplicateGroups[index]!;
    const count = duplicateGroup.items.length;
    const itemSize = formattedByteSize(duplicateGroup.itemSize);
    return (
        <Stack {...{ style }}>
            <Typography>{pt(`${count} items, ${itemSize} each`)}</Typography>
        </Stack>
    );
};

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
