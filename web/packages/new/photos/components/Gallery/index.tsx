/**
 * @file code that really belongs to pages/gallery.tsx itself (or related
 * files), but it written here in a separate file so that we can write in this
 * package that has TypeScript strict mode enabled.
 *
 * Once the original gallery.tsx is strict mode, this code can be inlined back
 * there.
 */

import { pt } from "@/base/i18n";
import type { Person } from "@/new/photos/services/ml/people";
import type { SearchOption } from "@/new/photos/services/search/types";
import { wait } from "@/utils/promise";
import OverflowMenu from "@ente/shared/components/OverflowMenu/menu";
import { OverflowMenuOption } from "@ente/shared/components/OverflowMenu/option";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import MoreHoriz from "@mui/icons-material/MoreHoriz";
import { Typography } from "@mui/material";
import { t } from "i18next";
import React from "react";
import type { NewAppContextPhotos } from "../../types/context";
import { SpaceBetweenFlex } from "../mui-custom";
import { useWrapAsyncOperation } from "../use-wrap";
import { GalleryItemsHeaderAdapter, GalleryItemsSummary } from "./ListHeader";

/**
 * The context in which a selection was made.
 *
 * This allows us to reset the selection if user moves to a different context
 * and starts a new selection.
 * */
export type SelectionContext =
    | { mode: "albums" | "hidden-albums"; collectionID: number }
    | { mode: "people"; personID: string };

interface SearchResultsHeaderProps {
    selectedOption: SearchOption;
}

export const SearchResultsHeader: React.FC<SearchResultsHeaderProps> = ({
    selectedOption,
}) => (
    <GalleryItemsHeaderAdapter>
        <Typography color="text.muted" variant="large">
            {t("search_results")}
        </Typography>
        <GalleryItemsSummary
            name={selectedOption.suggestion.label}
            fileCount={selectedOption.fileCount}
        />
    </GalleryItemsHeaderAdapter>
);

interface PeopleListHeaderProps {
    person: Person;
    appContext: NewAppContextPhotos;
}

export const PersonListHeader: React.FC<PeopleListHeaderProps> = ({
    person,
    appContext,
}) => {
    // TODO-Cluster
    const hasOptions = process.env.NEXT_PUBLIC_ENTE_WIP_CL;

    const wrap = useWrapAsyncOperation(appContext);

    const addPerson = wrap(async () => {
        console.log("add person");
        await wait(2000);
        throw new Error("test");
    });

    const rename = wrap(async () => {
        console.log("add person");
        await wait(2000);
        throw new Error("test");
    });

    return (
        <GalleryItemsHeaderAdapter>
            <SpaceBetweenFlex>
                <GalleryItemsSummary
                    name={
                        person.name ?? pt("Unnamed person") /* TODO-Cluster */
                    }
                    nameProps={person.name ? {} : { color: "text.muted" }}
                    fileCount={person.fileIDs.length}
                />
                {hasOptions && (
                    <OverflowMenu
                        ariaControls={"person-options"}
                        triggerButtonIcon={<MoreHoriz />}
                    >
                        {person.type == "cgroup" ? (
                            <CGroupPersonOptions onRename={rename} />
                        ) : (
                            <ClusterPersonOptions onAddPerson={addPerson} />
                        )}
                    </OverflowMenu>
                )}
            </SpaceBetweenFlex>
        </GalleryItemsHeaderAdapter>
    );
};

interface CGroupPersonOptionsProps {
    onRename: () => void;
}

const CGroupPersonOptions: React.FC<CGroupPersonOptionsProps> = ({
    onRename,
}) => (
    <>
        <OverflowMenuOption
            startIcon={<EditIcon />}
            centerAlign
            onClick={onRename}
        >
            {t("rename")}
        </OverflowMenuOption>
        {/* <OverflowMenuOption
            startIcon={<RemoveIcon />}
            centerAlign
            onClick={onDelete}
        >
            {pt("Remove")}
        </OverflowMenuOption> */}
    </>
);

interface ClusterPersonOptionsProps {
    onAddPerson: () => void;
}

const ClusterPersonOptions: React.FC<ClusterPersonOptionsProps> = ({
    onAddPerson,
}) => (
    <>
        <OverflowMenuOption
            startIcon={<AddIcon />}
            centerAlign
            onClick={onAddPerson}
        >
            {pt("Add a name")}
        </OverflowMenuOption>
    </>
);
