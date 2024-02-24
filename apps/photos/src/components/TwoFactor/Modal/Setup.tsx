import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import LockIcon from "@mui/icons-material/Lock";
import { t } from "i18next";
import { useRouter } from "next/router";

import { VerticallyCentered } from "@ente/shared/components/Container";
import { Button, Typography } from "@mui/material";

interface Iprops {
    closeDialog: () => void;
}

export default function TwoFactorModalSetupSection({ closeDialog }: Iprops) {
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
