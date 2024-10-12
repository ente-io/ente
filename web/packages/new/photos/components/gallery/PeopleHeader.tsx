import {
    useModalVisibility,
    type ModalVisibilityProps,
} from "@/base/components/utils/modal";
import { useIsSmallWidth } from "@/base/hooks";
import { pt } from "@/base/i18n";
import { deleteCGroup, renameCGroup } from "@/new/photos/services/ml";
import {
    type CGroupPerson,
    type ClusterPerson,
    type Person,
} from "@/new/photos/services/ml/people";
import OverflowMenu from "@ente/shared/components/OverflowMenu/menu";
import { OverflowMenuOption } from "@ente/shared/components/OverflowMenu/option";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import ListAltOutlined from "@mui/icons-material/ListAltOutlined";
import MoreHoriz from "@mui/icons-material/MoreHoriz";
import {
    Dialog,
    DialogContent,
    DialogTitle,
    IconButton,
    Stack,
    Tooltip,
} from "@mui/material";
import { ClearIcon } from "@mui/x-date-pickers";
import { t } from "i18next";
import React from "react";
import { useAppContext } from "../../types/context";
import { AddPersonDialog } from "../AddPersonDialog";
import { SpaceBetweenFlex } from "../mui";
import { SingleInputDialog } from "../SingleInputForm";
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
                        {...{ onSelectPerson }}
                    />
                ) : (
                    <ClusterPersonHeader person={person} {...{ people }} />
                )}
            </SpaceBetweenFlex>
        </GalleryItemsHeaderAdapter>
    );
};

type CGroupPersonHeaderProps = Pick<PeopleHeaderProps, "onSelectPerson"> & {
    person: CGroupPerson;
};

const CGroupPersonHeader: React.FC<CGroupPersonHeaderProps> = ({
    person,
    onSelectPerson,
}) => {
    const cgroup = person.cgroup;

    const { showMiniDialog } = useAppContext();

    const { show: showNameInput, props: nameInputVisibilityProps } =
        useModalVisibility();
    const { show: showSuggestions, props: suggestionsVisibilityProps } =
        useModalVisibility();

    const handleRename = (name: string) => renameCGroup(cgroup, name);

    const handleReset = () =>
        showMiniDialog({
            title: pt("Reset person?"),
            message: pt(
                "The name, face groupings and suggestions for this person will be reset",
            ),
            continue: {
                text: t("reset"),
                color: "primary",
                action: async () => {
                    await deleteCGroup(cgroup);
                    // Reset the selection to the default state.
                    onSelectPerson(undefined);
                },
            },
        });

    // While technically it is possible for the cgroup not to have a name, logic
    // wise we shouldn't be ending up here without a name.
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
                    onClick={handleReset}
                >
                    {pt("Reset")}
                </OverflowMenuOption>
                {process.env.NEXT_PUBLIC_ENTE_WIP_CL /* TODO-Cluster */ && (
                    <OverflowMenuOption
                        startIcon={<ListAltOutlined />}
                        centerAlign
                        onClick={showSuggestions}
                    >
                        {pt("Review suggestions")}
                    </OverflowMenuOption>
                )}
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

            <SuggestionsDialog
                {...suggestionsVisibilityProps}
                {...{ person }}
            />
        </>
    );
};

type ClusterPersonHeaderProps = Pick<PeopleHeaderProps, "people"> & {
    person: ClusterPerson;
};

const ClusterPersonHeader: React.FC<ClusterPersonHeaderProps> = ({
    people,
    person,
}) => {
    const cluster = person.cluster;

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

type SuggestionsDialogProps = ModalVisibilityProps & {
    person: CGroupPerson;
};

const SuggestionsDialog: React.FC<SuggestionsDialogProps> = ({
    person,
    ...rest
}) => {
    const isSmallWidth = useIsSmallWidth();

    console.log(person);
    return (
        <Dialog
            {...rest}
            maxWidth="sm"
            fullWidth
            fullScreen={isSmallWidth}
            PaperProps={{ sx: { minHeight: "60svh" } }}
        >
            <DialogTitle sx={{ "&&&": { pt: "20px" } }}>
                {pt(`${person.name}?`)}
            </DialogTitle>
            <DialogContent>Test</DialogContent>
        </Dialog>
    );
};
