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

interface Disable2FAProps {
    open: boolean;
    handleClose: () => void;
    handleDisable2FA: () => void; // Callback to handle 2FA disablement
}

export const Disable2FA: React.FC<Disable2FAProps> = ({
    open,
    handleClose,
    handleDisable2FA,
}) => {
    const [loading, setLoading] = useState(false);

    const handleDisable = async () => {
        try {
            setLoading(true);
            const token = requireToken();
            const userID = await getCurrentAdminUserId();

            const disableUrl = `${apiOrigin}/admin/user/disable-2fa`;
            const disableResponse = await fetch(disableUrl, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-Auth-Token": token,
                },
                body: JSON.stringify({ userID }),
            });

            if (!disableResponse.ok) {
                const errorResponse = await disableResponse.text();
                throw new Error(`Failed to disable 2FA: ${errorResponse}`);
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
                    {"Disable 2FA?"}
                </DialogTitle>
                <DialogContent>
                    <DialogContentText id="alert-dialog-description">
                        Are you sure you want to disable 2FA for this account?
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
                            handleDisable().catch((error: unknown) =>
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
                        {loading ? "Disabling..." : "Disable"}
                    </Button>
                </DialogActions>
            </Dialog>
        </div>
    );
};
