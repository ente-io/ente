import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { boxSeal } from "@/base/crypto/libsodium";
import log from "@/base/log";
import type { Collection } from "@/media/collection";
import { loadCast } from "@/new/photos/utils/chromecast-sender";
import DialogBoxV2 from "@ente/shared/components/DialogBoxV2";
import SingleInputForm, {
    type SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import castGateway from "@ente/shared/network/cast";
import { Button, Link, Stack, Typography } from "@mui/material";
import { t } from "i18next";
import { useEffect, useState } from "react";
import { Trans } from "react-i18next";
import { v4 as uuidv4 } from "uuid";

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

    // Make API call to clear all previous sessions on component mount.
    useEffect(() => {
        castGateway.revokeAllTokens();

        setBrowserCanCast(typeof window["chrome"] !== "undefined");
    }, []);

    const onSubmit: SingleInputFormProps["callback"] = async (
        value,
        setFieldError,
    ) => {
        try {
            await doCast(value.trim());
            onClose();
        } catch (e) {
            if (e instanceof Error && e.message == "tv-not-found") {
                setFieldError(t("tv_not_found"));
            } else {
                setFieldError(t("generic_error_retry"));
            }
        }
    };

    const doCast = async (pin: string) => {
        // Does the TV exist? have they advertised their existence?
        const tvPublicKeyB64 = await castGateway.getPublicKey(pin);
        if (!tvPublicKeyB64) {
            throw new Error("tv-not-found");
        }

        // Generate random id.
        const castToken = uuidv4();

        // Ok, they exist. let's give them the good stuff.
        const payload = JSON.stringify({
            castToken: castToken,
            collectionID: collection.id,
            collectionKey: collection.key,
        });
        const encryptedPayload = await boxSeal(btoa(payload), tvPublicKeyB64);

        // Hey TV, we acknowlege you!
        await castGateway.publishCastPayload(
            pin,
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
                                .catch((e) => {
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
        if (open) castGateway.revokeAllTokens();
    }, [open]);

    return (
        <DialogBoxV2
            open={open}
            onClose={onClose}
            attributes={{ title: t("cast_album_to_tv") }}
            sx={{ zIndex: 1600 }}
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
                        {t("GO_BACK")}
                    </Button>
                </Stack>
            )}
            {view == "auto-cast-error" && (
                <Stack sx={{ pt: 1, gap: 3, textAlign: "center" }}>
                    <Typography>{t("cast_auto_pair_failed")}</Typography>
                    <Button color="secondary" onClick={() => setView("choose")}>
                        {t("GO_BACK")}
                    </Button>
                </Stack>
            )}
            {view == "pin" && (
                <>
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
                    <SingleInputForm
                        callback={onSubmit}
                        fieldType="text"
                        realLabel={"Code"}
                        realPlaceholder={"123456"}
                        buttonText={t("pair_device_to_tv")}
                        submitButtonProps={{ sx: { mt: 1, mb: 2 } }}
                    />
                    <Button variant="text" onClick={() => setView("choose")}>
                        {t("GO_BACK")}
                    </Button>
                </>
            )}
        </DialogBoxV2>
    );
};
