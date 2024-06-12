import log from "@/next/log";
import { ensure } from "@/utils/ensure";
import { CenteredFlex } from "@ente/shared/components/Container";
import DialogBoxV2 from "@ente/shared/components/DialogBoxV2";
import EnteButton from "@ente/shared/components/EnteButton";
import { EnteDrawer } from "@ente/shared/components/EnteDrawer";
import FormPaper from "@ente/shared/components/Form/FormPaper";
import InfoItem from "@ente/shared/components/Info/InfoItem";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import MenuItemDivider from "@ente/shared/components/Menu/MenuItemDivider";
import { MenuItemGroup } from "@ente/shared/components/Menu/MenuItemGroup";
import SingleInputForm from "@ente/shared/components/SingleInputForm";
import Titlebar from "@ente/shared/components/Titlebar";
import { formatDateTimeFull } from "@ente/shared/time/format";
import CalendarTodayIcon from "@mui/icons-material/CalendarToday";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import DeleteIcon from "@mui/icons-material/Delete";
import EditIcon from "@mui/icons-material/Edit";
import KeyIcon from "@mui/icons-material/Key";
import { Box, Button, Stack, Typography, useMediaQuery } from "@mui/material";
import { useAppContext } from "components/context";
import { t } from "i18next";
import React, { useCallback, useEffect, useState } from "react";
import {
    deletePasskey,
    getPasskeys,
    registerPasskey,
    renamePasskey,
    type Passkey,
} from "services/passkey";

const Page: React.FC = () => {
    const { showNavBar, setDialogBoxAttributesV2 } = useAppContext();

    const [token, setToken] = useState<string | undefined>();
    const [passkeys, setPasskeys] = useState<Passkey[]>([]);
    const [showPasskeyDrawer, setShowPasskeyDrawer] = useState(false);
    const [selectedPasskey, setSelectedPasskey] = useState<
        Passkey | undefined
    >();

    const showPasskeyFetchFailedErrorDialog = useCallback(() => {
        setDialogBoxAttributesV2({
            title: t("ERROR"),
            content: t("passkey_fetch_failed"),
            close: {},
        });
    }, [setDialogBoxAttributesV2]);

    useEffect(() => {
        showNavBar(true);

        const urlParams = new URLSearchParams(window.location.search);

        const token = urlParams.get("token");
        if (token) {
            setToken(token);
        } else {
            log.error("Missing accounts token");
            showPasskeyFetchFailedErrorDialog();
        }
    }, [showNavBar, showPasskeyFetchFailedErrorDialog]);

    const refreshPasskeys = useCallback(async () => {
        try {
            setPasskeys(await getPasskeys(ensure(token)));
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
            await registerPasskey(ensure(token), inputValue);
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
        <>
            <CenteredFlex>
                <Box maxWidth="20rem">
                    <Box marginBottom="1rem">
                        <Typography>{t("passkeys_description")}</Typography>
                    </Box>
                    <FormPaper style={{ padding: "1rem" }}>
                        <SingleInputForm
                            fieldType="text"
                            placeholder={t("enter_passkey_name")}
                            buttonText={t("add_passkey")}
                            initialValue={""}
                            callback={handleSubmit}
                            submitButtonProps={{ sx: { marginBottom: 1 } }}
                        />
                    </FormPaper>
                    <Box marginTop="1rem">
                        <PasskeysList
                            passkeys={passkeys}
                            onSelectPasskey={handleSelectPasskey}
                        />
                    </Box>
                </Box>
            </CenteredFlex>

            <ManagePasskeyDrawer
                open={showPasskeyDrawer}
                onClose={handleDrawerClose}
                passkey={selectedPasskey}
                token={token}
                onUpdateOrDeletePasskey={handleUpdateOrDeletePasskey}
            />
        </>
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
        <MenuItemGroup>
            {passkeys.map((passkey, i) => (
                <React.Fragment key={passkey.id}>
                    <PasskeyListItem
                        passkey={passkey}
                        onClick={onSelectPasskey}
                    />
                    {i < passkeys.length - 1 && <MenuItemDivider />}
                </React.Fragment>
            ))}
        </MenuItemGroup>
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
}) => {
    return (
        <EnteMenuItem
            onClick={() => onClick(passkey)}
            startIcon={<KeyIcon />}
            endIcon={<ChevronRightIcon />}
            label={passkey.friendlyName}
        />
    );
};

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
    const [showRenameDialog, setShowRenameDialog] = useState(false);
    const [showDeleteDialog, setShowDeleteDialog] = useState(false);

    return (
        <>
            <EnteDrawer anchor="right" {...{ open, onClose }}>
                {token && passkey && (
                    <Stack spacing={"4px"} py={"12px"}>
                        <Titlebar
                            onClose={onClose}
                            title={t("manage_passkey")}
                            onRootClose={onClose}
                        />
                        <InfoItem
                            icon={<CalendarTodayIcon />}
                            title={t("CREATED_AT")}
                            caption={formatDateTimeFull(
                                passkey.createdAt / 1000,
                            )}
                            loading={false}
                            hideEditOption
                        />
                        <MenuItemGroup>
                            <EnteMenuItem
                                onClick={() => {
                                    setShowRenameDialog(true);
                                }}
                                startIcon={<EditIcon />}
                                label={t("rename_passkey")}
                            />
                            <MenuItemDivider />
                            <EnteMenuItem
                                onClick={() => {
                                    setShowDeleteDialog(true);
                                }}
                                startIcon={<DeleteIcon />}
                                label={t("delete_passkey")}
                                color="critical"
                            />
                        </MenuItemGroup>
                    </Stack>
                )}
            </EnteDrawer>

            {token && passkey && (
                <RenamePasskeyDialog
                    open={showRenameDialog}
                    onClose={() => setShowRenameDialog(false)}
                    token={token}
                    passkey={passkey}
                    onRenamePasskey={() => {
                        setShowRenameDialog(false);
                        onUpdateOrDeletePasskey();
                    }}
                />
            )}

            {token && passkey && (
                <DeletePasskeyDialog
                    open={showDeleteDialog}
                    onClose={() => setShowDeleteDialog(false)}
                    token={token}
                    passkey={passkey}
                    onDeletePasskey={() => {
                        setShowDeleteDialog(false);
                        onUpdateOrDeletePasskey();
                    }}
                />
            )}
        </>
    );
};

interface RenamePasskeyDialogProps {
    /** If `true`, then the dialog is shown. */
    open: boolean;
    /** Callback to invoke when the dialog wants to be closed. */
    onClose: () => void;
    /** Auth token for API requests. */
    token: string;
    /** The {@link Passkey} to rename. */
    passkey: Passkey;
    /** Callback to invoke when the passkey is renamed. */
    onRenamePasskey: () => void;
}

const RenamePasskeyDialog: React.FC<RenamePasskeyDialogProps> = ({
    open,
    onClose,
    token,
    passkey,
    onRenamePasskey,
}) => {
    const fullScreen = useMediaQuery("(max-width: 428px)");

    const handleSubmit = async (inputValue: string) => {
        try {
            await renamePasskey(token, passkey.id, inputValue);
            onRenamePasskey();
        } catch (e) {
            log.error("Failed to rename passkey", e);
        }
    };

    return (
        <DialogBoxV2
            fullWidth
            {...{ open, onClose, fullScreen }}
            attributes={{ title: t("rename_passkey") }}
        >
            <SingleInputForm
                initialValue={passkey.friendlyName}
                callback={handleSubmit}
                placeholder={t("enter_passkey_name")}
                buttonText={t("RENAME")}
                fieldType="text"
                secondaryButtonAction={onClose}
                submitButtonProps={{ sx: { mt: 1, mb: 2 } }}
            />
        </DialogBoxV2>
    );
};

interface DeletePasskeyDialogProps {
    /** If `true`, then the dialog is shown. */
    open: boolean;
    /** Callback to invoke when the dialog wants to be closed. */
    onClose: () => void;
    /** Auth token for API requests. */
    token: string;
    /** The {@link Passkey} to delete. */
    passkey: Passkey;
    /** Callback to invoke when the passkey is deleted. */
    onDeletePasskey: () => void;
}

const DeletePasskeyDialog: React.FC<DeletePasskeyDialogProps> = ({
    open,
    onClose,
    token,
    passkey,
    onDeletePasskey,
}) => {
    const [isDeleting, setIsDeleting] = useState(false);
    const fullScreen = useMediaQuery("(max-width: 428px)");

    const handleConfirm = async () => {
        setIsDeleting(true);
        try {
            await deletePasskey(token, passkey.id);
            onDeletePasskey();
        } catch (e) {
            log.error("Failed to delete passkey", e);
        } finally {
            setIsDeleting(false);
        }
    };

    return (
        <DialogBoxV2
            fullWidth
            {...{ open, onClose, fullScreen }}
            attributes={{ title: t("delete_passkey") }}
        >
            <Stack spacing={"8px"}>
                <Typography>{t("delete_passkey_confirmation")}</Typography>
                <EnteButton
                    type="submit"
                    size="large"
                    color="critical"
                    loading={isDeleting}
                    onClick={handleConfirm}
                >
                    {t("DELETE")}
                </EnteButton>
                <Button size="large" color={"secondary"} onClick={onClose}>
                    {t("CANCEL")}
                </Button>
            </Stack>
        </DialogBoxV2>
    );
};
