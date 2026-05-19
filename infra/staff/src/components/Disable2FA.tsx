import React, { useState } from "react";
import { useStaffSession } from "../services/session";
import {
    apiOrigin,
    getCurrentAdminUserId,
    requireToken,
    responseErrorMessage,
} from "../services/support";
import { ConfirmationDialog } from "./ConfirmationDialog";

interface Disable2FAProps {
    open: boolean;
    handleClose: () => void;
    handleDisable2FA: () => void;
}

export const Disable2FA: React.FC<Disable2FAProps> = ({
    open,
    handleClose,
    handleDisable2FA,
}) => {
    const [loading, setLoading] = useState(false);
    const session = useStaffSession();

    const handleDisable = async () => {
        try {
            setLoading(true);
            const token = requireToken(session);
            const userID = await getCurrentAdminUserId(session);
            const response = await fetch(
                `${apiOrigin}/admin/user/disable-2fa`,
                {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                        "X-Auth-Token": token,
                    },
                    body: JSON.stringify({ userID }),
                },
            );

            if (!response.ok) {
                throw new Error(
                    await responseErrorMessage(
                        response,
                        "Failed to disable 2FA",
                    ),
                );
            }
            handleDisable2FA();
            handleClose();
        } catch (error) {
            if (error instanceof Error) {
                alert(error.message);
            } else {
                alert("Failed to disable 2FA");
            }
        } finally {
            setLoading(false);
        }
    };

    return (
        <ConfirmationDialog
            open={open}
            onClose={handleClose}
            title="Disable 2FA?"
            actions={[
                {
                    label: "Disable",
                    loadingLabel: "Disabling...",
                    loading,
                    onClick: () => {
                        handleDisable().catch((error: unknown) =>
                            console.error(error),
                        );
                    },
                },
            ]}
        >
            Are you sure you want to disable 2FA for this account?
        </ConfirmationDialog>
    );
};
