import CloseIcon from "@mui/icons-material/Close";
import {
    Box,
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    TextField,
} from "@mui/material";
import React, { useEffect, useState } from "react";
import { useStaffSessionRef } from "../services/session";
import {
    apiOrigin,
    getCurrentAdminUserId,
    requireToken,
    responseErrorMessage,
} from "../services/support";

interface ChangeEmailProps {
    open: boolean;
    onClose: () => void;
}

export const ChangeEmail: React.FC<ChangeEmailProps> = ({ open, onClose }) => {
    const [newEmail, setNewEmail] = useState("");
    const [userID, setUserID] = useState("");
    const sessionRef = useStaffSessionRef();

    useEffect(() => {
        const fetchUserID = async () => {
            const session = sessionRef.current;
            const { email } = session;
            setNewEmail(email);

            try {
                setUserID(await getCurrentAdminUserId(session));
            } catch (error) {
                console.error("Error fetching user ID:", error);
            }
        };

        if (open) {
            fetchUserID().catch((error: unknown) =>
                console.error("Error in fetchUserID:", error),
            );
        }
    }, [open, sessionRef]);

    const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
        setNewEmail(event.target.value);
    };

    const handleSubmit = async (
        event: React.SyntheticEvent<HTMLFormElement>,
    ) => {
        event.preventDefault();

        try {
            const token = requireToken(sessionRef.current);
            const url = `${apiOrigin}/admin/user/change-email`;
            const body = { userID, email: newEmail };
            const response = await fetch(url, {
                method: "PUT",
                headers: {
                    "Content-Type": "application/json",
                    "X-Auth-Token": token,
                },
                body: JSON.stringify(body),
            });

            if (!response.ok) {
                throw new Error(
                    await responseErrorMessage(
                        response,
                        "Network response was not ok",
                    ),
                );
            }

            onClose();
        } catch (error) {
            console.error("Error updating email:", error);
        }
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
            <DialogTitle sx={dialogTitleSx}>
                Change Email
                <Button onClick={onClose} sx={dialogCloseButtonSx}>
                    <CloseIcon sx={{ color: "black" }} />
                </Button>
            </DialogTitle>
            <DialogContent>
                <form onSubmit={handleSubmit}>
                    <Box sx={{ mb: 2 }}>
                        <Box
                            component="label"
                            htmlFor="newEmail"
                            sx={fieldLabelSx}
                        >
                            Email
                        </Box>
                        <TextField
                            id="newEmail"
                            name="newEmail"
                            value={newEmail}
                            onChange={handleChange}
                            fullWidth
                        />
                    </Box>

                    <DialogActions sx={{ justifyContent: "center", mt: 5 }}>
                        <Button type="submit" variant="contained" sx={submitSx}>
                            Change Email
                        </Button>
                    </DialogActions>
                </form>
            </DialogContent>
        </Dialog>
    );
};

const dialogTitleSx = { mb: "20px", mt: "20px" };

const dialogCloseButtonSx = { position: "absolute", right: 10, top: 10 };

const fieldLabelSx = { display: "block", mb: "4px", textAlign: "left" };

const submitSx = { bgcolor: "#00B33C", color: "white" };
