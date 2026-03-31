import {
    PublicAccessPageContents,
    PublicAccessPageTitle,
} from "@/public-album/components/PublicAccessPage";
import { Stack, Typography } from "@mui/material";
import {
    SingleInputForm,
    type SingleInputFormProps,
} from "ente-base/components/SingleInputForm";
import { t } from "i18next";

export interface PasswordUnlockScreenProps {
    onSubmit: SingleInputFormProps["onSubmit"];
}

export const PasswordUnlockScreen: React.FC<PasswordUnlockScreenProps> = ({
    onSubmit,
}) => (
    <PublicAccessPageContents>
        <PublicAccessPageTitle>{t("password")}</PublicAccessPageTitle>
        <Stack>
            <Typography variant="small" sx={{ color: "text.muted", mb: 2 }}>
                {t("link_password_description")}
            </Typography>
            <SingleInputForm
                inputType="password"
                label={t("password")}
                submitButtonColor="primary"
                submitButtonTitle={t("unlock")}
                onSubmit={onSubmit}
            />
        </Stack>
    </PublicAccessPageContents>
);
