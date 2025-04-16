import LockIcon from "@mui/icons-material/Lock";
import { Stack, Typography } from "@mui/material";
import {
    RowButton,
    RowButtonGroup,
    RowButtonGroupHint,
    RowSwitch,
} from "ente-base/components/RowButton";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import {
    NestedSidebarDrawer,
    SidebarDrawerTitlebar,
    type NestedSidebarDrawerVisibilityProps,
} from "ente-base/components/mui/SidebarDrawer";
import { useBaseContext } from "ente-base/context";
import { disable2FA, get2FAStatus } from "ente-new/photos/services/user";
import { getData, setLSUser } from "ente-shared/storage/localStorage";
import { t } from "i18next";
import router, { useRouter } from "next/router";
import { useEffect, useState } from "react";

export const TwoFactorSettings: React.FC<
    NestedSidebarDrawerVisibilityProps
> = ({ open, onClose, onRootClose }) => {
    const [isTwoFactorEnabled, setIsTwoFactorEnabled] = useState(false);

    useEffect(() => {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
        const isTwoFactorEnabled =
            // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
            getData("user").isTwoFactorEnabled ?? false;
        // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
        setIsTwoFactorEnabled(isTwoFactorEnabled);
    }, []);

    useEffect(() => {
        if (!open) return;
        void (async () => {
            const isEnabled = await get2FAStatus();
            setIsTwoFactorEnabled(isEnabled);
            // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
            await setLSUser({
                ...getData("user"),
                isTwoFactorEnabled: isEnabled,
            });
        })();
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
                    title={t("two_factor_authentication")}
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
        void router.push("/two-factor/setup");
    };

    return (
        <Stack sx={{ px: "16px", py: "20px", alignItems: "center" }}>
            <LockIcon sx={{ fontSize: "40px", color: "text.muted" }} />
            <Typography
                sx={{
                    color: "text.muted",
                    textAlign: "center",
                    marginBlock: "32px 36px",
                }}
            >
                {t("two_factor_info")}
            </Typography>
            <FocusVisibleButton color="accent" fullWidth onClick={configure}>
                {t("enable_two_factor")}
            </FocusVisibleButton>
        </Stack>
    );
};

const ManageDrawerContents: React.FC<ContentsProps> = ({ onRootClose }) => {
    const { showMiniDialog } = useBaseContext();

    const confirmDisable = () =>
        showMiniDialog({
            title: t("disable_two_factor"),
            message: t("disable_two_factor_message"),
            continue: {
                text: t("disable"),
                color: "critical",
                action: disable,
            },
        });

    const disable = async () => {
        await disable2FA();
        // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
        await setLSUser({ ...getData("user"), isTwoFactorEnabled: false });
        onRootClose();
    };

    const confirmReconfigure = () =>
        showMiniDialog({
            title: t("update_two_factor"),
            message: t("update_two_factor_message"),
            continue: {
                text: t("update"),
                color: "primary",
                action: reconfigure,
            },
        });

    const reconfigure = async () => {
        onRootClose();
        await router.push("/two-factor/setup");
    };

    return (
        <Stack sx={{ px: "16px", py: "20px", gap: "24px" }}>
            <RowButtonGroup>
                <RowSwitch
                    label={t("enabled")}
                    checked={true}
                    onClick={confirmDisable}
                />
            </RowButtonGroup>

            <Stack>
                <RowButtonGroup>
                    <RowButton
                        label={t("reconfigure")}
                        onClick={confirmReconfigure}
                    />
                </RowButtonGroup>
                <RowButtonGroupHint>
                    {t("reconfigure_two_factor_hint")}
                </RowButtonGroupHint>
            </Stack>
        </Stack>
    );
};
