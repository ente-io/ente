import React from "react";
import { useStaffSession } from "../services/session";
import {
    apiOrigin,
    requireEmail,
    requireToken,
    responseErrorMessage,
} from "../services/support";
import { ConfirmationDialog } from "./ConfirmationDialog";

interface DeleteAccountProps {
    open: boolean;
    handleClose: () => void;
}

export const DeleteAccount: React.FC<DeleteAccountProps> = ({
    open,
    handleClose,
}) => {
    const session = useStaffSession();

    const handleDelete = async () => {
        try {
            const email = requireEmail(session);
            const token = requireToken(session);
            const response = await fetch(
                `${apiOrigin}/admin/user/delete?email=${encodeURIComponent(email)}`,
                { method: "DELETE", headers: { "X-Auth-Token": token } },
            );
            if (!response.ok) {
                throw new Error(
                    await responseErrorMessage(
                        response,
                        "Failed to delete user account",
                    ),
                );
            }
            handleClose();
        } catch (error) {
            if (error instanceof Error) {
                alert("Failed to delete the account: " + error.message);
            } else {
                alert("An error occurred while deleting the account");
            }
        }
    };

    return (
        <ConfirmationDialog
            open={open}
            onClose={handleClose}
            title="Delete Account?"
            actions={[
                {
                    label: "Delete",
                    onClick: () => {
                        handleDelete().catch((error: unknown) =>
                            console.error("Fetch data error:", error),
                        );
                    },
                },
            ]}
        >
            Are you sure you want to delete the account?
        </ConfirmationDialog>
    );
};
