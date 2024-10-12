import type { ModalVisibilityProps } from "@/base/components/utils/modal";
import { pt } from "@/base/i18n";
import { addCGroup, addClusterToCGroup } from "@/new/photos/services/ml";
import { ensure } from "@/utils/ensure";
import {
    Dialog,
    DialogContent,
    DialogTitle,
    styled,
    Typography,
    useMediaQuery,
} from "@mui/material";
import { t } from "i18next";
import React, { useState } from "react";
import type { FaceCluster } from "../services/ml/cluster";
import type { CGroupPerson, Person } from "../services/ml/people";
import { SpaceBetweenFlex, type ButtonishProps } from "./mui";
import { DialogCloseIconButton } from "./mui/Dialog";
import { SingleInputDialog } from "./SingleInputForm";
import {
    ItemCard,
    LargeTileButton,
    LargeTilePlusOverlay,
    LargeTileTextOverlay,
} from "./Tiles";
import { useWrapAsyncOperation } from "./use-wrap-async";

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
export const AddPersonDialog: React.FC<AddPersonDialogProps> = ({
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
