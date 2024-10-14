import {
    ActivityIndicator,
    ErrorIndicator,
} from "@/base/components/mui/ActivityIndicator";
import { CenteredBox } from "@/base/components/mui/Container";
import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import { LoadingButton } from "@/base/components/mui/LoadingButton";
import {
    useModalVisibility,
    type ModalVisibilityProps,
} from "@/base/components/utils/modal";
import { useIsSmallWidth } from "@/base/hooks";
import { pt } from "@/base/i18n";
import log from "@/base/log";
import {
    deleteCGroup,
    renameCGroup,
    suggestionsForPerson,
} from "@/new/photos/services/ml";
import {
    type CGroupPerson,
    type ClusterPerson,
    type Person,
    type PersonSuggestion,
} from "@/new/photos/services/ml/people";
import { wait } from "@/utils/promise";
import OverflowMenu from "@ente/shared/components/OverflowMenu/menu";
import { OverflowMenuOption } from "@ente/shared/components/OverflowMenu/option";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import ListAltOutlined from "@mui/icons-material/ListAltOutlined";
import MoreHoriz from "@mui/icons-material/MoreHoriz";
import {
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    IconButton,
    Stack,
    Tooltip,
    Typography,
} from "@mui/material";
import { ClearIcon } from "@mui/x-date-pickers";
import { t } from "i18next";
import React, { useEffect, useReducer } from "react";
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

interface SuggestionsDialogState {
    activity: "fetching" | "saving" | undefined;
    fetchFailed: boolean;
    hasUnsavedChanges?: boolean;
    /**
     * This is a workaround for the lack of stable identity of the person prop.
     */
    personID: string | undefined;
    suggestions: PersonSuggestion[];
}

type SuggestionsDialogAction =
    | { type: "fetch"; personID: string }
    | { type: "fetchFailed" }
    | { type: "fetched"; suggestions: PersonSuggestion[] }
    | { type: "save" }
    | { type: "close" };

const initialSuggestionsDialogState: SuggestionsDialogState = {
    activity: undefined,
    personID: undefined,
    fetchFailed: false,
    hasUnsavedChanges: false,
    suggestions: [],
};

const suggestionsDialogReducer = (
    state: SuggestionsDialogState,
    action: SuggestionsDialogAction,
): SuggestionsDialogState => {
    switch (action.type) {
        case "fetch":
            return {
                ...state,
                activity: "fetching",
                fetchFailed: false,
                hasUnsavedChanges: false,
                personID: action.personID,
            };
        case "fetchFailed":
            return { ...state, fetchFailed: true };
        case "fetched":
            return {
                ...state,
                activity: undefined,
                suggestions: action.suggestions,
            };
        case "save":
            return { ...state, activity: "saving" };
        case "close":
            // Reset the person ID when closing the dialog so that the
            // suggestions are recomputed the next time the dialog is reopened
            // (even for the same person).
            //
            // We cannot reset the suggestions themselves since they would cause
            // the dialog to lose its visual state during the closing animation.
            return { ...state, personID: undefined };
    }
};

const SuggestionsDialog: React.FC<SuggestionsDialogProps> = ({
    open,
    onClose,
    person,
}) => {
    const { showMiniDialog, onGenericError } = useAppContext();

    const [state, dispatch] = useReducer(
        suggestionsDialogReducer,
        initialSuggestionsDialogState,
    );

    const { activity, personID, fetchFailed, hasUnsavedChanges, suggestions } =
        state;

    const isSmallWidth = useIsSmallWidth();

    const resetPersonAndClose = () => {
        dispatch({ type: "close" });
        onClose();
    };

    const handleClose = () => {
        if (hasUnsavedChanges) {
            showMiniDialog({
                message: pt(
                    "You have unsaved changes. These will be lost if you close without saving",
                ),
                continue: {
                    text: pt("Discard changes"),
                    color: "critical",
                    action: resetPersonAndClose,
                },
            });

            return;
        }

        resetPersonAndClose();
    };

    const handleSave = async () => {
        try {
            // TODO-Cluster
            // await attributes.continue?.action?.();
            await wait(3000);
            resetPersonAndClose();
        } catch (e) {
            log.error("Failed to save suggestion review", e);
            onGenericError(e);
        }
    };

    useEffect(() => {
        if (!open) return;

        // Avoid recomputing when the person object changes without its identity
        // changing. This is a workaround, a better fix would be to fix upstream
        // to guarantee a stable identity of the person object itself.
        if (person.id == personID) return;

        dispatch({ type: "fetch", personID: person.id });

        let ignore = false;

        const go = async () => {
            try {
                const suggestions = await suggestionsForPerson(person);
                if (!ignore) {
                    dispatch({ type: "fetched", suggestions });
                }
            } catch (e) {
                log.error("Failed to generate suggestions", e);
                if (!ignore) {
                    dispatch({ type: "fetchFailed" });
                }
            }
        };

        void go();

        return () => {
            ignore = true;
        };
    }, [open, person, personID]);

    console.log({ open, person });

    return (
        <Dialog
            open={open}
            onClose={handleClose}
            maxWidth="sm"
            fullWidth
            fullScreen={isSmallWidth}
            PaperProps={{ sx: { minHeight: "80svh" } }}
        >
            <DialogTitle sx={{ "&&&": { py: "20px" } }}>
                {pt(`${person.name}?`)}
            </DialogTitle>
            <DialogContent dividers sx={{ display: "flex" }}>
                {activity == "fetching" ? (
                    <CenteredBox>
                        <ActivityIndicator>
                            {pt("Finding similar faces...")}
                        </ActivityIndicator>
                    </CenteredBox>
                ) : fetchFailed ? (
                    <CenteredBox>
                        <ErrorIndicator />
                    </CenteredBox>
                ) : suggestions.length == 0 ? (
                    <CenteredBox>
                        <Typography
                            color="text.muted"
                            sx={{ textAlign: "center" }}
                        >
                            {pt("No more suggestions for now")}
                        </Typography>
                    </CenteredBox>
                ) : (
                    <ul>
                        {suggestions.map((suggestion) => (
                            <li
                                key={suggestion.id}
                            >{`${suggestion.faces.length} faces`}</li>
                        ))}
                    </ul>
                )}
            </DialogContent>
            <DialogActions sx={{ "&&": { pt: "12px" } }}>
                <FocusVisibleButton
                    fullWidth
                    color="secondary"
                    onClick={handleClose}
                >
                    {t("close")}
                </FocusVisibleButton>
                <LoadingButton
                    fullWidth
                    disabled={!hasUnsavedChanges}
                    loading={activity == "saving"}
                    color={"accent"}
                    onClick={handleSave}
                >
                    {t("save")}
                </LoadingButton>
            </DialogActions>
        </Dialog>
    );
};
