import { Paper, Stack, styled, Typography } from "@mui/material";
import { type MiniDialogAttributes } from "ente-base/components/MiniDialog";
import { CenteredFill } from "ente-base/components/containers";
import { EnteLogo } from "ente-base/components/EnteLogo";
import { FocusVisibleButton } from "ente-base/components/mui/FocusVisibleButton";
import { NavbarBase } from "ente-base/components/Navbar";
import { errorDialogAttributes } from "ente-base/components/utils/dialog";
import type { ModalVisibilityProps } from "ente-base/components/utils/modal";
import log from "ente-base/log";
import { saveStringAsFile } from "ente-base/utils/web";
import { t } from "i18next";
import { useCallback, useEffect, useState } from "react";
import {
    getUserRecoveryKey,
    recoveryKeyToMnemonic,
} from "../services/recovery-key";
import { CodeBlock } from "./CodeBlock";

type RecoveryKeyProps = ModalVisibilityProps & {
    showMiniDialog: (attributes: MiniDialogAttributes) => void;
};

export const RecoveryKey: React.FC<RecoveryKeyProps> = ({
    open,
    onClose,
    showMiniDialog,
}) => {
    const [recoveryKey, setRecoveryKey] = useState<string | undefined>();

    const handleLoadError = useCallback(
        (e: unknown) => {
            log.error("Failed to generate recovery key", e);
            showMiniDialog(
                errorDialogAttributes(t("recovery_key_generation_failed")),
            );
            onClose();
        },
        [onClose, showMiniDialog],
    );

    useEffect(() => {
        if (!open) return;

        void getUserRecoveryKeyMnemonic()
            .then((key) => setRecoveryKey(key))
            .catch(handleLoadError);
    }, [open, handleLoadError]);

    const handleSaveClick = () => {
        saveRecoveryKeyMnemonicAsFile(recoveryKey!);
        onClose();
    };

    if (!open) return null;

    return (
        <Stack
            sx={[
                { minHeight: "100svh", bgcolor: "secondary.main" },
                (theme) =>
                    theme.applyStyles("dark", {
                        bgcolor: "background.default",
                    }),
            ]}
        >
            <NavbarBase
                sx={{ boxShadow: "none", borderBottom: "none", bgcolor: "transparent" }}
            >
                <EnteLogo />
            </NavbarBase>
            <CenteredFill
                sx={[
                    { bgcolor: "secondary.main" },
                    (theme) =>
                        theme.applyStyles("dark", {
                            bgcolor: "background.default",
                        }),
                ]}
            >
                <RecoveryKeyPaper>
                    <Typography variant="h3">{t("recovery_key")}</Typography>
                    <Typography sx={{ color: "text.muted" }}>
                        {t("recovery_key_description")}
                    </Typography>
                    <Stack
                        sx={{
                            border: "1px dashed",
                            borderColor: "stroke.muted",
                            borderRadius: 1,
                        }}
                    >
                        <CodeBlock code={recoveryKey} />
                        <Typography sx={{ m: 2 }}>
                            {t("key_not_stored_note")}
                        </Typography>
                    </Stack>
                    <Stack direction="row" sx={{ gap: 1, mt: 2 }}>
                        <FocusVisibleButton
                            color="secondary"
                            fullWidth
                            onClick={onClose}
                        >
                            {t("do_this_later")}
                        </FocusVisibleButton>
                        <FocusVisibleButton
                            color="accent"
                            fullWidth
                            onClick={handleSaveClick}
                        >
                            {t("save_key")}
                        </FocusVisibleButton>
                    </Stack>
                </RecoveryKeyPaper>
            </CenteredFill>
        </Stack>
    );
};

const RecoveryKeyPaper = styled(Paper)(({ theme }) => ({
    marginBlock: theme.spacing(2),
    padding: theme.spacing(5, 3),
    [theme.breakpoints.up("sm")]: {
        padding: theme.spacing(5),
    },
    width: "min(420px, 85vw)",
    display: "flex",
    flexDirection: "column",
    gap: theme.spacing(3),
    boxShadow: "none",
    borderRadius: "20px",
}));

const getUserRecoveryKeyMnemonic = async () =>
    recoveryKeyToMnemonic(await getUserRecoveryKey());

const saveRecoveryKeyMnemonicAsFile = (key: string) =>
    saveStringAsFile(key, "ente-recovery-key.txt");
