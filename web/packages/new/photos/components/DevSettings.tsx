import { useIsMobileWidth } from "@/base/hooks";
import { ensureOk } from "@/base/http";
import { getKVS, removeKV, setKV } from "@/base/kv";
import log from "@/base/log";
import InfoOutlinedIcon from "@mui/icons-material/InfoOutlined";
import {
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    IconButton,
    InputAdornment,
    Link,
    TextField,
    type ModalProps,
} from "@mui/material";
import { useFormik } from "formik";
import { t } from "i18next";
import React, { useEffect, useState } from "react";
import { z } from "zod";
import { FocusVisibleButton } from "./FocusVisibleButton";
import { SlideUpTransition } from "./mui/SlideUpTransition";

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
    const fullScreen = useIsMobileWidth();

    const handleDialogClose: ModalProps["onClose"] = (_, reason: string) => {
        // Don't close on backdrop clicks.
        if (reason != "backdropClick") onClose();
    };

    return (
        <Dialog
            {...{ open, fullScreen }}
            onClose={handleDialogClose}
            TransitionComponent={SlideUpTransition}
            maxWidth="xs"
            fullWidth
        >
            <Contents {...{ onClose }} />
        </Dialog>
    );
};

type ContentsProps = Pick<DevSettingsProps, "onClose">;

const Contents: React.FC<ContentsProps> = (props) => {
    // We need two nested components.
    //
    // -   The initialAPIOrigin cannot be in our parent (the top level
    //     DevSettings) otherwise it gets preserved across dialog reopens
    //     instead of being read from storage on opening the dialog.
    //
    // -   The initialAPIOrigin cannot be in our child (Form) because Formik
    //     doesn't have supported for async initial values.
    const [initialAPIOrigin, setInitialAPIOrigin] = useState<
        string | undefined
    >();

    useEffect(
        () =>
            void getKVS("apiOrigin").then((o) => setInitialAPIOrigin(o ?? "")),
        [],
    );

    // Even though this is async, this should be instantanous, we're just
    // reading the value from the local IndexedDB.
    if (initialAPIOrigin === undefined) return <></>;

    return <Form {...{ initialAPIOrigin }} {...props} />;
};

type FormProps = ContentsProps & {
    /** The initial value of API origin to prefill in the text input field. */
    initialAPIOrigin: string;
};

const Form: React.FC<FormProps> = ({ initialAPIOrigin, onClose }) => {
    const form = useFormik({
        initialValues: {
            apiOrigin: initialAPIOrigin,
        },
        validate: ({ apiOrigin }) => {
            try {
                apiOrigin && new URL(apiOrigin);
            } catch {
                return { apiOrigin: "Invalid endpoint" };
            }
            return {};
        },
        onSubmit: async (values, { setSubmitting, setErrors }) => {
            try {
                await updateAPIOrigin(values.apiOrigin);
            } catch (e) {
                // The person using this functionality is likely a developer and
                // might be helped more by the original error instead of a
                // friendlier but less specific message.
                setErrors({
                    apiOrigin: e instanceof Error ? e.message : String(e),
                });
                return;
            }

            setSubmitting(false);
            onClose();
        },
    });

    // Show validation errors only after the form has been submitted once (the
    // touched state of apiOrigin gets set too early, perhaps because of the
    // autoFocus).
    const hasError =
        form.submitCount > 0 &&
        form.touched.apiOrigin &&
        !!form.errors.apiOrigin;

    return (
        <form onSubmit={form.handleSubmit}>
            <DialogTitle sx={{ "&&": { padding: "24px 24px 12px 24px" } }}>
                {t("developer_settings")}
            </DialogTitle>
            <DialogContent sx={{ "&&": { padding: "0 24px 0 24px" } }}>
                <TextField
                    fullWidth
                    autoFocus
                    id="apiOrigin"
                    name="apiOrigin"
                    label={t("server_endpoint")}
                    placeholder="http://localhost:8080"
                    value={form.values.apiOrigin}
                    onChange={form.handleChange}
                    onBlur={form.handleBlur}
                    error={hasError}
                    helperText={
                        hasError
                            ? form.errors.apiOrigin
                            : " " /* always show an empty string to prevent a layout shift */
                    }
                    InputProps={{
                        endAdornment: (
                            <InputAdornment position="end">
                                <Link
                                    href="https://help.ente.io/self-hosting/guides/custom-server/"
                                    target="_blank"
                                    rel="noopener"
                                >
                                    <IconButton
                                        aria-label={t("more_information")}
                                        color="secondary"
                                        edge="end"
                                    >
                                        <InfoOutlinedIcon />
                                    </IconButton>
                                </Link>
                            </InputAdornment>
                        ),
                    }}
                />
            </DialogContent>
            <DialogActions sx={{ "&&": { padding: "0 24px 24px 24px" } }}>
                <FocusVisibleButton
                    type="submit"
                    color="accent"
                    fullWidth
                    disabled={form.isSubmitting}
                >
                    {t("save")}
                </FocusVisibleButton>
                <FocusVisibleButton
                    onClick={onClose}
                    color="secondary"
                    fullWidth
                >
                    {t("cancel")}
                </FocusVisibleButton>
            </DialogActions>
        </form>
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
 */
const updateAPIOrigin = async (origin: string) => {
    if (!origin) {
        await removeKV("apiOrigin");
        return;
    }

    const res = await fetch(`${origin}/ping`);
    ensureOk(res);
    try {
        PingResponse.parse(await res.json());
    } catch (e) {
        log.error("Invalid response", e);
        throw new Error("Invalid response");
    }

    await setKV("apiOrigin", origin);
};

const PingResponse = z.object({
    message: z.enum(["pong"]),
});
