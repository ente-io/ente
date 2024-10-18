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
    addCGroup,
    addClusterToCGroup,
    applyPersonSuggestionUpdates,
    deleteCGroup,
    ignoreCluster,
    renameCGroup,
    suggestionsAndChoicesForPerson,
} from "@/new/photos/services/ml";
import {
    type CGroupPerson,
    type ClusterPerson,
    type Person,
    type PersonSuggestionsAndChoices,
    type PersonSuggestionUpdates,
    type PreviewableCluster,
} from "@/new/photos/services/ml/people";
import { ensure } from "@/utils/ensure";
import OverflowMenu from "@ente/shared/components/OverflowMenu/menu";
import { OverflowMenuOption } from "@ente/shared/components/OverflowMenu/option";
import AddIcon from "@mui/icons-material/Add";
import CheckIcon from "@mui/icons-material/Check";
import ClearIcon from "@mui/icons-material/Clear";
import EditIcon from "@mui/icons-material/Edit";
import HideImageOutlinedIcon from "@mui/icons-material/HideImageOutlined";
import ListAltOutlinedIcon from "@mui/icons-material/ListAltOutlined";
import MoreHorizIcon from "@mui/icons-material/MoreHoriz";
import RestoreIcon from "@mui/icons-material/Restore";
import {
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    IconButton,
    List,
    ListItem,
    Stack,
    styled,
    ToggleButton,
    ToggleButtonGroup,
    Tooltip,
    Typography,
    useMediaQuery,
} from "@mui/material";
import { t } from "i18next";
import React, { useEffect, useReducer, useState } from "react";
import type { FaceCluster } from "../../services/ml/cluster";
import { useAppContext } from "../../types/context";
import { SpaceBetweenFlex, type ButtonishProps } from "../mui";
import { DialogCloseIconButton } from "../mui/Dialog";
import { SuggestionFaceList } from "../PeopleList";
import { SingleInputDialog } from "../SingleInputForm";
import {
    ItemCard,
    LargeTileButton,
    LargeTilePlusOverlay,
    LargeTileTextOverlay,
} from "../Tiles";
import { useWrapAsyncOperation } from "../utils/use-wrap-async";
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
    // wise we shouldn't be ending up here without a name (this state is
    // expected to be reached only for named persons).
    const name = cgroup.data.name ?? "";

    return (
        <>
            <GalleryItemsSummary
                name={name}
                fileCount={person.fileIDs.length}
            />
            <OverflowMenu
                ariaControls={"person-options"}
                triggerButtonIcon={<MoreHorizIcon />}
            >
                <OverflowMenuOption
                    startIcon={<ListAltOutlinedIcon />}
                    centerAlign
                    onClick={showSuggestions}
                >
                    {pt("Review suggestions")}
                </OverflowMenuOption>
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

    const { showMiniDialog } = useAppContext();

    const { show: showAddPerson, props: addPersonVisibilityProps } =
        useModalVisibility();

    const confirmIgnore = () =>
        showMiniDialog({
            title: pt("Ignore person?"),
            message: pt(
                "This face grouping will not be shown in the people list",
            ),
            continue: {
                text: pt("Ignore"),
                color: "primary",
                action: () => ignoreCluster(cluster),
            },
        });

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
                    triggerButtonIcon={<MoreHorizIcon />}
                >
                    <OverflowMenuOption
                        startIcon={<AddIcon />}
                        centerAlign
                        onClick={showAddPerson}
                    >
                        {pt("Add a name")}
                    </OverflowMenuOption>
                    <OverflowMenuOption
                        startIcon={<HideImageOutlinedIcon />}
                        centerAlign
                        onClick={confirmIgnore}
                    >
                        {pt("Ignore")}
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

type AddPersonDialogProps = ModalVisibilityProps & {
    /**
     * The list of people from show the existing named people.
     */
    people: Person[];
    /**
     * The cluster to add to the selected person (existing or new).
     */
    cluster: FaceCluster;
};

/**
 * A dialog allowing the user to select one of the existing named persons they
 * have, or create a new one, and then associate the provided cluster to it,
 * creating or updating a remote "person".
 */
const AddPersonDialog: React.FC<AddPersonDialogProps> = ({
    open,
    onClose,
    people,
    cluster,
}) => {
    const isFullScreen = useMediaQuery("(max-width: 490px)");

    const [openNameInput, setOpenNameInput] = useState(false);

    const cgroupPeople: CGroupPerson[] = people.filter(
        (p) => p.type != "cluster",
    );

    const handleAddPerson = () => setOpenNameInput(true);

    const handleSelectPerson = useWrapAsyncOperation((id: string) =>
        addClusterToCGroup(
            ensure(cgroupPeople.find((p) => p.id == id)).cgroup,
            cluster,
        ),
    );

    const handleAddPersonWithName = (name: string) => addCGroup(name, cluster);

    // [Note: Calling setState during rendering]
    //
    // Calling setState during rendering should be avoided when there are
    // cleaner alternatives, but it is not completely verboten, and it has
    // documented semantics:
    //
    // > React will discard the currently rendering component's output and
    // > immediately attempt to render it again with the new state.
    // >
    // > https://react.dev/reference/react/useState

    // If we're opened without any existing people that can be selected, jump
    // directly to the add person dialog.
    if (open && !openNameInput && !cgroupPeople.length) {
        onClose();
        setOpenNameInput(true);
        return <></>;
    }

    return (
        <>
            <Dialog
                {...{ open, onClose }}
                fullWidth
                fullScreen={isFullScreen}
                PaperProps={{ sx: { maxWidth: "490px" } }}
            >
                <SpaceBetweenFlex sx={{ padding: "10px 8px 6px 0" }}>
                    <DialogTitle variant="h3" fontWeight={"bold"}>
                        {pt("Add name")}
                    </DialogTitle>
                    <DialogCloseIconButton {...{ onClose }} />
                </SpaceBetweenFlex>
                <DialogContent_>
                    <AddPerson onClick={handleAddPerson} />
                    {cgroupPeople.map((person) => (
                        <PersonButton
                            key={person.id}
                            person={person}
                            onPersonClick={handleSelectPerson}
                        />
                    ))}
                </DialogContent_>
            </Dialog>

            <SingleInputDialog
                open={openNameInput}
                onClose={() => setOpenNameInput(false)}
                title={pt("New person") /* TODO-Cluster */}
                label={pt("Add name")}
                placeholder={t("enter_name")}
                autoComplete="name"
                autoFocus
                submitButtonTitle={t("add")}
                onSubmit={handleAddPersonWithName}
            />
        </>
    );
};

const DialogContent_ = styled(DialogContent)`
    display: flex;
    flex-wrap: wrap;
    gap: 4px;
`;

interface PersonButtonProps {
    person: Person;
    onPersonClick: (personID: string) => void;
}

const PersonButton: React.FC<PersonButtonProps> = ({
    person,
    onPersonClick,
}) => (
    <ItemCard
        TileComponent={LargeTileButton}
        coverFile={person.displayFaceFile}
        coverFaceID={person.displayFaceID}
        onClick={() => onPersonClick(person.id)}
    >
        <LargeTileTextOverlay>
            <Typography>{person.name ?? ""}</Typography>
        </LargeTileTextOverlay>
    </ItemCard>
);

const AddPerson: React.FC<ButtonishProps> = ({ onClick }) => (
    <ItemCard TileComponent={LargeTileButton} onClick={onClick}>
        <LargeTileTextOverlay>{pt("New person")}</LargeTileTextOverlay>
        <LargeTilePlusOverlay>+</LargeTilePlusOverlay>
    </ItemCard>
);

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
     * True if we should show the previously saved choice view instead of the
     * new suggestions.
     */
    showChoices: boolean;
    /** Fetched choices. */
    choices: SCItem[];
    /** Fetched suggestions. */
    suggestions: SCItem[];
    /**
     * An entry corresponding to each
     * - saved choice for which the user has changed their mind.
     * - suggestion that the user has either explicitly assigned or rejected.
     */
    updates: PersonSuggestionUpdates;
}

type SCItem = PreviewableCluster & { fixed?: boolean; assigned?: boolean };

type SuggestionsDialogAction =
    | { type: "fetch"; personID: string }
    | { type: "fetchFailed"; personID: string }
    | {
          type: "fetched";
          personID: string;
          suggestionsAndChoices: PersonSuggestionsAndChoices;
      }
    | { type: "updateItem"; item: SCItem; value: boolean | undefined }
    | { type: "save" }
    | { type: "toggleHistory" }
    | { type: "close" };

const initialSuggestionsDialogState: SuggestionsDialogState = {
    activity: undefined,
    personID: undefined,
    fetchFailed: false,
    showChoices: false,
    choices: [],
    suggestions: [],
    updates: new Map(),
};

const suggestionsDialogReducer = (
    state: SuggestionsDialogState,
    action: SuggestionsDialogAction,
): SuggestionsDialogState => {
    switch (action.type) {
        case "fetch":
            return {
                ...initialSuggestionsDialogState,
                choices: [],
                suggestions: [],
                updates: new Map(),
                activity: "fetching",
                personID: action.personID,
            };
        case "fetchFailed":
            if (action.personID != state.personID) return state;
            return { ...state, activity: undefined, fetchFailed: true };
        case "fetched":
            if (action.personID != state.personID) return state;
            return {
                ...state,
                activity: undefined,
                choices: action.suggestionsAndChoices.choices,
                suggestions: action.suggestionsAndChoices.suggestions,
            };
        case "updateItem": {
            const updates = new Map(state.updates);
            const { item, value } = action;
            if (item.assigned === undefined && value === undefined) {
                // If this was a suggestion, prune previous updates since the
                // use has toggled the item back to its original unset state.
                updates.delete(item.id);
            } else if (item.assigned !== undefined && value === item.assigned) {
                // If this is a choice, prune updates which match the choice's
                // original assigned state.
                updates.delete(item.id);
            } else {
                updates.set(item.id, value);
            }
            return { ...state, updates };
        }
        case "toggleHistory":
            return { ...state, showChoices: !state.showChoices };
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

    const hasUnsavedChanges = state.updates.size > 0;

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
                const suggestionsAndChoices =
                    await suggestionsAndChoicesForPerson(person);
                dispatch({ type: "fetched", personID, suggestionsAndChoices });
            } catch (e) {
                log.error("Failed to fetch suggestions and choices", e);
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

    const handleUpdateItem = (item: SCItem, value: boolean | undefined) =>
        dispatch({ type: "updateItem", item, value });

    const handleSave = async () => {
        dispatch({ type: "save" });
        try {
            await applyPersonSuggestionUpdates(person.cgroup, state.updates);
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
            <SpaceBetweenFlex
                sx={{
                    padding: "20px 16px 16px 16px",
                    backgroundColor: state.showChoices
                        ? (theme) => theme.colors.fill.faint
                        : "transparent",
                }}
            >
                <Stack sx={{ gap: "8px" }}>
                    <DialogTitle sx={{ "&&&": { p: 0 } }}>
                        {state.showChoices
                            ? pt("Saved choices")
                            : pt("Review suggestions")}
                    </DialogTitle>
                    <Typography color="text.muted">
                        {person.name ?? " "}
                    </Typography>
                </Stack>
                {state.choices.length > 1 && (
                    <IconButton
                        disableTouchRipple
                        onClick={() => dispatch({ type: "toggleHistory" })}
                        aria-label={
                            !state.showChoices
                                ? pt("Saved suggestions")
                                : pt("Review suggestions")
                        }
                        sx={{
                            backgroundColor: state.showChoices
                                ? (theme) => theme.colors.fill.muted
                                : "transparent",
                        }}
                    >
                        <RestoreIcon />
                    </IconButton>
                )}
            </SpaceBetweenFlex>
            <DialogContent
                /* Reset scroll position on switching view */
                key={`${state.showChoices}`}
                sx={{ display: "flex", "&&&": { pt: 0 } }}
            >
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
                ) : state.showChoices ? (
                    <SuggestionOrChoiceList
                        items={state.choices}
                        updates={state.updates}
                        onUpdateItem={handleUpdateItem}
                    />
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
                    <SuggestionOrChoiceList
                        items={state.suggestions}
                        updates={state.updates}
                        onUpdateItem={handleUpdateItem}
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

interface SuggestionOrChoiceListProps {
    items: SCItem[];
    updates: PersonSuggestionUpdates;
    /**
     * Callback invoked when the user changes the value associated with the
     * given suggestion or choice.
     */
    onUpdateItem: (item: SCItem, value: boolean | undefined) => void;
}

const SuggestionOrChoiceList: React.FC<SuggestionOrChoiceListProps> = ({
    items,
    updates,
    onUpdateItem,
}) => (
    <List dense sx={{ width: "100%" }}>
        {items.map((item) => (
            <ListItem
                key={item.id}
                sx={{
                    paddingInline: 0,
                    paddingBlockEnd: "24px",
                    justifyContent: "space-between",
                }}
            >
                <Stack sx={{ gap: "10px" }}>
                    <Typography variant="small" color="text.muted">
                        {/* Use the face count as as stand-in for the photo count */}
                        {t("photos_count", { count: item.faces.length })}
                    </Typography>
                    <SuggestionFaceList faces={item.previewFaces} />
                </Stack>
                {!item.fixed && (
                    <ToggleButtonGroup
                        value={fromItemValue(item, updates)}
                        exclusive
                        onChange={(_, v) => onUpdateItem(item, toItemValue(v))}
                    >
                        <ToggleButton value="no" aria-label={t("no")}>
                            <ClearIcon />
                        </ToggleButton>
                        <ToggleButton value="yes" aria-label={pt("Yes")}>
                            <CheckIcon />
                        </ToggleButton>
                    </ToggleButtonGroup>
                )}
            </ListItem>
        ))}
    </List>
);

const fromItemValue = (item: SCItem, updates: PersonSuggestionUpdates) => {
    // Use the in-memory state if available. For choices, fallback to their
    // original state.
    const resolved = updates.has(item.id)
        ? updates.get(item.id)
        : item.assigned;
    return resolved ? "yes" : resolved === false ? "no" : undefined;
};

const toItemValue = (v: unknown) =>
    // This dance is needed for TypeScript to recognize the type.
    v == "yes" ? true : v == "no" ? false : undefined;
