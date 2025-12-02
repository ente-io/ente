import {
    Alert,
    Box,
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    FormControl,
    InputLabel,
    MenuItem,
    Paper,
    Select,
    Typography,
} from "@mui/material";
import type { SelectChangeEvent } from "@mui/material/Select";
import { useEffect, useState } from "react";
import { getToken } from "../App";
import { apiOrigin } from "../services/support";

const APP_OPTIONS = [
    { label: "Photos", value: "photos" },
    { label: "Locker", value: "locker" },
    { label: "Auth", value: "auth" },
] as const;

type AppOption = (typeof APP_OPTIONS)[number]["value"];

const computeExpiryTimeMicros = () =>
    Date.now() * 1000 + 7 * 24 * 60 * 60 * 1_000_000;

const generateOtp = () =>
    Math.floor(Math.random() * 1_000_000)
        .toString()
        .padStart(6, "0");

interface AddOttProps {
    open: boolean;
    onClose: () => void;
    userEmail: string;
}

const AddOtt = ({ open, onClose, userEmail }: AddOttProps) => {
    const [selectedApp, setSelectedApp] = useState<AppOption>("photos");
    const [submitting, setSubmitting] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [createdOtp, setCreatedOtp] = useState<string | null>(null);
    const [expiryPreview, setExpiryPreview] = useState<number>(() =>
        computeExpiryTimeMicros(),
    );

    useEffect(() => {
        if (open) {
            setSelectedApp("photos");
            setError(null);
            setCreatedOtp(null);
            setExpiryPreview(computeExpiryTimeMicros());
        }
    }, [open]);

    const handleClose = () => {
        if (submitting) {
            return;
        }
        onClose();
    };

    const handleSubmit = async () => {
        try {
            setSubmitting(true);
            setError(null);

            if (!userEmail || userEmail === "None") {
                throw new Error("User email is unavailable");
            }

            const token = getToken();
            if (!token) {
                throw new Error("Auth token is unavailable");
            }

            const otp = generateOtp();
            const expiryTime = computeExpiryTimeMicros();
            setExpiryPreview(expiryTime);

            const response = await fetch(`${apiOrigin}/admin/user/add-ott`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "X-Auth-Token": token,
                },
                body: JSON.stringify({
                    email: userEmail,
                    code: otp,
                    app: selectedApp,
                    expiryTime: expiryTime,
                }),
            });

            if (!response.ok) {
                const message = await response.text();
                throw new Error(message || "Failed to create OTT");
            }

            setCreatedOtp(otp);
        } catch (err) {
            if (err instanceof Error) {
                setError(err.message);
            } else {
                setError("Failed to create OTT");
            }
        } finally {
            setSubmitting(false);
        }
    };

    return (
        <Dialog
            open={open}
            onClose={handleClose}
            PaperComponent={Paper}
            maxWidth="xs"
            fullWidth
        >
            {createdOtp ? (
                <>
                    <DialogTitle>OTT created</DialogTitle>
                    <DialogContent>
                        <Typography gutterBottom>
                            Share this OTP with the user. It expires in 7 days.
                        </Typography>
                        <Box
                            sx={{
                                bgcolor: "#F5F5F5",
                                borderRadius: 1,
                                p: 2,
                                textAlign: "center",
                                fontSize: "1.5rem",
                                fontWeight: "bold",
                                letterSpacing: "0.2rem",
                            }}
                        >
                            {createdOtp}
                        </Box>
                    </DialogContent>
                    <DialogActions>
                        <Button onClick={handleClose} variant="contained">
                            Done
                        </Button>
                    </DialogActions>
                </>
            ) : (
                <>
                    <DialogTitle>Add OTT</DialogTitle>
                    <DialogContent>
                        <Typography variant="body2" gutterBottom>
                            Generate a one-time token for{" "}
                            <strong>{userEmail || "this user"}</strong>. The OTP
                            expires 7 days from now.
                        </Typography>
                        <FormControl fullWidth margin="normal">
                            <InputLabel id="app-type-label">
                                App type
                            </InputLabel>
                            <Select
                                labelId="app-type-label"
                                value={selectedApp}
                                label="App type"
                                onChange={(
                                    event: SelectChangeEvent<AppOption>,
                                ) =>
                                    setSelectedApp(
                                        event.target.value as AppOption,
                                    )
                                }
                            >
                                {APP_OPTIONS.map((option) => (
                                    <MenuItem
                                        key={option.value}
                                        value={option.value}
                                    >
                                        {option.label}
                                    </MenuItem>
                                ))}
                            </Select>
                        </FormControl>
                        <Typography variant="caption" color="text.secondary">
                            Expiry (µs): {expiryPreview}
                        </Typography>
                        {error && (
                            <Alert severity="error" sx={{ mt: 2 }}>
                                {error}
                            </Alert>
                        )}
                    </DialogContent>
                    <DialogActions>
                        <Button onClick={handleClose}>Cancel</Button>
                        <Button
                            variant="contained"
                            onClick={() => {
                                void handleSubmit();
                            }}
                            disabled={submitting}
                        >
                            {submitting ? "Creating..." : "Create"}
                        </Button>
                    </DialogActions>
                </>
            )}
        </Dialog>
    );
};

export default AddOtt;
