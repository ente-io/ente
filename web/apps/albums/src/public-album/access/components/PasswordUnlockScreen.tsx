import {
    PublicAccessLayout,
    PublicAccessLayoutTitle,
} from "@/public-album/access/components/PublicAccessLayout";
import { Typography } from "@mui/material";
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
    <PublicAccessLayout>
        <PublicAccessLayoutTitle>{t("password")}</PublicAccessLayoutTitle>
        <Typography sx={{ color: "text.muted" }}>
            {t("link_password_description")}
        </Typography>
        <SingleInputForm
            inputType="password"
            label={t("password")}
            submitButtonTitle={t("unlock")}
            onSubmit={onSubmit}
        />
    </PublicAccessLayout>
);
