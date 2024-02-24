import { Button } from "@mui/material";
import { t } from "i18next";

export const AuthFooter = () => {
    return (
        <div
            style={{
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                justifyContent: "center",
            }}
        >
            <p>{t("AUTH_DOWNLOAD_MOBILE_APP")}</p>
            <a href="https://github.com/ente-io/auth#-download" download>
                <Button color="accent">{t("DOWNLOAD")}</Button>
            </a>
        </div>
    );
};
