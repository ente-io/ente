import { SidebarDrawer } from "@/base/components/mui/SidebarDrawer";
import { AppNavbarNormalFlow } from "@/base/components/Navbar";
import {
    RowButton,
    RowButtonDivider,
    RowButtonGroup,
} from "@/base/components/RowButton";
import { SingleInputDialog } from "@/base/components/SingleInputDialog";
import { Titlebar } from "@/base/components/Titlebar";
import { errorDialogAttributes } from "@/base/components/utils/dialog";
import { useModalVisibility } from "@/base/components/utils/modal";
import log from "@/base/log";
import SingleInputForm from "@ente/shared/components/SingleInputForm";
import { formatDateTimeFull } from "@ente/shared/time/format";
import CalendarTodayIcon from "@mui/icons-material/CalendarToday";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import DeleteIcon from "@mui/icons-material/Delete";
import EditIcon from "@mui/icons-material/Edit";
import KeyIcon from "@mui/icons-material/Key";
import { Box, Paper, Stack, Typography, styled } from "@mui/material";
import { t } from "i18next";
import React, { useCallback, useEffect, useState } from "react";
import {
    deletePasskey,
    getPasskeys,
    registerPasskey,
    renamePasskey,
    type Passkey,
} from "services/passkey";
import { useAppContext } from "../../types/context";

const Page: React.FC = () => {
    const { showMiniDialog } = useAppContext();

    const [token, setToken] = useState<string | undefined>();
    const [passkeys, setPasskeys] = useState<Passkey[]>([]);
    const [showPasskeyDrawer, setShowPasskeyDrawer] = useState(false);
    const [selectedPasskey, setSelectedPasskey] = useState<
        Passkey | undefined
    >();

    const showPasskeyFetchFailedErrorDialog = useCallback(() => {
        showMiniDialog(errorDialogAttributes(t("passkey_fetch_failed")));
    }, [showMiniDialog]);

    useEffect(() => {
        const urlParams = new URLSearchParams(window.location.search);

        const token = urlParams.get("token");
        if (token) {
            setToken(token);
        } else {
            log.error("Missing accounts token");
            showPasskeyFetchFailedErrorDialog();
        }
    }, [showPasskeyFetchFailedErrorDialog]);

    const refreshPasskeys = useCallback(async () => {
        try {
            setPasskeys(await getPasskeys(token!));
        } catch (e) {
            log.error("Failed to fetch passkeys", e);
            showPasskeyFetchFailedErrorDialog();
        }
    }, [token, showPasskeyFetchFailedErrorDialog]);

    useEffect(() => {
        if (token) {
            void refreshPasskeys();
        }
    }, [token, refreshPasskeys]);

    const handleSelectPasskey = (passkey: Passkey) => {
        setSelectedPasskey(passkey);
        setShowPasskeyDrawer(true);
    };

    const handleDrawerClose = () => {
        setShowPasskeyDrawer(false);
        // Don't clear the selected passkey, let the stale value be so that the
        // drawer closing animation is nicer.
        //
        // The value will get overwritten the next time we open the drawer for a
        // different passkey, so this will not have a functional impact.
    };

    const handleUpdateOrDeletePasskey = () => {
        setShowPasskeyDrawer(false);
        setSelectedPasskey(undefined);
        void refreshPasskeys();
    };

    const handleSubmit = async (
        inputValue: string,
        setFieldError: (errorMessage: string) => void,
        resetForm: () => void,
    ) => {
        try {
            await registerPasskey(token!, inputValue);
        } catch (e) {
            log.error("Failed to register a new passkey", e);
            // If the user cancels the operation, then an error with name
            // "NotAllowedError" is thrown.
            //
            // Ignore these, but in other cases add an error indicator to the
            // add passkey text field. The browser is expected to already have
            // shown an error dialog to the user.
            if (!(e instanceof Error && e.name == "NotAllowedError")) {
                setFieldError(t("passkey_add_failed"));
            }
            return;
        }
        await refreshPasskeys();
        resetForm();
    };

    return (
        <Stack sx={{ minHeight: "100svh" }}>
            <AppNavbarNormalFlow />
            <Stack
                sx={{ alignSelf: "center", m: 3, maxWidth: "375px", gap: 3 }}
            >
                <Typography>{t("passkeys_description")}</Typography>
                <Paper sx={{ p: "1rem" }}>
                    <SingleInputForm
                        fieldType="text"
                        placeholder={t("enter_passkey_name")}
                        buttonText={t("add_passkey")}
                        initialValue={""}
                        callback={handleSubmit}
                        submitButtonProps={{ sx: { marginBottom: 1 } }}
                    />
                </Paper>
                <PasskeysList
                    passkeys={passkeys}
                    onSelectPasskey={handleSelectPasskey}
                />
            </Stack>

            <ManagePasskeyDrawer
                open={showPasskeyDrawer}
                onClose={handleDrawerClose}
                passkey={selectedPasskey}
                token={token}
                onUpdateOrDeletePasskey={handleUpdateOrDeletePasskey}
            />
        </Stack>
    );
};

export default Page;

interface PasskeysListProps {
    /** The list of {@link Passkey}s to show. */
    passkeys: Passkey[];
    /**
     * Callback to invoke when an passkey in the list is clicked.
     *
     * It is passed the corresponding {@link Passkey}.
     */
    onSelectPasskey: (passkey: Passkey) => void;
}

const PasskeysList: React.FC<PasskeysListProps> = ({
    passkeys,
    onSelectPasskey,
}) => {
    return (
        <RowButtonGroup>
            {passkeys.map((passkey, i) => (
                <React.Fragment key={passkey.id}>
                    <PasskeyListItem
                        passkey={passkey}
                        onClick={onSelectPasskey}
                    />
                    {i < passkeys.length - 1 && <RowButtonDivider />}
                </React.Fragment>
            ))}
        </RowButtonGroup>
    );
};

interface PasskeyListItemProps {
    /** The passkey to show in the item. */
    passkey: Passkey;
    /**
     * Callback to invoke when the item is clicked.
     *
     * It is passed the item's {@link passkey}.
     */
    onClick: (passkey: Passkey) => void;
}

const PasskeyListItem: React.FC<PasskeyListItemProps> = ({
    passkey,
    onClick,
}) => (
    <RowButton
        startIcon={<KeyIcon />}
        endIcon={<ChevronRightIcon />}
        label={
            <PasskeyLabel>
                <Typography sx={{ fontWeight: "medium" }}>
                    {passkey.friendlyName}
                </Typography>
            </PasskeyLabel>
        }
        onClick={() => onClick(passkey)}
    />
);

const PasskeyLabel = styled("div")`
    /* If the name of the passkey does not fit in one line, break the text into
       multiple lines as necessary */
    white-space: normal;
`;

interface ManagePasskeyDrawerProps {
    /** If `true`, then the drawer is shown. */
    open: boolean;
    /** Callback to invoke when the drawer wants to be closed. */
    onClose: () => void;
    /**
     * The token to use for authenticating with the backend when making requests
     * for editing or deleting passkeys.
     *
     * It is guaranteed that this will be defined when `open` is true.
     */
    token: string | undefined;
    /**
     * The {@link Passkey} whose details should be shown in the drawer.
     *
     * It is guaranteed that this will be defined when `open` is true.
     */
    passkey: Passkey | undefined;
    /**
     * Callback to invoke when the passkey in the modifed or deleted.
     *
     * The passkey that the drawer is showing will be out of date at this point,
     * so the list of passkeys should be refreshed and the drawer closed.
     */
    onUpdateOrDeletePasskey: () => void;
}

const ManagePasskeyDrawer: React.FC<ManagePasskeyDrawerProps> = ({
    open,
    onClose,
    token,
    passkey,
    onUpdateOrDeletePasskey,
}) => {
    const { showMiniDialog } = useAppContext();

    const { show: showRenameDialog, props: renameDialogVisibilityProps } =
        useModalVisibility();

    const handleRenamePasskeySubmit = useCallback(
        async (inputValue: string) => {
            await renamePasskey(token!, passkey!.id, inputValue);
            onUpdateOrDeletePasskey();
        },
        [token, passkey, onUpdateOrDeletePasskey],
    );

    const showDeleteConfirmationDialog = useCallback(
        () =>
            showMiniDialog({
                title: t("delete_passkey"),
                message: t("delete_passkey_confirmation"),
                continue: {
                    text: t("delete"),
                    color: "critical",
                    action: async () => {
                        await deletePasskey(token!, passkey!.id);
                        onUpdateOrDeletePasskey();
                    },
                },
            }),
        [showMiniDialog, token, passkey, onUpdateOrDeletePasskey],
    );

    return (
        <>
            <SidebarDrawer anchor="right" {...{ open, onClose }}>
                {token && passkey && (
                    <Stack sx={{ gap: "4px", py: "12px" }}>
                        <Titlebar
                            onClose={onClose}
                            title={t("manage_passkey")}
                            onRootClose={onClose}
                        />
                        <CreatedAtEntry>
                            {formatDateTimeFull(passkey.createdAt / 1000)}
                        </CreatedAtEntry>
                        <RowButtonGroup>
                            <RowButton
                                startIcon={<EditIcon />}
                                label={t("rename_passkey")}
                                onClick={showRenameDialog}
                            />
                            <RowButtonDivider />
                            <RowButton
                                color="critical"
                                startIcon={<DeleteIcon />}
                                label={t("delete_passkey")}
                                onClick={showDeleteConfirmationDialog}
                            />
                        </RowButtonGroup>
                    </Stack>
                )}
            </SidebarDrawer>
            {token && passkey && (
                <SingleInputDialog
                    {...renameDialogVisibilityProps}
                    title={t("rename_passkey")}
                    label={t("name")}
                    placeholder={t("enter_passkey_name")}
                    autoFocus
                    initialValue={passkey.friendlyName}
                    submitButtonTitle={t("rename")}
                    onSubmit={handleRenamePasskeySubmit}
                />
            )}
        </>
    );
};

const CreatedAtEntry: React.FC<React.PropsWithChildren> = ({ children }) => (
    <Stack direction="row" sx={{ alignItems: "center", gap: 0.5, pb: 1 }}>
        <CalendarTodayIcon color="secondary" sx={{ m: "16px" }} />
        <Box sx={{ py: 0.5 }}>
            <Typography>{t("created_at")}</Typography>
            <Typography variant="small" sx={{ color: "text.muted" }}>
                {children}
            </Typography>
        </Box>
    </Stack>
);
