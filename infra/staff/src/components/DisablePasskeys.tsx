import React, { useState } from "react";
import {
    apiOrigin,
    getCurrentAdminUserId,
    requireToken,
    responseErrorMessage,
} from "../services/support";
import { ConfirmationDialog } from "./ConfirmationDialog";

interface DisablePasskeysProps {
    open: boolean;
    handleClose: () => void;
    handleDisablePasskeys: () => void;
}

export const DisablePasskeys: React.FC<DisablePasskeysProps> = ({
    open,
    handleClose,
    handleDisablePasskeys,
}) => {
    const [loading, setLoading] = useState(false);

    const handleDisabling = async () => {
        try {
            setLoading(true);
            const token = requireToken();
            const userId = await getCurrentAdminUserId();

            const disablePasskeysUrl = `${apiOrigin}/admin/user/disable-passkeys`;
            const response = await fetch(disablePasskeysUrl, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-Auth-Token": token,
                },
                body: JSON.stringify({ userId }),
            });

            if (!response.ok) {
                throw new Error(
                    await responseErrorMessage(
                        response,
                        "Failed to disable passkeys",
                    ),
                );
            }

            handleDisablePasskeys();
            handleClose();
        } catch (error) {
            if (error instanceof Error) {
                alert(error.message);
            } else {
                alert("Failed to disable passkeys");
            }
        } finally {
            setLoading(false);
        }
    };

    return (
        <ConfirmationDialog
            open={open}
            onClose={handleClose}
            title="Disable Passkeys?"
            actions={[
                {
                    label: "Disable",
                    loadingLabel: "Disabling...",
                    loading,
                    onClick: () => {
                        handleDisabling().catch((error: unknown) =>
                            console.error(error),
                        );
                    },
                },
            ]}
        >
            Are you sure you want to disable passkeys for this account?
        </ConfirmationDialog>
    );
};
