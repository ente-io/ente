import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { pt } from "@/base/i18n";
import type { EnteFile } from "@/media/file";
import { VerticallyCentered } from "@ente/shared/components/Container";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import MoreHorizIcon from "@mui/icons-material/MoreHoriz";
import SortIcon from "@mui/icons-material/Sort";
import { Box, IconButton, Stack, Typography } from "@mui/material";
import { useRouter } from "next/router";
import React, { useEffect } from "react";
import { useAppContext } from "../types/context";

const Page: React.FC = () => {
    const { showNavBar } = useAppContext();

    useEffect(() => {
        showNavBar(false);
    }, []);

    return (
        <Stack sx={{ flex: 1 }}>
            <Navbar />
            <Contents />
        </Stack>
    );
};

export default Page;

/**
 * A group of duplicates as shown in the UI.
 */
interface DuplicateGroup {
    /**
     * Files which our algorithm has determined to be duplicates of each other.
     *
     * These are sorted in the order of precedence, such that the first item is
     * the one we'd wish to retain if the user decides to dedup this group.
     */
    items: {
        /** The underlying collection file. */
        file: EnteFile;
        /** The name of the collection to which this file belongs. */
        collectionName: string;
    }[];
    /**
     * The size (in bytes) of each item in the group.
     */
    itemSize: number;
    /**
     * The number of files that will be pruned if the user decides to dedup this group.
     */
    prunableCount: number;
    /**
     * The size (in bytes) that can be saved if the user decides to dedup this group.
     */
    prunableSize: number;
    /**
     * `true` if the user has marked this group for deduping.
     */
    isSelected: boolean;
}

interface DuplicatesState {
    status: "analyzing" | "deleting" | undefined;
    /**
     * Groups of duplicates.
     *
     * Within each group, the files  are sorted in the order of precedence such
     * that the first item is the one we'd wish to retain if the user decides to
     * dedup this group.
     *
     * This is the primary source of truth computed after we exit the
     * "analyzing" state. It is used to derive the {@link duplicateGroups}
     * property which the UI then displays.
     */
    duplicates: EnteFile[][];
    /**
     * {@link duplicates} augmented with UI state and various cached properties
     * to make them more amenable to be directly used by the UI component.
     *
     * These are sorted in order of display, reflecting the {@link sortType}
     * user preference.
     */
    duplicateGroups: DuplicateGroup[];
    /**
     * The attribute to use for sorting {@link duplicateGroups}.
     */
    sortType: "prunableCount" | "prunableSize";
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

const Contents: React.FC = () => {
    return (
        <VerticallyCentered>
            <ActivityIndicator />
        </VerticallyCentered>
    );
};
