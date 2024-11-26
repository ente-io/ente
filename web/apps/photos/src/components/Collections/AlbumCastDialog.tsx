import { TitledMiniDialog } from "@/base/components/MiniDialog";
import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { boxSeal } from "@/base/crypto";
import { newID } from "@/base/id";
import log from "@/base/log";
import type { Collection } from "@/media/collection";
import { photosDialogZIndex } from "@/new/photos/components/utils/z-index";
import {
    publicKeyForPairingCode,
    revokeAllCastTokens,
} from "@/new/photos/services/cast";
import { loadCast } from "@/new/photos/utils/chromecast-sender";
import SingleInputForm, {
    type SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import { Button, Link, Stack, Typography } from "@mui/material";
import { t } from "i18next";
import { useEffect, useState } from "react";
import { Trans } from "react-i18next";

interface AlbumCastDialogProps {
    /** If `true`, the dialog is shown. */
    open: boolean;
    /** Callback fired when the dialog wants to be closed. */
    onClose: () => void;
    /** The collection that we want to cast. */
    collection: Collection;
}

/**
 * A dialog that shows various options that the user has for casting an album.
 */
export const AlbumCastDialog: React.FC<AlbumCastDialogProps> = ({
    open,
    onClose,
    collection,
}) => {
    const [view, setView] = useState<
        "choose" | "auto" | "pin" | "auto-cast-error"
    >("choose");

    const [browserCanCast, setBrowserCanCast] = useState(false);

    useEffect(() => {
        // Determine if Chromecast is supported by the current browser
        // (effectively, only Chrome).
        //
        // Override, otherwise tsc complains about unknown property `chrome`.
        // eslint-disable-next-line @typescript-eslint/dot-notation
        setBrowserCanCast(typeof window["chrome"] !== "undefined");
    }, []);

    const onSubmit: SingleInputFormProps["callback"] = async (
        value,
        setFieldError,
    ) => {
        try {
            if (await doCast(value.trim())) {
                onClose();
            } else {
                setFieldError(t("tv_not_found"));
            }
        } catch (e) {
            log.error("Failed to cast", e);
            setFieldError(t("generic_error_retry"));
        }
    };

    const doCast = async (code: string) => {
        // Find out the public key associated with the given pairing code (if
        // indeed a device has published one).
        const publicKey = await publicKeyForPairingCode(code);
        if (!publicKey) return false;

        // Generate random id.
        const castToken = newID("cast_");

        // Publish the payload so that the other end can use it.
        const payload = JSON.stringify({
            castToken: castToken,
            collectionID: collection.id,
            collectionKey: collection.key,
        });
        const encryptedPayload = await boxSeal(btoa(payload), publicKey);

        await castGateway.publishCastPayload(
            code,
            encryptedPayload,
            collection.id,
            castToken,
        );
    };

    useEffect(() => {
        if (view === "auto") {
            loadCast().then(async (cast) => {
                const instance = cast.framework.CastContext.getInstance();
                try {
                    await instance.requestSession();
                } catch (e) {
                    setView("auto-cast-error");
                    log.error("Error requesting session", e);
                    return;
                }
                const session = instance.getCurrentSession();
                session.addMessageListener(
                    "urn:x-cast:pair-request",
                    (_, message) => {
                        const data = message;
                        const obj = JSON.parse(data);
                        const code = obj.code;

                        if (code) {
                            doCast(code)
                                .then(() => {
                                    setView("choose");
                                    onClose();
                                })
                                .catch((e: unknown) => {
                                    log.error("Error casting to TV", e);
                                    setView("auto-cast-error");
                                });
                        }
                    },
                );

                const collectionID = collection.id;
                session
                    .sendMessage("urn:x-cast:pair-request", { collectionID })
                    .then(() => {
                        log.debug(() => "urn:x-cast:pair-request sent");
                    });
            });
        }
    }, [view]);

    useEffect(() => {
        // Make API call to clear all previous sessions (if any) whenever the
        // dialog is opened so that the user can start a new session.
        //
        // This is not going to have an effect on the current client, so we
        // don't need to wait for it to finish (and can ignore errors).
        if (open) void revokeAllCastTokens();
    }, [open]);

    return (
        <TitledMiniDialog
            open={open}
            onClose={onClose}
            title={t("cast_album_to_tv")}
            sx={{ zIndex: photosDialogZIndex }}
        >
            {view == "choose" && (
                <Stack sx={{ py: 1, gap: 4 }}>
                    {browserCanCast && (
                        <Stack sx={{ gap: 2 }}>
                            <Typography color={"text.muted"}>
                                {t("cast_auto_pair_description")}
                            </Typography>

                            <Button onClick={() => setView("auto")}>
                                {t("cast_auto_pair")}
                            </Button>
                        </Stack>
                    )}
                    <Stack sx={{ gap: 2 }}>
                        <Typography color="text.muted">
                            {t("pair_with_pin_description")}
                        </Typography>
                        <Button onClick={() => setView("pin")}>
                            {t("pair_with_pin")}
                        </Button>
                    </Stack>
                </Stack>
            )}
            {view == "auto" && (
                <Stack sx={{ pt: 1, gap: 3, textAlign: "center" }}>
                    <div>
                        <ActivityIndicator />
                    </div>
                    <Typography>{t("choose_device_from_browser")}</Typography>
                    <Button color="secondary" onClick={() => setView("choose")}>
                        {t("go_back")}
                    </Button>
                </Stack>
            )}
            {view == "auto-cast-error" && (
                <Stack sx={{ pt: 1, gap: 3, textAlign: "center" }}>
                    <Typography>{t("cast_auto_pair_failed")}</Typography>
                    <Button color="secondary" onClick={() => setView("choose")}>
                        {t("go_back")}
                    </Button>
                </Stack>
            )}
            {view == "pin" && (
                <>
                    <Stack sx={{ gap: 2, mb: 2 }}>
                        <Typography>
                            <Trans
                                i18nKey="visit_cast_url"
                                components={{
                                    a: (
                                        <Link
                                            target="_blank"
                                            href="https://cast.ente.io"
                                        />
                                    ),
                                }}
                                values={{ url: "cast.ente.io" }}
                            />
                        </Typography>
                        <Typography>{t("enter_cast_pin_code")}</Typography>
                    </Stack>
                    <SingleInputForm
                        callback={onSubmit}
                        fieldType="text"
                        realLabel={t("code")}
                        realPlaceholder={"123456"}
                        buttonText={t("pair_device_to_tv")}
                        submitButtonProps={{ sx: { mt: 1, mb: 2 } }}
                    />
                    <Button
                        variant="text"
                        fullWidth
                        onClick={() => setView("choose")}
                    >
                        {t("go_back")}
                    </Button>
                </>
            )}
        </TitledMiniDialog>
    );
};
