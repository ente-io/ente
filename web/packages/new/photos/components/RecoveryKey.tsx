/* eslint-disable react/prop-types */
/* eslint-disable @typescript-eslint/no-floating-promises */
/* eslint-disable react-hooks/exhaustive-deps */
/* eslint-disable @typescript-eslint/no-unsafe-return */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unsafe-call */
import { errorDialogAttributes } from "@/base/components/utils/mini-dialog";
import type { ModalVisibilityProps } from "@/base/components/utils/modal";
import { useIsMobileWidth } from "@/base/hooks";
import log from "@/base/log";
import { useAppContext } from "@/new/photos/types/context";
import { ensure } from "@/utils/ensure";
import CodeBlock from "@ente/shared/components/CodeBlock";
import DialogTitleWithCloseButton from "@ente/shared/components/DialogBox/TitleWithCloseButton";
import { getRecoveryKey } from "@ente/shared/crypto/helpers";
import { downloadAsFile } from "@ente/shared/utils";
import {
    Box,
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    Typography,
    styled,
} from "@mui/material";
import * as bip39 from "bip39";
import { t } from "i18next";
import { useEffect, useState } from "react";

// mobile client library only supports english.
bip39.setDefaultWordlist("english");

const RECOVERY_KEY_FILE_NAME = "ente-recovery-key.txt";

export const RecoveryKey: React.FC<ModalVisibilityProps> = ({
    open,
    onClose,
}) => {
    const { showMiniDialog } = useAppContext();

    const [recoveryKey, setRecoveryKey] = useState<string | null>(null);
    const fullScreen = useIsMobileWidth();

    const somethingWentWrong = () =>
        showMiniDialog(
            errorDialogAttributes(t("RECOVER_KEY_GENERATION_FAILED")),
        );

    useEffect(() => {
        if (!open) {
            return;
        }
        const main = async () => {
            try {
                setRecoveryKey(await getRecoveryKeyMnemonic());
            } catch (e) {
                log.error("Failed to generate recovery key", e);
                somethingWentWrong();
                onClose();
            }
        };
        main();
    }, [open]);

    function onSaveClick() {
        downloadAsFile(RECOVERY_KEY_FILE_NAME, ensure(recoveryKey));
        onClose();
    }

    return (
        <Dialog
            fullScreen={fullScreen}
            open={open}
            onClose={onClose}
            // [Note: maxWidth "xs" on MUI dialogs]
            //
            // While logically the "xs" breakpoint doesn't make sense as a
            // maxWidth value (since as a breakpoint it's value is 0), in
            // practice MUI has hardcoded its value to a reasonable 444px.
            // https://github.com/mui/material-ui/issues/34646.
            maxWidth="xs"
            fullWidth
        >
            <DialogTitleWithCloseButton onClose={onClose}>
                {t("recovery_key")}
            </DialogTitleWithCloseButton>
            <DialogContent>
                <Typography mb={3}>{t("RECOVERY_KEY_DESCRIPTION")}</Typography>
                <DashedBorderWrapper>
                    <CodeBlock code={recoveryKey} />
                    <Typography m={2}>
                        {t("KEY_NOT_STORED_DISCLAIMER")}
                    </Typography>
                </DashedBorderWrapper>
            </DialogContent>
            <DialogActions>
                <Button color="secondary" size="large" onClick={onClose}>
                    {t("do_this_later")}
                </Button>
                <Button color="accent" size="large" onClick={onSaveClick}>
                    {t("save_key")}
                </Button>
            </DialogActions>
        </Dialog>
    );
};

const DashedBorderWrapper = styled(Box)(({ theme }) => ({
    border: `1px dashed ${theme.palette.grey.A400}`,
    borderRadius: theme.spacing(1),
}));

const getRecoveryKeyMnemonic = async () =>
    bip39.entropyToMnemonic(await getRecoveryKey());
