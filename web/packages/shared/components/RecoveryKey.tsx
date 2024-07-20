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

interface Props {
    isMobile: boolean;
    show: boolean;
    onHide: () => void;
    somethingWentWrong: any;
}

function RecoveryKey({ somethingWentWrong, isMobile, ...props }: Props) {
    const [recoveryKey, setRecoveryKey] = useState<string | null>(null);

    useEffect(() => {
        if (!props.show) {
            return;
        }
        const main = async () => {
            try {
                const recoveryKey = await getRecoveryKey();
                setRecoveryKey(bip39.entropyToMnemonic(recoveryKey));
            } catch (e) {
                somethingWentWrong();
                props.onHide();
            }
        };
        main();
    }, [props.show]);

    function onSaveClick() {
        downloadAsFile(RECOVERY_KEY_FILE_NAME, ensure(recoveryKey));
        props.onHide();
    }

    return (
        <Dialog
            fullScreen={isMobile}
            open={props.show}
            onClose={props.onHide}
            // [Note: maxWidth "xs" on MUI dialogs]
            //
            // While logically the "xs" breakpoint doesn't make sense as a
            // maxWidth value (since as a breakpoint it's value is 0), in
            // practice MUI has hardcoded its value to a reasonable 444px.
            // https://github.com/mui/material-ui/issues/34646.
            maxWidth="xs"
        >
            <DialogTitleWithCloseButton onClose={props.onHide}>
                {t("RECOVERY_KEY")}
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
                <Button color="secondary" size="large" onClick={props.onHide}>
                    {t("SAVE_LATER")}
                </Button>
                <Button color="accent" size="large" onClick={onSaveClick}>
                    {t("SAVE")}
                </Button>
            </DialogActions>
        </Dialog>
    );
}
export default RecoveryKey;

const DashedBorderWrapper = styled(Box)(({ theme }) => ({
    border: `1px dashed ${theme.palette.grey.A400}`,
    borderRadius: theme.spacing(1),
}));
