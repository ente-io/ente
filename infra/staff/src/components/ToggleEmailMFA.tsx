import {
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    DialogContentText,
    DialogTitle,
    Paper,
} from "@mui/material";
import React, { useState } from "react";
import {
    apiOrigin,
    getCurrentAdminUserId,
    requireToken,
} from "../services/support";

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
            const toggleEmailMFAResponse = await fetch(toggleEmailMFAUrl, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-Auth-Token": token,
                },
                body: JSON.stringify({ userID: userId, emailMFA: enable }),
            });

            if (!toggleEmailMFAResponse.ok) {
                const errorResponse = await toggleEmailMFAResponse.text();
                throw new Error(`Failed to update Email MFA: ${errorResponse}`);
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
        <div>
            <Dialog
                open={open}
                onClose={handleClose}
                aria-labelledby="alert-dialog-title"
                aria-describedby="alert-dialog-description"
                PaperComponent={Paper}
                sx={{
                    width: "499px",
                    height: "286px",
                    margin: "auto",
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    justifyContent: "center",
                }}
                slotProps={{
                    backdrop: {
                        style: {
                            backgroundColor: "rgba(255, 255, 255, 0.9)", // Semi-transparent backdrop
                        },
                    },
                }}
            >
                <DialogTitle id="alert-dialog-title">
                    {"Toggle Email MFA"}
                </DialogTitle>
                <DialogContent>
                    <DialogContentText id="alert-dialog-description">
                        Do you want to enable or disable Email MFA for this
                        account?
                    </DialogContentText>
                </DialogContent>
                <DialogActions sx={{ justifyContent: "center" }}>
                    <Button
                        onClick={handleClose}
                        sx={{
                            bgcolor: "white",
                            color: "black",
                            "&:hover": { bgcolor: "#FAFAFA" },
                        }}
                    >
                        Cancel
                    </Button>
                    <Button
                        onClick={() => {
                            handleToggle(true).catch((error: unknown) =>
                                console.error(error),
                            );
                        }}
                        sx={{
                            bgcolor: "#4CAF50",
                            color: "white",
                            "&:hover": { bgcolor: "#45A049" },
                        }}
                        disabled={loading}
                    >
                        {loading ? "Processing..." : "Enable Email MFA"}
                    </Button>
                    <Button
                        onClick={() => {
                            handleToggle(false).catch((error: unknown) =>
                                console.error(error),
                            );
                        }}
                        sx={{
                            bgcolor: "#F4473D",
                            color: "white",
                            "&:hover": { bgcolor: "#E53935" },
                        }}
                        disabled={loading}
                    >
                        {loading ? "Processing..." : "Disable Email MFA"}
                    </Button>
                </DialogActions>
            </Dialog>
        </div>
    );
};
