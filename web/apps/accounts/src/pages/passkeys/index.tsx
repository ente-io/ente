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
import { ACCOUNTS_PAGES } from "@ente/shared/constants/pages";
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
import {
    Fragment,
    createContext,
    useContext,
    useEffect,
    useState,
} from "react";
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

const Passkeys = () => {
    const { showNavBar } = useAppContext();

    const [selectedPasskey, setSelectedPasskey] = useState<Passkey | null>(
        null,
    );

    const [showPasskeyDrawer, setShowPasskeyDrawer] = useState(false);

    const [passkeys, setPasskeys] = useState<Passkey[]>([]);

    const router = useRouter();

    const checkLoggedIn = () => {
        const token = getToken();
        if (!token) {
            router.push(ACCOUNTS_PAGES.LOGIN);
        }
    };

    const init = async () => {
        checkLoggedIn();
        const data = await getPasskeys();
        setPasskeys(data.passkeys || []);
    };

    useEffect(() => {
        showNavBar(true);
        init();
    }, []);

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

        await init();
        resetForm();
    };

    return (
        <>
            <PasskeysContext.Provider
                value={{
                    selectedPasskey,
                    setSelectedPasskey,
                    setShowPasskeyDrawer,
                    refreshPasskeys: init,
                }}
            >
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
                            <PasskeysList passkeys={passkeys} />
                        </Box>
                    </Box>
                </CenteredFlex>
                <ManagePasskeyDrawer open={showPasskeyDrawer} />
            </PasskeysContext.Provider>
        </>
    );
};

export default Passkeys;

interface PasskeysListProps {
    passkeys: Passkey[];
}

const PasskeysList: React.FC<PasskeysListProps> = ({ passkeys }) => {
    return (
        <>
            <MenuItemGroup>
                {passkeys.map((passkey, i) => (
                    <Fragment key={passkey.id}>
                        <PasskeyListItem passkey={passkey} />
                        {i < passkeys.length - 1 && <MenuItemDivider />}
                    </Fragment>
                ))}
            </MenuItemGroup>
        </>
    );
};

interface PasskeyListItemProps {
    passkey: Passkey;
}

const PasskeyListItem: React.FC<PasskeyListItemProps> = ({ passkey }) => {
    const { setSelectedPasskey, setShowPasskeyDrawer } =
        useContext(PasskeysContext);

    return (
        <EnteMenuItem
            onClick={() => {
                setSelectedPasskey(passkey);
                setShowPasskeyDrawer(true);
            }}
            startIcon={<KeyIcon />}
            endIcon={<ChevronRightIcon />}
            label={passkey?.friendlyName}
        />
    );
};

interface ManagePasskeyDrawerProps {
    open: boolean;
}

const ManagePasskeyDrawer: React.FC<ManagePasskeyDrawerProps> = (props) => {
    const { setShowPasskeyDrawer, refreshPasskeys, selectedPasskey } =
        useContext(PasskeysContext);

    const [showDeletePasskeyModal, setShowDeletePasskeyModal] = useState(false);
    const [showRenamePasskeyModal, setShowRenamePasskeyModal] = useState(false);

    return (
        <>
            <EnteDrawer
                anchor="right"
                open={props.open}
                onClose={() => {
                    setShowPasskeyDrawer(false);
                }}
            >
                {selectedPasskey && (
                    <>
                        <Stack spacing={"4px"} py={"12px"}>
                            <Titlebar
                                onClose={() => {
                                    setShowPasskeyDrawer(false);
                                }}
                                title="Manage Passkey"
                                onRootClose={() => {
                                    setShowPasskeyDrawer(false);
                                }}
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
