import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { pt } from "@/base/i18n";
import { VerticallyCentered } from "@ente/shared/components/Container";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import MoreHorizIcon from "@mui/icons-material/MoreHoriz";
import SortIcon from "@mui/icons-material/Sort";
import { Box, IconButton, Stack, Typography } from "@mui/material";
import { useRouter } from "next/router";
import React, { useEffect, useReducer } from "react";
import type { DuplicateGroup } from "../services/dedup";
import { useAppContext } from "../types/context";

const Page: React.FC = () => {
    const { showNavBar } = useAppContext();

    const [state, dispatch] = useReducer(dedupReducer, initialDedupState);

    useEffect(() => {
        showNavBar(false);
        console.log(dispatch);
    }, []);

    const contents = (() => {
        switch (state.status) {
            case undefined:
            case "analyzing":
                return <Loading />;
            default:
                return <Loading />;
        }
    })();

    return (
        <Stack sx={{ flex: 1 }}>
            <Navbar />
            {contents}
        </Stack>
    );
};

export default Page;

interface DedupState {
    status:
        | undefined
        | "analyzing"
        | "analysisFailed"
        | "showingResults"
        | "deleting"
        | "deletionFailed";
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
    sortOrder: "prunableCount" | "prunableSize";
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
    | { type: "analyzed"; duplicateGroups: DuplicateGroup[] }
    | { type: "changeSortOrder"; sortOrder: DedupState["sortOrder"] }
    | { type: "select"; index: number }
    | { type: "deselect"; index: number }
    | { type: "deselectAll" }
    | { type: "dedup" }
    | { type: "dedupCompleted" }
    | { type: "dedupFailed" };

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
        default:
            return state;
    }
};

const Navbar: React.FC = () => {
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
                <IconButton>
                    <SortIcon />
                </IconButton>
                <IconButton>
                    <MoreHorizIcon />
                </IconButton>
            </Stack>
        </Stack>
    );
};

const Loading: React.FC = () => {
    return (
        <VerticallyCentered>
            <ActivityIndicator />
        </VerticallyCentered>
    );
};
