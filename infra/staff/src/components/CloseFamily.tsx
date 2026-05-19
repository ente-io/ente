import React, { useState } from "react";
import { useStaffSession } from "../services/session";
import {
    apiOrigin,
    getCurrentAdminUserId,
    requireToken,
    responseErrorMessage,
} from "../services/support";
import { ConfirmationDialog } from "./ConfirmationDialog";

interface CloseFamilyProps {
    open: boolean;
    handleClose: () => void;
    handleCloseFamily: () => void;
}

export const CloseFamily: React.FC<CloseFamilyProps> = ({
    open,
    handleClose,
    handleCloseFamily,
}) => {
    const [loading, setLoading] = useState(false);
    const session = useStaffSession();

    const handleClosure = async () => {
        try {
            setLoading(true);
            const token = requireToken(session);
            const userId = await getCurrentAdminUserId(session);
            const response = await fetch(
                `${apiOrigin}/admin/user/close-family`,
                {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                        "X-Auth-Token": token,
                    },
                    body: JSON.stringify({ userId }),
                },
            );

            if (!response.ok) {
                throw new Error(
                    await responseErrorMessage(
                        response,
                        "Failed to close family",
                    ),
                );
            }

            handleCloseFamily();
            handleClose();
        } catch (error) {
            if (error instanceof Error) {
                alert(error.message);
            } else {
                alert("Failed to close family");
            }
        } finally {
            setLoading(false);
        }
    };

    return (
        <ConfirmationDialog
            open={open}
            onClose={handleClose}
            title="Close Family?"
            actions={[
                {
                    label: "Close",
                    loadingLabel: "Closing...",
                    loading,
                    onClick: () => {
                        handleClosure().catch((error: unknown) =>
                            console.error(error),
                        );
                    },
                },
            ]}
        >
            Are you sure you want to close family relations for this account?
        </ConfirmationDialog>
    );
};
