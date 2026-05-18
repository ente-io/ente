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

interface CloseFamilyProps {
    open: boolean;
    handleClose: () => void;
    handleCloseFamily: () => void; // Callback to handle closing family
}

const CloseFamily: React.FC<CloseFamilyProps> = ({
    open,
    handleClose,
    handleCloseFamily,
}) => {
    const [loading, setLoading] = useState(false);

    const handleClosure = async () => {
        try {
            setLoading(true);
            const token = requireToken();
            const userId = await getCurrentAdminUserId();

            const closeFamilyUrl = `${apiOrigin}/admin/user/close-family`;
            const closeFamilyResponse = await fetch(closeFamilyUrl, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-Auth-Token": token,
                },
                body: JSON.stringify({ userId }),
            });

            if (!closeFamilyResponse.ok) {
                const errorResponse = await closeFamilyResponse.text();
                throw new Error(`Failed to close family: ${errorResponse}`);
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
                    {"Close Family?"}
                </DialogTitle>
                <DialogContent>
                    <DialogContentText id="alert-dialog-description">
                        Are you sure you want to close family relations for this
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
                            handleClosure().catch((error: unknown) =>
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
                        {loading ? "Closing..." : "Close"}
                    </Button>
                </DialogActions>
            </Dialog>
        </div>
    );
};

export default CloseFamily;
