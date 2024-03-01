import { ENTE_WEBSITE_LINK } from "@ente/shared/constants/urls";
import { Button, styled } from "@mui/material";
import { t } from "i18next";
import { useEffect, useState } from "react";
import { OS, getDeviceOS } from "utils/common/deviceDetection";

export const NoStyleAnchor = styled("a")`
    color: inherit;
    text-decoration: none !important;
    &:hover {
        color: #fff !important;
    }
`;

function GoToEnte() {
    const [os, setOS] = useState<OS>(OS.UNKNOWN);

    useEffect(() => {
        const os = getDeviceOS();
        setOS(os);
    }, []);

    const getButtonText = (os: OS) => {
        if (os === OS.ANDROID || os === OS.IOS) {
            return t("INSTALL");
        } else {
            return t("SIGN_UP");
        }
    };

    return (
        <Button
            color="accent"
            LinkComponent={NoStyleAnchor}
            href={ENTE_WEBSITE_LINK}
        >
            {getButtonText(os)}
        </Button>
    );
}

export default GoToEnte;
