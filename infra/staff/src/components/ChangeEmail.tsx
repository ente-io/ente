import CloseIcon from "@mui/icons-material/Close";
import {
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    TextField,
} from "@mui/material";
import React, { useEffect, useState } from "react";
import { getEmail } from "../services/session";
import {
    apiOrigin,
    getCurrentAdminUserId,
    requireToken,
} from "../services/support";
import type { ErrorResponse } from "../types";

interface ChangeEmailProps {
    open: boolean;
    onClose: () => void;
}

export const ChangeEmail: React.FC<ChangeEmailProps> = ({ open, onClose }) => {
    const [newEmail, setNewEmail] = useState<string>("");
    const [userID, setUserID] = useState<string>("");

    useEffect(() => {
        const fetchUserID = async () => {
            const email = getEmail();
            setNewEmail(email);

            try {
                setUserID(await getCurrentAdminUserId());
            } catch (error) {
                console.error("Error fetching user ID:", error);
            }
        };

        if (open) {
            fetchUserID().catch((error: unknown) =>
                console.error("Error in fetchUserID:", error),
            );
        }
    }, [open]);

    const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
        setNewEmail(event.target.value);
    };

    const handleSubmit = async (
        event: React.SyntheticEvent<HTMLFormElement>,
    ) => {
        event.preventDefault();

        const token = requireToken();
        const url = `${apiOrigin}/admin/user/change-email`;

        const body = { userID, email: newEmail };

        try {
            const response = await fetch(url, {
                method: "PUT",
                headers: {
                    "Content-Type": "application/json",
                    "X-AUTH-TOKEN": token,
                },
                body: JSON.stringify(body),
            });

            if (!response.ok) {
                let errorData;
                try {
                    errorData = (await response.json()) as ErrorResponse;
                } catch (error) {
                    console.error("Error parsing error response:", error);
                }
                throw new Error(
                    errorData?.message ?? "Network response was not ok",
                );
            }

            onClose();
        } catch (error) {
            console.error("Error updating email:", error);
        }
    };
    const handleSubmitSync = (event: React.SyntheticEvent<HTMLFormElement>) => {
        handleSubmit(event).catch((error: unknown) => {
            console.error("Error in handleSubmit:", error);
        });
    };

    return (
        <Dialog
            open={open}
            onClose={onClose}
            slotProps={{
                backdrop: {
                    style: {
                        backdropFilter: "blur(5px)",
                        backgroundColor: "rgba(255, 255, 255, 0.8)",
                    },
                },
                paper: { style: { width: "444px", height: "300px" } },
            }}
        >
            <DialogTitle style={{ marginBottom: "20px", marginTop: "20px" }}>
                Change Email
                <Button
                    onClick={onClose}
                    style={{ position: "absolute", right: 10, top: 10 }}
                >
                    <CloseIcon style={{ color: "black" }} />
                </Button>
            </DialogTitle>
            <DialogContent>
                <form onSubmit={handleSubmitSync}>
                    <div style={{ marginBottom: "16px" }}>
                        <label
                            htmlFor="newEmail"
                            style={{
                                textAlign: "left",
                                display: "block",
                                marginBottom: "4px",
                            }}
                        >
                            Email
                        </label>
                        <TextField
                            id="newEmail"
                            name="newEmail"
                            value={newEmail}
                            onChange={handleChange}
                            fullWidth
                        />
                    </div>

                    <DialogActions
                        style={{ justifyContent: "center", marginTop: "40px" }}
                    >
                        <Button
                            type="submit"
                            variant="contained"
                            style={{
                                backgroundColor: "#00B33C",
                                color: "white",
                            }}
                        >
                            Change Email
                        </Button>
                    </DialogActions>
                </form>
            </DialogContent>
        </Dialog>
    );
};
