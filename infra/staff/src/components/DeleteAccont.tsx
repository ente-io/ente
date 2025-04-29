import {
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    DialogContentText,
    DialogTitle,
    Paper,
} from "@mui/material";
import React from "react";
import { getEmail, getToken } from "../App"; // Import getEmail and getToken functions
import { apiOrigin } from "../services/support";

interface DeleteAccountProps {
    open: boolean;
    handleClose: () => void;
}

const DeleteAccount: React.FC<DeleteAccountProps> = ({ open, handleClose }) => {
    const handleDelete = async () => {
        try {
            const encodedEmail = encodeURIComponent(getEmail());
            console.log(encodedEmail);
            const token = getToken();

            const deleteUrl = `${apiOrigin}/admin/user/delete?email=${encodedEmail}`;
            const response = await fetch(deleteUrl, {
                method: "DELETE",
                headers: { "X-Auth-Token": token },
            });
            if (!response.ok) {
                throw new Error("Failed to delete user account");
            }
            handleClose(); // Close dialog on successful delete
            console.log("Account deleted successfully");
        } catch (error) {
            if (error instanceof Error) {
                alert("Failed to delete the account: " + error.message);
            } else {
                alert("An error occurred while deleting the account");
            }
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
                BackdropProps={{
                    style: {
                        backgroundColor: "rgba(255, 255, 255, 0.9)", // Semi-transparent backdrop
                    },
                }}
            >
                <DialogTitle id="alert-dialog-title">
                    {"Delete Account?"}
                </DialogTitle>
                <DialogContent>
                    <DialogContentText id="alert-dialog-description">
                        Are you sure you want to delete the account?
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
                            handleDelete().catch((error: unknown) =>
                                console.error("Fetch data error:", error),
                            );
                        }}
                        sx={{
                            bgcolor: "#F4473D",
                            color: "white",
                            "&:hover": { bgcolor: "#E53935" },
                        }}
                    >
                        Delete{" "}
                    </Button>
                </DialogActions>
            </Dialog>
        </div>
    );
};

export default DeleteAccount;
