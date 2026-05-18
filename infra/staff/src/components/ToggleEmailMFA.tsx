import React, { useState } from "react";
import {
    apiOrigin,
    getCurrentAdminUserId,
    requireToken,
    responseErrorMessage,
} from "../services/support";
import { ConfirmationDialog } from "./ConfirmationDialog";

interface ToggleEmailMFAProps {
    open: boolean;
    handleClose: () => void;
    handleToggleEmailMFA: (status: boolean) => void;
}

export const ToggleEmailMFA: React.FC<ToggleEmailMFAProps> = ({
    open,
    handleClose,
    handleToggleEmailMFA,
}) => {
    const [loading, setLoading] = useState(false);

    const handleToggle = async (enable: boolean) => {
        try {
            setLoading(true);
            const token = requireToken();
            const userId = await getCurrentAdminUserId();

            const toggleEmailMFAUrl = `${apiOrigin}/admin/user/update-email-mfa`;
            const response = await fetch(toggleEmailMFAUrl, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-Auth-Token": token,
                },
                body: JSON.stringify({ userID: userId, emailMFA: enable }),
            });

            if (!response.ok) {
                throw new Error(
                    await responseErrorMessage(
                        response,
                        "Failed to update Email MFA",
                    ),
                );
            }

            handleToggleEmailMFA(enable);
            handleClose();
        } catch (error) {
            if (error instanceof Error) {
                alert(error.message);
            } else {
                alert("Failed to update Email MFA");
            }
        } finally {
            setLoading(false);
        }
    };

    return (
        <ConfirmationDialog
            open={open}
            onClose={handleClose}
            title="Toggle Email MFA"
            actions={[
                {
                    label: "Enable Email MFA",
                    loadingLabel: "Processing...",
                    loading,
                    tone: "success",
                    onClick: () => {
                        handleToggle(true).catch((error: unknown) =>
                            console.error(error),
                        );
                    },
                },
                {
                    label: "Disable Email MFA",
                    loadingLabel: "Processing...",
                    loading,
                    onClick: () => {
                        handleToggle(false).catch((error: unknown) =>
                            console.error(error),
                        );
                    },
                },
            ]}
        >
            Do you want to enable or disable Email MFA for this account?
        </ConfirmationDialog>
    );
};
