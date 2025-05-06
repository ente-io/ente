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
import { getEmail, getToken } from "../App"; // Import getEmail and getToken functions
import { apiOrigin } from "../services/support";
import type { UserData } from "../types";

interface Disable2FAProps {
    open: boolean;
    handleClose: () => void;
    handleDisable2FA: () => void; // Callback to handle 2FA disablement
}

const Disable2FA: React.FC<Disable2FAProps> = ({
    open,
    handleClose,
    handleDisable2FA,
}) => {
    const [loading, setLoading] = useState(false);

    const handleDisable = async () => {
        try {
            setLoading(true);
            const email = getEmail();
            const token = getToken();

            if (!email) {
                throw new Error("Email not found");
            }

            if (!token) {
                throw new Error("Token not found");
            }

            const encodedEmail = encodeURIComponent(email);

            // Fetch user data
            const userUrl = `${apiOrigin}/admin/user?email=${encodedEmail}`;
            const userResponse = await fetch(userUrl, {
                method: "GET",
                headers: {
                    "Content-Type": "application/json",
                    "X-Auth-Token": token,
                },
            });
            if (!userResponse.ok) {
                throw new Error("Failed to fetch user data");
            }
            const userData = (await userResponse.json()) as UserData;
            const userID = userData.subscription?.userID;

            if (!userID) {
                throw new Error("User ID not found");
            }

            // Disable 2FA
            const disableUrl = `${apiOrigin}/admin/user/disable-2fa`;
            const body = JSON.stringify({ userID });
            const disableResponse = await fetch(disableUrl, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-Auth-Token": token,
                },
                body: body,
            });

            if (!disableResponse.ok) {
                const errorResponse = await disableResponse.text();
                throw new Error(`Failed to disable 2FA: ${errorResponse}`);
            }
            handleDisable2FA(); // Notify parent component of successful disable
            handleClose(); // Close dialog on successful disable
            console.log("2FA disabled successfully");
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

    const handleCancel = () => {
        handleClose(); // Close dialog
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
                BackdropProps={{
                    style: {
                        backgroundColor: "rgba(255, 255, 255, 0.9)", // Semi-transparent backdrop
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
                        onClick={handleCancel}
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

export default Disable2FA;
