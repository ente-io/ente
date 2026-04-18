import {
    Dialog,
    DialogContent,
    DialogTitle,
    styled,
    Typography,
    useMediaQuery,
} from "@mui/material";
import { SpacedRow } from "ente-base/components/containers";
import { DialogCloseIconButton } from "ente-base/components/mui/DialogCloseIconButton";
import type { ModalVisibilityProps } from "ente-base/components/utils/modal";
import type { Person } from "ente-new/photos/services/ml/people";
import React from "react";
import { ItemCard, LargeTileButton, LargeTileTextOverlay } from "./Tiles";

export type AssignPersonDialogProps = ModalVisibilityProps & {
    /**
     * Existing named people that can be selected.
     */
    people: Person[];
    /**
     * Title to show on the dialog.
     */
    title: string;
    /**
     * Called when the user selects a person.
     */
    onSelectPerson: (personID: string) => void;
};

/**
 * A dialog that allows selecting an existing person (cgroup) to associate
 * something (e.g. file(s)) with.
 */
export const AssignPersonDialog: React.FC<AssignPersonDialogProps> = ({
    open,
    onClose,
    people,
    title,
    onSelectPerson,
}) => {
    const isFullScreen = useMediaQuery("(max-width: 490px)");

    return (
        <Dialog
            {...{ open, onClose }}
            fullWidth
            fullScreen={isFullScreen}
            slotProps={{ paper: { sx: { maxWidth: "490px" } } }}
        >
            <SpacedRow sx={{ padding: "10px 8px 6px 0" }}>
                <DialogTitle variant="h3">{title}</DialogTitle>
                <DialogCloseIconButton {...{ onClose }} />
            </SpacedRow>
            <DialogContent_>
                {people.map((person) => (
                    <ItemCard
                        key={person.id}
                        TileComponent={LargeTileButton}
                        coverFile={person.displayFaceFile}
                        coverFaceID={person.displayFaceID}
                        onClick={() => onSelectPerson(person.id)}
                    >
                        <LargeTileTextOverlay>
                            <Typography>{person.name ?? ""}</Typography>
                        </LargeTileTextOverlay>
                    </ItemCard>
                ))}
            </DialogContent_>
        </Dialog>
    );
};

const DialogContent_ = styled(DialogContent)`
    display: flex;
    flex-wrap: wrap;
    gap: 4px;
`;
