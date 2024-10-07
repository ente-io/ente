import { pt } from "@/base/i18n";
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
import type { CollectionSummary } from "../services/collection/ui";
import { SpaceBetweenFlex, type ButtonishProps } from "./mui";
import {
    DialogCloseIconButton,
    type DialogVisibilityProps,
} from "./mui/Dialog";
import { NameInputDialog } from "./NameInputDialog";
import {
    ItemCard,
    LargeTileButton,
    LargeTilePlusOverlay,
    LargeTileTextOverlay,
} from "./Tiles";

type PeopleSelectorProps = DialogVisibilityProps;

export const PeopleSelector: React.FC<PeopleSelectorProps> = ({
    open,
    onClose,
}) => {
    const isFullScreen = useMediaQuery("(max-width: 490px)");

    const [openNameInput, setOpenNameInput] = useState(false);

    const filteredCollections: CollectionSummary[] = [];

    const handleAddPerson = () => {
        console.log("handleAddPerson");
        setOpenNameInput(true);
    };

    const handleSelectPerson = (id: string) => {
        console.log("handleSelectPerson", id);
    };

    const handleAddPersonWithName = (name: string) => {
        console.log("handleAddPersonWithName", name);
    };

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
                    {filteredCollections.map((person) => (
                        <PersonButton
                            key={person.id}
                            person={person}
                            onPersonClick={handleSelectPerson}
                        />
                    ))}
                </DialogContent_>
            </Dialog>

            <NameInputDialog
                open={openNameInput}
                onClose={() => setOpenNameInput(false)}
                title={pt("New person") /* TODO-Cluster */}
                placeholder={t("enter_name")}
                initialValue={""}
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
    person: CollectionSummary;
    onPersonClick: (personID: string) => void;
}

const PersonButton: React.FC<PersonButtonProps> = ({
    person,
    onPersonClick,
}) => (
    <ItemCard
        TileComponent={LargeTileButton}
        // coverFile={collectionSummary.coverFile}
        onClick={() => onPersonClick(person.id.toString())}
    >
        <LargeTileTextOverlay>
            <Typography>{person.name}</Typography>
        </LargeTileTextOverlay>
    </ItemCard>
);

const AddPerson: React.FC<ButtonishProps> = ({ onClick }) => (
    <ItemCard TileComponent={LargeTileButton} onClick={onClick}>
        <LargeTileTextOverlay>{t("New person")}</LargeTileTextOverlay>
        <LargeTilePlusOverlay>+</LargeTilePlusOverlay>
    </ItemCard>
);
