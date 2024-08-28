import { t } from "i18next";
import { useContext } from "react";

import { disableTwoFactor } from "@/accounts/api/user";
import { PHOTOS_PAGES as PAGES } from "@ente/shared/constants/pages";
import { LS_KEYS, getData, setLSUser } from "@ente/shared/storage/localStorage";
import { Button, Grid } from "@mui/material";
import router from "next/router";
import { AppContext } from "pages/_app";

interface Iprops {
    closeDialog: () => void;
}

export default function TwoFactorModalManageSection(props: Iprops) {
    const { closeDialog } = props;
    const { setDialogMessage } = useContext(AppContext);

    const warnTwoFactorDisable = async () => {
        setDialogMessage({
            title: t("DISABLE_TWO_FACTOR"),

            content: t("DISABLE_TWO_FACTOR_MESSAGE"),
            close: { text: t("cancel") },
            proceed: {
                variant: "critical",
                text: t("disable"),
                action: twoFactorDisable,
            },
        });
    };

    const twoFactorDisable = async () => {
        try {
            await disableTwoFactor();
            await setLSUser({
                ...getData(LS_KEYS.USER),
                isTwoFactorEnabled: false,
            });
            closeDialog();
        } catch (e) {
            setDialogMessage({
                title: t("TWO_FACTOR_DISABLE_FAILED"),
                close: {},
            });
        }
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
        <>
            <Grid
                mb={1.5}
                rowSpacing={1}
                container
                alignItems="center"
                justifyContent="center"
            >
                <Grid item sm={9} xs={12}>
                    {t("UPDATE_TWO_FACTOR_LABEL")}
                </Grid>
                <Grid item sm={3} xs={12}>
                    <Button
                        color={"accent"}
                        onClick={warnTwoFactorReconfigure}
                        size="large"
                    >
                        {t("reconfigure")}
                    </Button>
                </Grid>
            </Grid>
            <Grid
                rowSpacing={1}
                container
                alignItems="center"
                justifyContent="center"
            >
                <Grid item sm={9} xs={12}>
                    {t("DISABLE_TWO_FACTOR_LABEL")}{" "}
                </Grid>

                <Grid item sm={3} xs={12}>
                    <Button
                        color="critical"
                        onClick={warnTwoFactorDisable}
                        size="large"
                    >
                        {t("disable")}
                    </Button>
                </Grid>
            </Grid>
        </>
    );
}
