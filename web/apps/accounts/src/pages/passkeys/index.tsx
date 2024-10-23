import { EnteDrawer } from "@/base/components/EnteDrawer";
import { MenuItemDivider, MenuItemGroup } from "@/base/components/Menu";
import { Titlebar } from "@/base/components/Titlebar";
import { errorDialogAttributes } from "@/base/components/utils/dialog";
import log from "@/base/log";
import { ensure } from "@/utils/ensure";
import { CenteredFlex } from "@ente/shared/components/Container";
import FormPaper from "@ente/shared/components/Form/FormPaper";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import SingleInputForm from "@ente/shared/components/SingleInputForm";
import { formatDateTimeFull } from "@ente/shared/time/format";
import CalendarTodayIcon from "@mui/icons-material/CalendarToday";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import DeleteIcon from "@mui/icons-material/Delete";
import EditIcon from "@mui/icons-material/Edit";
import KeyIcon from "@mui/icons-material/Key";
import {
    Box,
    Dialog,
    Stack,
    Typography,
    styled,
    useMediaQuery,
    useTheme,
} from "@mui/material";
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
    const { showNavBar, showMiniDialog } = useAppContext();

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
    const labelComponent = (
        <PasskeyLabel>
            <Typography fontWeight="bold">{passkey.friendlyName}</Typography>
        </PasskeyLabel>
    );
    return (
        <EnteMenuItem
            onClick={() => onClick(passkey)}
            startIcon={<KeyIcon />}
            endIcon={<ChevronRightIcon />}
            labelComponent={labelComponent}
        />
    );
};

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

    const [showRenameDialog, setShowRenameDialog] = useState(false);

    const showDeleteConfirmationDialog = useCallback(
        () =>
            showMiniDialog({
                title: t("delete_passkey"),
                message: t("delete_passkey_confirmation"),
                continue: {
                    text: t("delete"),
                    color: "critical",
                    action: async () => {
                        await deletePasskey(ensure(token), ensure(passkey).id);
                        onUpdateOrDeletePasskey();
                    },
                },
            }),
        [showMiniDialog, token, passkey, onUpdateOrDeletePasskey],
    );

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
                        <CreatedAtEntry>
                            {formatDateTimeFull(passkey.createdAt / 1000)}
                        </CreatedAtEntry>
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
                                onClick={showDeleteConfirmationDialog}
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
        </>
    );
};

const CreatedAtEntry: React.FC<React.PropsWithChildren> = ({ children }) => (
    <Box sx={{ display: "flex", alignItems: "center", gap: 0.5, pb: 1 }}>
        <CalendarTodayIcon color="secondary" sx={{ m: "16px" }} />
        <Box py={0.5}>
            <Typography>{t("created_at")}</Typography>
            <Typography variant="small" color="text.muted">
                {children}
            </Typography>
        </Box>
    </Box>
);

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
    const fullScreen = useMediaQuery(useTheme().breakpoints.down("sm"));

    const handleSubmit = async (inputValue: string) => {
        try {
            await renamePasskey(token, passkey.id, inputValue);
            onRenamePasskey();
        } catch (e) {
            log.error("Failed to rename passkey", e);
        }
    };

    return (
        <Dialog
            {...{ open, onClose, fullScreen }}
            PaperProps={{ sx: { width: { sm: "360px" } } }}
        >
            <Stack gap={3} p={3}>
                <Typography variant="large" fontWeight={"bold"}>
                    {t("rename_passkey")}
                </Typography>
                <SingleInputForm
                    initialValue={passkey.friendlyName}
                    callback={handleSubmit}
                    placeholder={t("enter_passkey_name")}
                    buttonText={t("rename")}
                    fieldType="text"
                    secondaryButtonAction={onClose}
                    submitButtonProps={{ sx: { mt: 1, mb: 0 } }}
                />
            </Stack>
        </Dialog>
    );
};
