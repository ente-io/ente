import SingleInputForm, {
    SingleInputFormProps,
} from "@ente/shared/components/SingleInputForm";
import ComlinkCryptoWorker from "@ente/shared/crypto";
import { Dialog, Stack, Typography } from "@mui/material";
import { t } from "i18next";

export function PublicLinkSetPassword({
    open,
    onClose,
    collection,
    publicShareProp,
    updatePublicShareURLHelper,
    setChangePasswordView,
}) {
    const savePassword: SingleInputFormProps["callback"] = async (
        passphrase,
        setFieldError,
    ) => {
        if (passphrase && passphrase.trim().length >= 1) {
            await enablePublicUrlPassword(passphrase);
            setChangePasswordView(false);
            publicShareProp.passwordEnabled = true;
        } else {
            setFieldError("can not be empty");
        }
    };

    const enablePublicUrlPassword = async (password: string) => {
        const cryptoWorker = await ComlinkCryptoWorker.getInstance();
        const kekSalt = await cryptoWorker.generateSaltToDeriveKey();
        const kek = await cryptoWorker.deriveInteractiveKey(password, kekSalt);

        return updatePublicShareURLHelper({
            collectionID: collection.id,
            passHash: kek.key,
            nonce: kekSalt,
            opsLimit: kek.opsLimit,
            memLimit: kek.memLimit,
        });
    };
    return (
        <Dialog
            open={open}
            onClose={onClose}
            disablePortal
            BackdropProps={{ sx: { position: "absolute" } }}
            sx={{ position: "absolute" }}
            PaperProps={{ sx: { p: 1 } }}
        >
            <Stack spacing={3} p={1.5}>
                <Typography variant="h3" px={1} py={0.5} fontWeight={"bold"}>
                    {t("PASSWORD_LOCK")}
                </Typography>
                <SingleInputForm
                    callback={savePassword}
                    placeholder={t("RETURN_PASSPHRASE_HINT")}
                    buttonText={t("LOCK")}
                    fieldType="password"
                    secondaryButtonAction={onClose}
                    submitButtonProps={{ sx: { mt: 1, mb: 2 } }}
                />
            </Stack>
        </Dialog>
    );
}
