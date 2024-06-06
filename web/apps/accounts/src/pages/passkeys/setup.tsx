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
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import { formatDateTimeFull } from "@ente/shared/time/format";
import CalendarTodayIcon from "@mui/icons-material/CalendarToday";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
import DeleteIcon from "@mui/icons-material/Delete";
import EditIcon from "@mui/icons-material/Edit";
import KeyIcon from "@mui/icons-material/Key";
import { Box, Button, Stack, Typography, useMediaQuery } from "@mui/material";
import { t } from "i18next";
import _sodium from "libsodium-wrappers";
import { useRouter } from "next/router";
import { useAppContext } from "pages/_app";
import type { Dispatch, SetStateAction } from "react";
import React, { createContext, useContext, useEffect, useState } from "react";
import { deletePasskey, renamePasskey } from "services/passkey";
import {
    finishPasskeyRegistration,
    getPasskeyRegistrationOptions,
    getPasskeys,
    type Passkey,
} from "../../services/passkey";

export const PasskeysContext = createContext(
    {} as {
        selectedPasskey: Passkey | null;
        setSelectedPasskey: Dispatch<SetStateAction<Passkey | null>>;
        setShowPasskeyDrawer: Dispatch<SetStateAction<boolean>>;
        refreshPasskeys: () => void;
    },
);
{
    /* <PasskeysContext.Provider
value={{
    selectedPasskey,
    setSelectedPasskey,
    setShowPasskeyDrawer,
    refreshPasskeys: init,
}}
>
</PasskeysContext.Provider> */
}

const Page: React.FC = () => {
    const { showNavBar } = useAppContext();

    const [passkeys, setPasskeys] = useState<Passkey[]>([]);
    const [selectedPasskey, setSelectedPasskey] = useState<
        Passkey | undefined
    >();

    const router = useRouter();

    const refreshPasskeys = async () => {
        const data = await getPasskeys();
        setPasskeys(data.passkeys || []);
    };

    useEffect(() => {
        if (!getToken()) {
            router.push("/login");
            return;
        }

        showNavBar(true);
        void refreshPasskeys();
    }, []);

    const handleSelectPasskey = (passkey: Passkey) =>
        setSelectedPasskey(passkey);

    const shouldOpenDrawer = selectedPasskey !== undefined;
    const handleDrawerClose = () => setSelectedPasskey(undefined);

    const handleSubmit = async (
        inputValue: string,
        setFieldError: (errorMessage: string) => void,
        resetForm: () => void,
    ) => {
        let response: {
            options: {
                publicKey: PublicKeyCredentialCreationOptions;
            };
            sessionID: string;
        };

        try {
            response = await getPasskeyRegistrationOptions();
        } catch {
            setFieldError("Failed to begin registration");
            return;
        }

        const options = response.options;

        // TODO-PK: The types don't match.
        options.publicKey.challenge = _sodium.from_base64(
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            options.publicKey.challenge,
        );
        options.publicKey.user.id = _sodium.from_base64(
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            options.publicKey.user.id,
        );

        // create new credential
        let newCredential: Credential;

        try {
            newCredential = ensure(await navigator.credentials.create(options));
        } catch (e) {
            log.error("Error creating credential", e);
            setFieldError("Failed to create credential");
            return;
        }

        try {
            await finishPasskeyRegistration(
                inputValue,
                newCredential,
                response.sessionID,
            );
        } catch {
            setFieldError("Failed to finish registration");
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
                        <Typography>{t("PASSKEYS_DESCRIPTION")}</Typography>
                    </Box>
                    <FormPaper
                        style={{
                            padding: "1rem",
                        }}
                    >
                        <SingleInputForm
                            fieldType="text"
                            placeholder={t("ENTER_PASSKEY_NAME")}
                            buttonText={t("ADD_PASSKEY")}
                            initialValue={""}
                            callback={handleSubmit}
                            submitButtonProps={{
                                sx: {
                                    marginBottom: 1,
                                },
                            }}
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
                open={shouldOpenDrawer}
                onClose={handleDrawerClose}
                selectedPasskey={selectedPasskey}
                refreshPasskeys={() => void refreshPasskeys}
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
    /*** Callback to invoke when the drawer wants to be closed. */
    onClose: () => void;
    /** The {@link Passkey} whose details should be shown in the drawer. */
    selectedPasskey: Passkey | undefined;
    refreshPasskeys: () => void;
}

const ManagePasskeyDrawer: React.FC<ManagePasskeyDrawerProps> = ({
    open,
    onClose,
    selectedPasskey,
    refreshPasskeys,
}) => {
    const [showDeletePasskeyModal, setShowDeletePasskeyModal] = useState(false);
    const [showRenamePasskeyModal, setShowRenamePasskeyModal] = useState(false);

    return (
        <>
            <EnteDrawer anchor="right" open={open} onClose={onClose}>
                {selectedPasskey && (
                    <>
                        <Stack spacing={"4px"} py={"12px"}>
                            <Titlebar
                                onClose={onClose}
                                title="Manage Passkey"
                                onRootClose={onClose}
                            />
                            <InfoItem
                                icon={<CalendarTodayIcon />}
                                title={t("CREATED_AT")}
                                caption={
                                    `${formatDateTimeFull(
                                        selectedPasskey.createdAt / 1000,
                                    )}` || ""
                                }
                                loading={!selectedPasskey}
                                hideEditOption
                            />
                            <MenuItemGroup>
                                <EnteMenuItem
                                    onClick={() => {
                                        setShowRenamePasskeyModal(true);
                                    }}
                                    startIcon={<EditIcon />}
                                    label={"Rename Passkey"}
                                />
                                <MenuItemDivider />
                                <EnteMenuItem
                                    onClick={() => {
                                        setShowDeletePasskeyModal(true);
                                    }}
                                    startIcon={<DeleteIcon />}
                                    label={"Delete Passkey"}
                                    color="critical"
                                />
                            </MenuItemGroup>
                        </Stack>
                    </>
                )}
            </EnteDrawer>
            <DeletePasskeyModal
                open={showDeletePasskeyModal}
                onClose={() => {
                    setShowDeletePasskeyModal(false);
                    refreshPasskeys();
                }}
            />
            <RenamePasskeyModal
                open={showRenamePasskeyModal}
                onClose={() => {
                    setShowRenamePasskeyModal(false);
                    refreshPasskeys();
                }}
            />
        </>
    );
};

interface DeletePasskeyModalProps {
    open: boolean;
    onClose: () => void;
}

const DeletePasskeyModal: React.FC<DeletePasskeyModalProps> = (props) => {
    const { selectedPasskey, setShowPasskeyDrawer } =
        useContext(PasskeysContext);

    const [loading, setLoading] = useState(false);

    const isMobile = useMediaQuery("(max-width: 428px)");

    const doDelete = async () => {
        if (!selectedPasskey) return;
        setLoading(true);
        try {
            await deletePasskey(selectedPasskey.id);
        } catch (error) {
            console.error(error);
            return;
        } finally {
            setLoading(false);
        }
        props.onClose();
        setShowPasskeyDrawer(false);
    };

    return (
        <DialogBoxV2
            fullWidth
            open={props.open}
            onClose={props.onClose}
            fullScreen={isMobile}
            attributes={{
                title: t("DELETE_PASSKEY"),
                secondary: {
                    action: props.onClose,
                    text: t("CANCEL"),
                },
            }}
        >
            <Stack spacing={"8px"}>
                <Typography>{t("DELETE_PASSKEY_CONFIRMATION")}</Typography>
                <EnteButton
                    type="submit"
                    size="large"
                    color="critical"
                    loading={loading}
                    onClick={doDelete}
                >
                    {t("DELETE")}
                </EnteButton>
                <Button
                    size="large"
                    color={"secondary"}
                    onClick={props.onClose}
                >
                    {t("CANCEL")}
                </Button>
            </Stack>
        </DialogBoxV2>
    );
};

interface RenamePasskeyModalProps {
    open: boolean;
    onClose: () => void;
}

const RenamePasskeyModal: React.FC<RenamePasskeyModalProps> = (props) => {
    const { selectedPasskey } = useContext(PasskeysContext);

    const isMobile = useMediaQuery("(max-width: 428px)");

    const onSubmit = async (inputValue: string) => {
        if (!selectedPasskey) return;
        try {
            await renamePasskey(selectedPasskey.id, inputValue);
        } catch (error) {
            console.error(error);
            return;
        }

        props.onClose();
    };

    return (
        <DialogBoxV2
            fullWidth
            open={props.open}
            onClose={props.onClose}
            fullScreen={isMobile}
            attributes={{
                title: t("RENAME_PASSKEY"),
                secondary: {
                    action: props.onClose,
                    text: t("CANCEL"),
                },
            }}
        >
            <SingleInputForm
                initialValue={selectedPasskey?.friendlyName}
                callback={onSubmit}
                placeholder={t("ENTER_PASSKEY_NAME")}
                buttonText={t("RENAME")}
                fieldType="text"
                secondaryButtonAction={props.onClose}
                submitButtonProps={{ sx: { mt: 1, mb: 2 } }}
            />
        </DialogBoxV2>
    );
};
