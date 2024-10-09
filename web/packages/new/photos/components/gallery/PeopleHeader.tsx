import { pt } from "@/base/i18n";
import {
    addCGroup,
    deleteCGroup,
    renameCGroup,
} from "@/new/photos/services/ml";
import { type Person } from "@/new/photos/services/ml/people";
import OverflowMenu from "@ente/shared/components/OverflowMenu/menu";
import { OverflowMenuOption } from "@ente/shared/components/OverflowMenu/option";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import MoreHoriz from "@mui/icons-material/MoreHoriz";
import { IconButton, Stack, Tooltip } from "@mui/material";
import { ClearIcon } from "@mui/x-date-pickers";
import { t } from "i18next";
import React, { useState } from "react";
import type { FaceCluster } from "../../services/ml/cluster";
import type { CGroup } from "../../services/user-entity";
import { useAppContext } from "../../types/context";
import { AddPersonDialog } from "../AddPersonDialog";
import { SpaceBetweenFlex } from "../mui";
import { NameInputDialog } from "../NameInputDialog";
import { SingleInputDialog } from "../SingleInputForm";
import { useWrapAsyncOperation } from "../use-wrap-async";
import type { GalleryBarImplProps } from "./BarImpl";
import { GalleryItemsHeaderAdapter, GalleryItemsSummary } from "./ListHeader";

/**
 * Derived UI state backing the gallery when it is in "people" mode.
 *
 * This may be different from the actual underlying state since there might be
 * unsynced data (hidden or deleted that have not yet been synced with remote)
 * that should be taken into account for the UI state.
 */
export interface GalleryPeopleState {
    /**
     * The currently selected person, if any.
     *
     * Whenever this is present, it is guaranteed to be one of the items from
     * within {@link people}.
     */
    activePerson: Person | undefined;
    /**
     * The list of people to show.
     */
    people: Person[];
}

type PeopleHeaderProps = Pick<
    GalleryBarImplProps,
    "people" | "onSelectPerson"
> & {
    person: Person;
};

export const PeopleHeader: React.FC<PeopleHeaderProps> = ({
    people,
    onSelectPerson,
    person,
}) => {
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
                {person.type == "cgroup" ? (
                    <CGroupPersonOptions
                        cgroup={person.cgroup}
                        {...{ onSelectPerson }}
                    />
                ) : (
                    <ClusterPersonOptions
                        cluster={person.cluster}
                        {...{ people }}
                    />
                )}
            </SpaceBetweenFlex>
        </GalleryItemsHeaderAdapter>
    );
};

type CGroupPersonOptionsProps = Pick<PeopleHeaderProps, "onSelectPerson"> & {
    cgroup: CGroup;
};

const CGroupPersonOptions: React.FC<CGroupPersonOptionsProps> = ({
    cgroup,
    onSelectPerson,
}) => {
    const { setDialogBoxAttributesV2 } = useAppContext();

    const [openAddNameInput, setOpenAddNameInput] = useState(false);

    const handleRenamePerson = () => setOpenAddNameInput(true);

    const renamePersonUsingName = useWrapAsyncOperation((name: string) =>
        renameCGroup(cgroup, name),
    );

    const handleDeletePerson = () =>
        setDialogBoxAttributesV2({
            title: pt("Reset person?"),
            content: pt(
                "The name, face groupings and suggestions for this person will be reset",
            ),
            close: { text: t("cancel") },
            proceed: {
                text: t("reset"),
                action: deletePerson,
            },
            buttonDirection: "row",
        });

    const deletePerson = useWrapAsyncOperation(async () => {
        await deleteCGroup(cgroup);
        // Reset the selection to the default state.
        onSelectPerson(undefined);
    });

    return (
        <>
            <OverflowMenu
                ariaControls={"person-options"}
                triggerButtonIcon={<MoreHoriz />}
            >
                <OverflowMenuOption
                    startIcon={<EditIcon />}
                    centerAlign
                    onClick={handleRenamePerson}
                >
                    {t("rename")}
                </OverflowMenuOption>
                <OverflowMenuOption
                    startIcon={<ClearIcon />}
                    centerAlign
                    onClick={handleDeletePerson}
                >
                    {pt("Reset")}
                </OverflowMenuOption>
            </OverflowMenu>

            <SingleInputDialog
                open={openAddNameInput}
                onClose={() => setOpenAddNameInput(false)}
                title={pt("Rename person") /* TODO-Cluster pt()'s */}
                label={pt("Name")}
                placeholder={t("enter_name")}
                autoComplete="name"
                autoFocus
                initialValue={cgroup.data.name ?? ""}
                submitButtonTitle={t("rename")}
                onSubmit={renamePersonUsingName}
            />
        </>
    );
};

type ClusterPersonOptionsProps = Pick<PeopleHeaderProps, "people"> & {
    cluster: FaceCluster;
};

const ClusterPersonOptions: React.FC<ClusterPersonOptionsProps> = ({
    people,
    cluster,
}) => {
    const { startLoading, finishLoading } = useAppContext();

    const [openNameInput, setOpenNameInput] = useState(false);
    const [openAddPersonDialog, setOpenAddPersonDialog] = useState(false);

    const handleAddPerson = () => {
        // TODO-Cluster
        if (process.env.NEXT_PUBLIC_ENTE_WIP_CL) {
            // WIP path
            setOpenAddPersonDialog(true);
        } else {
            // Existing path
            setOpenNameInput(true);
        }
    };

    // TODO-Cluster
    const addPersonWithName = async (name: string) => {
        startLoading();
        try {
            await addCGroup(name, cluster);
        } finally {
            finishLoading();
        }
    };

    return (
        <>
            <Stack direction="row" sx={{ alignItems: "center", gap: 2 }}>
                <Tooltip title={pt("Add a name")}>
                    <IconButton onClick={handleAddPerson}>
                        <AddIcon />
                    </IconButton>
                </Tooltip>

                <OverflowMenu
                    ariaControls={"person-options"}
                    triggerButtonIcon={<MoreHoriz />}
                >
                    <OverflowMenuOption
                        startIcon={<AddIcon />}
                        centerAlign
                        onClick={handleAddPerson}
                    >
                        {pt("Add a name")}
                    </OverflowMenuOption>
                </OverflowMenu>
            </Stack>

            <NameInputDialog
                open={openNameInput}
                onClose={() => setOpenNameInput(false)}
                title={pt("Add person") /* TODO-Cluster */}
                placeholder={t("enter_name")}
                initialValue={""}
                submitButtonTitle={t("add")}
                onSubmit={addPersonWithName}
            />

            <AddPersonDialog
                open={openAddPersonDialog}
                onClose={() => setOpenAddPersonDialog(false)}
                {...{ people, cluster }}
            />
        </>
    );
};
