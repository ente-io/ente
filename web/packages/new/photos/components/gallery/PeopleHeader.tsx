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
import CheckIcon from "@mui/icons-material/Check";
import ClearIcon from "@mui/icons-material/Clear";
import EditIcon from "@mui/icons-material/Edit";
import ListAltOutlined from "@mui/icons-material/ListAltOutlined";
import MoreHoriz from "@mui/icons-material/MoreHoriz";
import {
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    IconButton,
    List,
    ListItem,
    Stack,
    ToggleButton,
    ToggleButtonGroup,
    Tooltip,
    Typography,
} from "@mui/material";
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
                title={
                    pt("Rename person") /* TODO-Cluster pt()'s
                    also remove "UNIDENTIFIED_FACES": "Unidentified faces" */
                }
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
    /**
     * This is a workaround for the lack of stable identity of the person prop
     * passed to the dialog (on which we trigger the suggestion computation.)
     */
    personID: string | undefined;
    /**
     * True if "fetching" failed.
     */
    fetchFailed: boolean;
    /**
     * List of clusters (suitably augmented for the UI display) which might
     * belong to the person, and being offered to the user as suggestions.
     */
    suggestions: PersonSuggestion[];
    /**
     * An entry corresponding to each clusters (suggestions) that the user has
     * either explicitly accepted or rejected.
     */
    markedSuggestionIDs: Map<string, NonNullable<SuggestionMark>>;
}

type SuggestionMark = "yes" | "no" | undefined;

type SuggestionsDialogAction =
    | { type: "fetch"; personID: string }
    | { type: "fetchFailed"; personID: string }
    | { type: "fetched"; personID: string; suggestions: PersonSuggestion[] }
    | { type: "mark"; suggestion: PersonSuggestion; value: SuggestionMark }
    | { type: "save" }
    | { type: "close" };

const initialSuggestionsDialogState: SuggestionsDialogState = {
    activity: undefined,
    personID: undefined,
    fetchFailed: false,
    suggestions: [],
    markedSuggestionIDs: new Map(),
};

const suggestionsDialogReducer = (
    state: SuggestionsDialogState,
    action: SuggestionsDialogAction,
): SuggestionsDialogState => {
    switch (action.type) {
        case "fetch":
            return {
                activity: "fetching",
                personID: action.personID,
                fetchFailed: false,
                suggestions: [],
                markedSuggestionIDs: new Map(),
            };
        case "fetchFailed":
            if (action.personID != state.personID) return state;
            return { ...state, activity: undefined, fetchFailed: true };
        case "fetched":
            if (action.personID != state.personID) return state;
            return {
                ...state,
                activity: undefined,
                suggestions: action.suggestions,
            };
        case "mark": {
            const markedSuggestionIDs = new Map(state.markedSuggestionIDs);
            const id = action.suggestion.id;
            if (action.value == "yes" || action.value == "no") {
                markedSuggestionIDs.set(id, action.value);
            } else {
                markedSuggestionIDs.delete(id);
            }
            return {
                ...state,
                markedSuggestionIDs,
            };
        }
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

    const isSmallWidth = useIsSmallWidth();

    const hasUnsavedChanges = state.markedSuggestionIDs.size > 0;

    const resetPersonAndClose = () => {
        dispatch({ type: "close" });
        onClose();
    };

    useEffect(() => {
        if (!open) return;

        // Avoid recomputing when the person object changes without its identity
        // changing. This is a workaround, a better fix would be to fix upstream
        // to guarantee a stable identity of the person object itself.
        const personID = person.id;
        if (person.id == state.personID) return;

        dispatch({ type: "fetch", personID });

        const go = async () => {
            try {
                const suggestions = await suggestionsForPerson(person);
                dispatch({ type: "fetched", personID, suggestions });
            } catch (e) {
                log.error("Failed to generate suggestions", e);
                dispatch({ type: "fetchFailed", personID });
            }
        };

        void go();
    }, [open, person, state.personID]);

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

    const handleMark = (suggestion: PersonSuggestion, value: SuggestionMark) =>
        dispatch({ type: "mark", suggestion, value });

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
                {person.name && pt(`${person.name}?`)}
            </DialogTitle>
            <DialogContent dividers sx={{ display: "flex" }}>
                {state.activity == "fetching" ? (
                    <CenteredBox>
                        <ActivityIndicator>
                            {pt("Finding similar faces...")}
                        </ActivityIndicator>
                    </CenteredBox>
                ) : state.fetchFailed ? (
                    <CenteredBox>
                        <ErrorIndicator />
                    </CenteredBox>
                ) : state.suggestions.length == 0 ? (
                    <CenteredBox>
                        <Typography
                            color="text.muted"
                            sx={{ textAlign: "center" }}
                        >
                            {pt("No more suggestions for now")}
                        </Typography>
                    </CenteredBox>
                ) : (
                    <SuggestionsList
                        suggestions={state.suggestions}
                        markedSuggestionIDs={state.markedSuggestionIDs}
                        onMarkSuggestion={handleMark}
                    />
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
                    loading={state.activity == "saving"}
                    color={"accent"}
                    onClick={handleSave}
                >
                    {t("save")}
                </LoadingButton>
            </DialogActions>
        </Dialog>
    );
};

type SuggestionsListProps = Pick<
    SuggestionsDialogState,
    "suggestions" | "markedSuggestionIDs"
> & {
    /**
     * Callback invoked when the user toggles the value associated with the
     * given suggestion.
     */
    onMarkSuggestion: (
        suggestion: PersonSuggestion,
        value: SuggestionMark,
    ) => void;
};

const SuggestionsList: React.FC<SuggestionsListProps> = ({
    suggestions,
    markedSuggestionIDs,
    onMarkSuggestion,
}) => (
    <List sx={{ width: "100%" }}>
        {suggestions.map((suggestion) => (
            <ListItem
                sx={{
                    paddingInline: 0,
                    justifyContent: "space-between",
                }}
                key={suggestion.id}
            >
                <Typography>{`${suggestion.previewFaces.length} faces ntaoheu naoehtu aosnehu asoenuh aoenuht`}</Typography>
                <ToggleButtonGroup
                    value={markedSuggestionIDs.get(suggestion.id)}
                    exclusive
                    onChange={(_, v) =>
                        onMarkSuggestion(
                            suggestion,
                            // Dance for TypeScript to recognize the type.
                            v == "yes" ? "yes" : v == "no" ? "no" : undefined,
                        )
                    }
                >
                    <ToggleButton value="yes" aria-label={pt("Yes")}>
                        <CheckIcon />
                    </ToggleButton>
                    <ToggleButton value="no" aria-label={t("no")}>
                        <ClearIcon />
                    </ToggleButton>
                </ToggleButtonGroup>
            </ListItem>
        ))}
    </List>
);
