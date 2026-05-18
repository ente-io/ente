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
import type { DisablePasskeysProps } from "../types";

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
            const disablePasskeysResponse = await fetch(disablePasskeysUrl, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-Auth-Token": token,
                },
                body: JSON.stringify({ userId }),
            });

            if (!disablePasskeysResponse.ok) {
                const errorResponse = await disablePasskeysResponse.text();
                throw new Error(`Failed to disable passkeys: ${errorResponse}`);
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
                    {"Disable Passkeys?"}
                </DialogTitle>
                <DialogContent>
                    <DialogContentText id="alert-dialog-description">
                        Are you sure you want to disable passkeys for this
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
                            handleDisabling().catch((error: unknown) =>
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
