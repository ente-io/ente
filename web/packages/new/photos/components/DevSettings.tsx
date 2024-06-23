import log from "@/next/log";
import InfoOutlinedIcon from "@mui/icons-material/InfoOutlined";
import {
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    IconButton,
    InputAdornment,
    TextField,
    useMediaQuery,
    type ModalProps,
} from "@mui/material";
import { useFormik } from "formik";
import { t } from "i18next";
import React from "react";
import { FocusVisibleButton } from "./FocusVisibleButton";
import { SlideTransition } from "./SlideTransition";

interface DevSettingsProps {
    /** If `true`, then the dialog is shown. */
    open: boolean;
    /** Called when the dialog wants to be closed. */
    onClose: () => void;
}

/**
 * A dialog allowing the user to set the API origin that the app connects to.
 * See: [Note: Configuring custom server].
 */
export const DevSettings: React.FC<DevSettingsProps> = ({ open, onClose }) => {
    const fullScreen = useMediaQuery("(max-width: 428px)");

    const handleDialogClose: ModalProps["onClose"] = (_, reason: string) => {
        // Don't close on backdrop clicks.
        if (reason != "backdropClick") onClose();
    };

    const form = useFormik({
        initialValues: { apiOrigin: "" },
        onSubmit: async (values, { setSubmitting, setErrors }) => {
            const res = await updateAPIOrigin(values.apiOrigin);
            if (typeof res == "string") {
                setErrors({ apiOrigin: res });
            } else {
                setSubmitting(false);
                // Add a bit of delay to acknowledge the update better.
                setTimeout(onClose, 200);
            }
        },
    });

    return (
        <Dialog
            {...{ open, fullScreen }}
            onClose={handleDialogClose}
            TransitionComponent={SlideTransition}
            maxWidth="xs"
        >
            <form onSubmit={form.handleSubmit}>
                <DialogTitle>{"Developer settings"}</DialogTitle>
                <DialogContent>
                    <TextField
                        fullWidth
                        autoFocus
                        id="apiOrigin"
                        name="apiOrigin"
                        label="Server endpoint"
                        placeholder="http://localhost:8080"
                        value={form.values.apiOrigin}
                        onChange={form.handleChange}
                        onBlur={form.handleBlur}
                        error={
                            form.touched.apiOrigin && !!form.errors.apiOrigin
                        }
                        helperText={
                            form.touched.apiOrigin && form.errors.apiOrigin
                        }
                        InputProps={{
                            endAdornment: (
                                <InputAdornment position="end">
                                    <IconButton
                                        aria-label="More information"
                                        color="secondary"
                                        edge="end"
                                    >
                                        <InfoOutlinedIcon />
                                    </IconButton>
                                </InputAdornment>
                            ),
                        }}
                    />
                </DialogContent>
                <DialogActions>
                    <FocusVisibleButton
                        type="submit"
                        color="accent"
                        fullWidth
                        disabled={form.isSubmitting}
                        disableRipple
                    >
                        {"Save"}
                    </FocusVisibleButton>
                    <FocusVisibleButton
                        onClick={onClose}
                        color="secondary"
                        fullWidth
                        disableRipple
                    >
                        {t("CANCEL")}
                    </FocusVisibleButton>
                </DialogActions>
            </form>
        </Dialog>
    );
};

/**
 * Save {@link origin} to local storage after verifying it with a ping.
 *
 * The given {@link origin} will be verifying by making an API call to the
 * `/ping` endpoint. If that succeeds, then it will be saved to local storage,
 * and all subsequent API calls will use it as the {@link apiOrigin}.
 *
 * See: [Note: Configuring custom server].
 *
 * @param origin The new API origin to use. Pass an empty string to clear the
 * previously saved API origin (if any).
 *
 * @returns true on success, and the user visible error message string
 * otherwise.
 */
const updateAPIOrigin = async (origin: string): Promise<true | string> => {
    if (!origin) {
        localStorage.removeItem("apiOrigin");
        return true;
    }

    const url = `${origin}/ping`;
    try {
        const res = await fetch(url);
        if (!res.ok)
            throw new Error(`Failed to fetch ${url}: HTTP ${res.status}`);
        localStorage.setItem("apiOrigin", origin);
        return true;
    } catch (e) {
        log.error("Failed to ping the provided origin", e);
        // The person using this is likely a developer, just give them the
        // original error itself, they might find it helpful.
        return e instanceof Error ? e.message : t("ERROR");
    }
};
