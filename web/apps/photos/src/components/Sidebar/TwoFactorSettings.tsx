import { disableTwoFactor } from "@/accounts/api/user";
import { MenuItemGroup, MenuSectionTitle } from "@/base/components/Menu";
import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import {
    NestedSidebarDrawer,
    SidebarDrawerTitlebar,
    type NestedSidebarDrawerVisibilityProps,
} from "@/base/components/mui/SidebarDrawer";
import { useAppContext } from "@/new/photos/types/context";
import { EnteMenuItem } from "@ente/shared/components/Menu/EnteMenuItem";
import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import { LS_KEYS, getData, setLSUser } from "@ente/shared/storage/localStorage";
import LockIcon from "@mui/icons-material/Lock";
import { Stack, Typography } from "@mui/material";
import { t } from "i18next";
import router, { useRouter } from "next/router";
import { useEffect, useState } from "react";
import { getTwoFactorStatus } from "services/userService";

export const TwoFactorSettings: React.FC<
    NestedSidebarDrawerVisibilityProps
> = ({ open, onClose, onRootClose }) => {
    const [isTwoFactorEnabled, setIsTwoFactorEnabled] = useState(false);

    useEffect(() => {
        const isTwoFactorEnabled =
            getData(LS_KEYS.USER).isTwoFactorEnabled ?? false;
        setIsTwoFactorEnabled(isTwoFactorEnabled);
    }, []);

    useEffect(() => {
        if (!open) {
            return;
        }
        const main = async () => {
            const isTwoFactorEnabled = await getTwoFactorStatus();
            setIsTwoFactorEnabled(isTwoFactorEnabled);
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
                    <ManageDrawerContents onRootClose={handleRootClose} />
                ) : (
                    <SetupDrawerContents onRootClose={handleRootClose} />
                )}
            </Stack>
        </NestedSidebarDrawer>
    );
};

export default TwoFactorSettings;

type ContentsProps = Pick<NestedSidebarDrawerVisibilityProps, "onRootClose">;

const SetupDrawerContents: React.FC<ContentsProps> = ({ onRootClose }) => {
    const router = useRouter();

    const configure = () => {
        onRootClose();
        router.push(PAGES.TWO_FACTOR_SETUP);
    };

    return (
        <Stack sx={{ px: "16px", py: "20px", alignItems: "center" }}>
            <LockIcon
                sx={{
                    fontSize: "40px",
                    color: (theme) => theme.colors.text.muted,
                }}
            />
            <Typography
                sx={{ textAlign: "center", marginBlock: "32px 36px" }}
                color="text.muted"
            >
                {t("TWO_FACTOR_INFO")}
            </Typography>
            <FocusVisibleButton color="accent" size="large" onClick={configure}>
                {t("ENABLE_TWO_FACTOR")}
            </FocusVisibleButton>
        </Stack>
    );
};

const ManageDrawerContents: React.FC<ContentsProps> = ({ onRootClose }) => {
    const { showMiniDialog } = useAppContext();

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
        onRootClose();
    };

    const confirmReconfigure = () =>
        showMiniDialog({
            title: t("UPDATE_TWO_FACTOR"),
            message: t("UPDATE_TWO_FACTOR_MESSAGE"),
            continue: {
                text: t("UPDATE"),
                color: "primary",
                action: reconfigure,
            },
        });

    const reconfigure = () => {
        onRootClose();
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
                        onClick={confirmReconfigure}
                        variant="primary"
                        checked={true}
                        label={t("reconfigure")}
                    />
                </MenuItemGroup>
                <MenuSectionTitle title={t("UPDATE_TWO_FACTOR_LABEL")} />
            </div>
        </Stack>
    );
};
