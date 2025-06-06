import { Link, Stack, Typography } from "@mui/material";
import { TitledMiniDialog } from "ente-base/components/MiniDialog";
import { ActivityIndicator } from "ente-base/components/mui/ActivityIndicator";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import {
    SingleInputForm,
    type SingleInputFormProps,
} from "ente-base/components/SingleInputForm";
import type { ModalVisibilityProps } from "ente-base/components/utils/modal";
import { ut } from "ente-base/i18n";
import log from "ente-base/log";
import type { Collection } from "ente-media/collection";
import { useSettingsSnapshot } from "ente-new/photos/components/utils/use-snapshot";
import {
    publishCastPayload,
    revokeAllCastTokens,
    unknownDeviceCodeErrorMessage,
} from "ente-new/photos/services/cast";
import { loadCast } from "ente-new/photos/utils/chromecast-sender";
import { t } from "i18next";
import { useCallback, useEffect, useState } from "react";
import { Trans } from "react-i18next";

type AlbumCastDialogProps = ModalVisibilityProps & {
    /** The collection that we want to cast. */
    collection: Collection;
};

/**
 * A dialog that shows various options that the user has for casting an album.
 */
export const AlbumCastDialog: React.FC<AlbumCastDialogProps> = ({
    open,
    onClose,
    collection,
}) => {
    const { castURL } = useSettingsSnapshot();

    const [view, setView] = useState<
        "choose" | "auto" | "pin" | "auto-cast-error"
    >("choose");

    const [browserCanCast, setBrowserCanCast] = useState(false);

    // The link to the cast app is to the full URL, but in the link text only
    // show the host (e.g. for "https://cast.ente.io", show "cast.ente.io").
    const castHost = new URL(castURL).host;

    useEffect(() => {
        // Determine if Chromecast is supported by the current browser
        // (effectively, only Chrome).
        //
        // Override, otherwise tsc complains about unknown property `chrome`.
        // eslint-disable-next-line @typescript-eslint/dot-notation
        setBrowserCanCast(typeof window["chrome"] != "undefined");
    }, []);

    const onSubmit: SingleInputFormProps["onSubmit"] = useCallback(
        async (value, showError) => {
            try {
                await publishCastPayload(value.trim(), collection);
                onClose();
            } catch (e) {
                log.error("Failed to cast", e);
                if (
                    e instanceof Error &&
                    e.message == unknownDeviceCodeErrorMessage
                ) {
                    showError(t("tv_not_found"));
                } else {
                    throw e;
                }
            }
        },
        [onClose, collection],
    );

    useEffect(() => {
        if (view == "auto") {
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
                            publishCastPayload(`${code}`, collection)
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
    }, [view, collection]);

    useEffect(() => {
        // Make API call to clear all previous sessions (if any) whenever the
        // dialog is opened so that the user can start a new session.
        //
        // This is not going to have an effect on the current client, so we
        // don't need to wait for it to finish (and can ignore errors).
        if (open) void revokeAllCastTokens();
    }, [open]);

    return (
        <TitledMiniDialog {...{ open, onClose }} title={t("cast_album_to_tv")}>
            {view == "choose" && (
                <Stack sx={{ py: 1, gap: 4 }}>
                    {browserCanCast && (
                        <Stack sx={{ gap: 2 }}>
                            <Typography sx={{ color: "text.muted" }}>
                                {t("cast_auto_pair_description")}
                            </Typography>

                            <FocusVisibleButton onClick={() => setView("auto")}>
                                {t("cast_auto_pair")}
                            </FocusVisibleButton>
                        </Stack>
                    )}
                    <Stack sx={{ gap: 2 }}>
                        <Typography sx={{ color: "text.muted" }}>
                            {t("pair_with_pin_description")}
                        </Typography>
                        <FocusVisibleButton onClick={() => setView("pin")}>
                            {t("pair_with_pin")}
                        </FocusVisibleButton>
                    </Stack>
                </Stack>
            )}
            {view == "auto" && (
                <Stack sx={{ pt: 1, gap: 3, textAlign: "center" }}>
                    <div>
                        <ActivityIndicator />
                    </div>
                    <Typography>{t("choose_device_from_browser")}</Typography>
                    <FocusVisibleButton
                        color="secondary"
                        onClick={() => setView("choose")}
                    >
                        {t("go_back")}
                    </FocusVisibleButton>
                </Stack>
            )}
            {view == "auto-cast-error" && (
                <Stack sx={{ pt: 1, gap: 3, textAlign: "center" }}>
                    <Typography>{t("cast_auto_pair_failed")}</Typography>
                    <FocusVisibleButton
                        color="secondary"
                        onClick={() => setView("choose")}
                    >
                        {t("go_back")}
                    </FocusVisibleButton>
                </Stack>
            )}
            {view == "pin" && (
                <>
                    <Stack sx={{ gap: 2, mb: 2 }}>
                        <Typography sx={{ color: "text.muted" }}>
                            <Trans
                                i18nKey="visit_cast_url"
                                components={{
                                    a: <Link target="_blank" href={castURL} />,
                                }}
                                values={{ url: castHost }}
                            />
                        </Typography>
                        <Typography sx={{ color: "text.muted" }}>
                            {t("enter_cast_pin_code")}
                        </Typography>
                    </Stack>
                    <SingleInputForm
                        label={t("code")}
                        placeholder={ut("123456")}
                        submitButtonTitle={t("pair_device_to_tv")}
                        submitButtonColor="accent"
                        onSubmit={onSubmit}
                    />
                    <FocusVisibleButton
                        variant="text"
                        fullWidth
                        onClick={() => setView("choose")}
                        sx={{ mt: 1 }}
                    >
                        {t("go_back")}
                    </FocusVisibleButton>
                </>
            )}
        </TitledMiniDialog>
    );
};
