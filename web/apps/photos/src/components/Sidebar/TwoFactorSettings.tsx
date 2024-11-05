import { disableTwoFactor } from "@/accounts/api/user";
import { MenuItemGroup, MenuSectionTitle } from "@/base/components/Menu";
import {
    NestedSidebarDrawer,
    SidebarDrawerTitlebar,
    type NestedSidebarDrawerVisibilityProps,
} from "@/base/components/mui/SidebarDrawer";
import { useAppContext } from "@/new/photos/types/context";
import { VerticallyCentered } from "@ente/shared/components/Container";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import { LS_KEYS, getData, setLSUser } from "@ente/shared/storage/localStorage";
import LockIcon from "@mui/icons-material/Lock";
import { Button, Stack, Typography } from "@mui/material";
import { t } from "i18next";
import router, { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { getTwoFactorStatus } from "services/userService";

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

                {isTwoFactorEnabled ? (
                    <TwoFactorModalManageSection
                        closeDialog={handleRootClose}
                    />
                ) : (
                    <TwoFactorModalSetupSection closeDialog={handleRootClose} />
                )}
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
    const { showMiniDialog, setDialogMessage } = useAppContext();

    const confirmDisable = () =>
        showMiniDialog({
            title: t("DISABLE_TWO_FACTOR"),
            message: t("DISABLE_TWO_FACTOR_MESSAGE"),
            continue: {
                text: t("disable"),
                color: "critical",
                action: disable,
            },
        });

    const disable = async () => {
        await disableTwoFactor();
        await setLSUser({
            ...getData(LS_KEYS.USER),
            isTwoFactorEnabled: false,
        });
        closeDialog();
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
        <Stack sx={{ px: "16px", py: "20px", gap: "24px" }}>
            <MenuItemGroup>
                <EnteMenuItem
                    onClick={confirmDisable}
                    variant="toggle"
                    checked={true}
                    label={t("enabled")}
                />
            </MenuItemGroup>

            <div>
                <MenuItemGroup>
                    <EnteMenuItem
                        onClick={warnTwoFactorReconfigure}
                        variant="primary"
                        checked={true}
                        label={t("reconfigure")}
                    />
                </MenuItemGroup>
                <MenuSectionTitle title={t("UPDATE_TWO_FACTOR_LABEL")} />
            </div>
        </Stack>
    );
}
