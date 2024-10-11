import { useModalVisibility } from "@/base/components/utils/modal";
import { pt } from "@/base/i18n";
import { deleteCGroup, renameCGroup } from "@/new/photos/services/ml";
import { type Person } from "@/new/photos/services/ml/people";
import OverflowMenu from "@ente/shared/components/OverflowMenu/menu";
import { OverflowMenuOption } from "@ente/shared/components/OverflowMenu/option";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import MoreHoriz from "@mui/icons-material/MoreHoriz";
import { IconButton, Stack, Tooltip } from "@mui/material";
import { ClearIcon } from "@mui/x-date-pickers";
import { t } from "i18next";
import React from "react";
import type { FaceCluster } from "../../services/ml/cluster";
import type { CGroup } from "../../services/user-entity";
import { useAppContext } from "../../types/context";
import { AddPersonDialog } from "../AddPersonDialog";
import { SpaceBetweenFlex } from "../mui";
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
                {person.type == "cgroup" ? (
                    <CGroupPersonHeader
                        person={person}
                        cgroup={person.cgroup}
                        {...{ onSelectPerson }}
                    />
                ) : (
                    <ClusterPersonHeader
                        person={person}
                        cluster={person.cluster}
                        {...{ people }}
                    />
                )}
            </SpaceBetweenFlex>
        </GalleryItemsHeaderAdapter>
    );
};

type CGroupPersonHeaderProps = Pick<PeopleHeaderProps, "onSelectPerson"> & {
    person: Person;
    cgroup: CGroup;
};

const CGroupPersonHeader: React.FC<CGroupPersonHeaderProps> = ({
    person,
    cgroup,
    onSelectPerson,
}) => {
    const { showMiniDialog } = useAppContext();

    const { show: showNameInput, props: nameInputVisibilityProps } =
        useModalVisibility();

    const handleRename = useWrapAsyncOperation((name: string) =>
        renameCGroup(cgroup, name),
    );

    const handleDeletePerson = () =>
        showMiniDialog({
            title: pt("Reset person?"),
            message: pt(
                "The name, face groupings and suggestions for this person will be reset",
            ),
            continue: {
                text: t("reset"),
                color: "primary",
                action: deletePerson,
            },
        });

    const deletePerson = useWrapAsyncOperation(async () => {
        await deleteCGroup(cgroup);
        // Reset the selection to the default state.
        onSelectPerson(undefined);
    });

    // While technically it is possible for the cgroup not to have a name,
    // logical wise we shouldn't be ending up here without a name.
    const name = cgroup.data.name ?? "";

    return (
        <>
            <GalleryItemsSummary
                name={name}
                fileCount={person.fileIDs.length}
            />
            <OverflowMenu
                ariaControls={"person-options"}
                triggerButtonIcon={<MoreHoriz />}
            >
                <OverflowMenuOption
                    startIcon={<EditIcon />}
                    centerAlign
                    onClick={showNameInput}
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
                {...nameInputVisibilityProps}
                title={pt("Rename person") /* TODO-Cluster pt()'s */}
                label={pt("Name")}
                placeholder={t("enter_name")}
                autoComplete="name"
                autoFocus
                initialValue={name}
                submitButtonTitle={t("rename")}
                onSubmit={handleRename}
            />
        </>
    );
};

type ClusterPersonHeaderProps = Pick<PeopleHeaderProps, "people"> & {
    person: Person;
    cluster: FaceCluster;
};

const ClusterPersonHeader: React.FC<ClusterPersonHeaderProps> = ({
    people,
    person,
    cluster,
}) => {
    const { show: showAddPerson, props: addPersonVisibilityProps } =
        useModalVisibility();

    return (
        <>
            <GalleryItemsSummary
                name={pt("Unnamed person") /* TODO-Cluster */}
                nameProps={{ color: "text.muted" }}
                fileCount={person.fileIDs.length}
                onNameClick={showAddPerson}
            />
            <Stack direction="row" sx={{ alignItems: "center", gap: 2 }}>
                <Tooltip title={pt("Add a name")}>
                    <IconButton onClick={showAddPerson}>
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
                        onClick={showAddPerson}
                    >
                        {pt("Add a name")}
                    </OverflowMenuOption>
                </OverflowMenu>
            </Stack>

            <AddPersonDialog
                {...addPersonVisibilityProps}
                {...{ people, cluster }}
            />
        </>
    );
};
