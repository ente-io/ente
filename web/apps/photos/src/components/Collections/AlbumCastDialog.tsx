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
import React, { useCallback, useEffect, useState } from "react";
import { Trans } from "react-i18next";
import { z } from "zod/v4";

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
}) => (
    <TitledMiniDialog {...{ open, onClose }} title={t("cast_album_to_tv")}>
        <AlbumCastDialogContents {...{ open, onClose, collection }} />
    </TitledMiniDialog>
);

/**
 * [Note: MUI dialog state]
 *
 * In some cases we keep the dialog contents in a separate component so that (a)
 * they get rendered only when the dialog is shown, and (b) they get rendered
 * afresh when the dialog is unmounted and then shown again.
 *
 * Keeping it separate both resets the state of the component, and also ensures
 * that the effects run again when the dialog is shown.
 *
 * Details:
 *
 * Any state we keep inside the React component that a MUI Dialog as a child
 * gets retained across visibility changes. For example, if the
 * {@link AlbumCastDialogContents} were inlined into {@link AlbumCastDialog},
 * then if we were to open the dialog, switch over to the "pin" view, then close
 * the dialog by clicking on the backdrop, and then reopen it again, then we'd
 * still remain on the "pin" view.
 *
 * This behaviour might be desirable or undesirable, depending on the
 * circumstance. If it is undesirable, there are multiple approaches:
 * https://github.com/mui/material-ui/issues/16325
 *
 * One of those approaches is to keep the dialog contents in a separate
 * component.
 */
export const AlbumCastDialogContents: React.FC<AlbumCastDialogProps> = ({
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
        // @ts-expect-error TODO: why is this needed
        // eslint-disable-next-line @typescript-eslint/dot-notation
        setBrowserCanCast(typeof window["chrome"] != "undefined");
    }, []);

    const onSubmit: SingleInputFormProps["onSubmit"] = useCallback(
        async (value, setFieldError) => {
            try {
                await publishCastPayload(value.trim(), collection);
                onClose();
            } catch (e) {
                log.error("Failed to cast", e);
                if (
                    e instanceof Error &&
                    e.message == unknownDeviceCodeErrorMessage
                ) {
                    setFieldError(t("tv_not_found"));
                } else {
                    throw e;
                }
            }
        },
        [onClose, collection],
    );

    useEffect(() => {
        if (view == "auto") {
            void loadCast().then(async (cast) => {
                const instance = cast.framework.CastContext.getInstance();
                try {
                    await instance.requestSession();
                } catch (e) {
                    setView("auto-cast-error");
                    log.error("Error requesting session", e);
                    return;
                }
                const session = instance.getCurrentSession()!;
                session.addMessageListener(
                    "urn:x-cast:pair-request",
                    (_, message) => {
                        const { code } = CastPairRequest.parse(
                            JSON.parse(message),
                        );

                        void publishCastPayload(code, collection)
                            .then(() => {
                                setView("choose");
                                onClose();
                            })
                            .catch((e: unknown) => {
                                log.error("Error casting to TV", e);
                                setView("auto-cast-error");
                            });
                    },
                );

                const collectionID = collection.id;
                void session
                    .sendMessage("urn:x-cast:pair-request", { collectionID })
                    .then(() => {
                        log.debug(() => "urn:x-cast:pair-request sent");
                    });
            });
        }
    }, [onClose, view, collection]);

    useEffect(() => {
        // Make API call to clear all previous sessions (if any) whenever the
        // dialog is opened so that the user can start a new session.
        //
        // This is not going to have an effect on the current client, so we
        // don't need to wait for it to finish (and can ignore errors).
        if (open) void revokeAllCastTokens();
    }, [open]);

    return (
        <>
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
        </>
    );
};

/**
 * Zod schema for the "x-cast:pair-request" payload sent by the cast app.
 */
const CastPairRequest = z.object({ code: z.string() });
