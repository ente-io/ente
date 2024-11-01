import { disableTwoFactor } from "@/accounts/api/user";
import type { ModalVisibilityProps } from "@/base/components/utils/modal";
import { AppContext } from "@/new/photos/types/context";
import { VerticallyCentered } from "@ente/shared/components/Container";
import DialogTitleWithCloseButton from "@ente/shared/components/DialogBox/TitleWithCloseButton";
import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import { LS_KEYS, getData, setLSUser } from "@ente/shared/storage/localStorage";
import LockIcon from "@mui/icons-material/Lock";
import {
    Button,
    Dialog,
    DialogContent,
    Grid,
    Typography,
    styled,
} from "@mui/material";
import { t } from "i18next";
import router, { useRouter } from "next/router";
import { useContext, useEffect, useState } from "react";
import { getTwoFactorStatus } from "services/userService";

const TwoFactorDialog = styled(Dialog)(({ theme }) => ({
    "& .MuiDialogContent-root": {
        padding: theme.spacing(2, 4),
    },
}));

type Props = ModalVisibilityProps & {
    closeSidebar: () => void;
};

function TwoFactorModal(props: Props) {
    const [isTwoFactorEnabled, setTwoFactorStatus] = useState(false);

    useEffect(() => {
        const isTwoFactorEnabled =
            getData(LS_KEYS.USER).isTwoFactorEnabled ?? false;
        setTwoFactorStatus(isTwoFactorEnabled);
    }, []);

    useEffect(() => {
        if (!props.open) {
            return;
        }
        const main = async () => {
            const isTwoFactorEnabled = await getTwoFactorStatus();
            setTwoFactorStatus(isTwoFactorEnabled);
            await setLSUser({
                ...getData(LS_KEYS.USER),
                isTwoFactorEnabled,
            });
        };
        main();
    }, [props.open]);

    const closeDialog = () => {
        props.onClose();
        props.closeSidebar();
    };

    return (
        <TwoFactorDialog
            maxWidth="xs"
            open={props.open}
            onClose={props.onClose}
        >
            <DialogTitleWithCloseButton onClose={props.onClose}>
                {t("TWO_FACTOR_AUTHENTICATION")}
            </DialogTitleWithCloseButton>
            <DialogContent sx={{ px: 4 }}>
                {isTwoFactorEnabled ? (
                    <TwoFactorModalManageSection closeDialog={closeDialog} />
                ) : (
                    <TwoFactorModalSetupSection closeDialog={closeDialog} />
                )}
            </DialogContent>
        </TwoFactorDialog>
    );
}

export default TwoFactorModal;

interface TwoFactorModalSetupSectionProps {
    closeDialog: () => void;
}

function TwoFactorModalSetupSection({
    closeDialog,
}: TwoFactorModalSetupSectionProps) {
    const router = useRouter();
    const redirectToTwoFactorSetup = () => {
        closeDialog();
        router.push(PAGES.TWO_FACTOR_SETUP);
    };

    return (
        <VerticallyCentered sx={{ mb: 2 }}>
            <LockIcon sx={{ fontSize: (theme) => theme.spacing(5), mb: 2 }} />
            <Typography mb={4}>{t("TWO_FACTOR_INFO")}</Typography>
            <Button
                variant="contained"
                color="accent"
                size="large"
                onClick={redirectToTwoFactorSetup}
            >
                {t("ENABLE_TWO_FACTOR")}
            </Button>
        </VerticallyCentered>
    );
}

interface TwoFactorModalManageSectionProps {
    closeDialog: () => void;
}

function TwoFactorModalManageSection(props: TwoFactorModalManageSectionProps) {
    const { closeDialog } = props;
    const { setDialogMessage } = useContext(AppContext);

    const warnTwoFactorDisable = async () => {
        setDialogMessage({
            title: t("DISABLE_TWO_FACTOR"),

            content: t("DISABLE_TWO_FACTOR_MESSAGE"),
            close: { text: t("cancel") },
            proceed: {
                variant: "critical",
                text: t("disable"),
                action: twoFactorDisable,
            },
        });
    };

    const twoFactorDisable = async () => {
        try {
            await disableTwoFactor();
            await setLSUser({
                ...getData(LS_KEYS.USER),
                isTwoFactorEnabled: false,
            });
            closeDialog();
        } catch (e) {
            setDialogMessage({
                title: t("TWO_FACTOR_DISABLE_FAILED"),
                close: {},
            });
        }
    };

    const warnTwoFactorReconfigure = async () => {
        setDialogMessage({
            title: t("UPDATE_TWO_FACTOR"),

            content: t("UPDATE_TWO_FACTOR_MESSAGE"),
            close: { text: t("cancel") },
            proceed: {
                variant: "accent",
                text: t("UPDATE"),
                action: reconfigureTwoFactor,
            },
        });
    };

    const reconfigureTwoFactor = async () => {
        closeDialog();
        router.push(PAGES.TWO_FACTOR_SETUP);
    };

    return (
        <>
            <Grid
                mb={1.5}
                rowSpacing={1}
                container
                alignItems="center"
                justifyContent="center"
            >
                <Grid item sm={9} xs={12}>
                    {t("UPDATE_TWO_FACTOR_LABEL")}
                </Grid>
                <Grid item sm={3} xs={12}>
                    <Button
                        color={"accent"}
                        onClick={warnTwoFactorReconfigure}
                        size="large"
                    >
                        {t("reconfigure")}
                    </Button>
                </Grid>
            </Grid>
            <Grid
                rowSpacing={1}
                container
                alignItems="center"
                justifyContent="center"
            >
                <Grid item sm={9} xs={12}>
                    {t("DISABLE_TWO_FACTOR_LABEL")}{" "}
                </Grid>

                <Grid item sm={3} xs={12}>
                    <Button
                        color="critical"
                        onClick={warnTwoFactorDisable}
                        size="large"
                    >
                        {t("disable")}
                    </Button>
                </Grid>
            </Grid>
        </>
    );
}
