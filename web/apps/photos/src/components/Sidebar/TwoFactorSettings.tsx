import { disableTwoFactor } from "@/accounts/api/user";
import {
    NestedSidebarDrawer,
    SidebarDrawerTitlebar,
    type NestedSidebarDrawerVisibilityProps,
} from "@/base/components/mui/SidebarDrawer";
import { AppContext } from "@/new/photos/types/context";
import { VerticallyCentered } from "@ente/shared/components/Container";
import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import { LS_KEYS, getData, setLSUser } from "@ente/shared/storage/localStorage";
import LockIcon from "@mui/icons-material/Lock";
import { Button, Grid, Stack, Typography } from "@mui/material";
import { t } from "i18next";
import router, { useRouter } from "next/router";
import { useContext, useEffect, useState } from "react";
import { getTwoFactorStatus } from "services/userService";

// TODO: Revisit these comments
// const TwoFactorDialog = styled(Dialog)(({ theme }) => ({
//     "& .MuiDialogContent-root": {
//         padding: theme.spacing(2, 4),
//     },
// }));

// type TwoFactorModalProps = ModalVisibilityProps & {
//     closeSidebar: () => void;
// };

export const TwoFactorSettings: React.FC<
    NestedSidebarDrawerVisibilityProps
> = ({ open, onClose, onRootClose }) => {
    const [isTwoFactorEnabled, setTwoFactorStatus] = useState(false);

    useEffect(() => {
        const isTwoFactorEnabled =
            getData(LS_KEYS.USER).isTwoFactorEnabled ?? false;
        setTwoFactorStatus(isTwoFactorEnabled);
    }, []);

    useEffect(() => {
        if (!open) {
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
    }, [open]);

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    return (
        <NestedSidebarDrawer
            {...{ open, onClose }}
            onRootClose={handleRootClose}
        >
            <Stack sx={{ gap: "4px", py: "12px" }}>
                <SidebarDrawerTitlebar
                    onClose={onClose}
                    onRootClose={handleRootClose}
                    title={t("TWO_FACTOR_AUTHENTICATION")}
                />
                {/* {component} */}

                {/* <DialogContent sx={{ px: 4 }}> */}
                {isTwoFactorEnabled ? (
                    <TwoFactorModalManageSection
                        closeDialog={handleRootClose}
                    />
                ) : (
                    <TwoFactorModalSetupSection closeDialog={handleRootClose} />
                )}
                {/* </DialogContent> */}
            </Stack>
        </NestedSidebarDrawer>
    );
};

export default TwoFactorSettings;

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
