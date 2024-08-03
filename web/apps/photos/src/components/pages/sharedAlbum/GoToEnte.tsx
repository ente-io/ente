import { useIsTouchscreen } from "@/base/hooks";
import { Button, styled } from "@mui/material";
import { t } from "i18next";

export const NoStyleAnchor = styled("a")`
    color: inherit;
    text-decoration: none !important;
    &:hover {
        color: #fff !important;
    }
`;

function GoToEnte() {
    // Touchscreen devices are overwhemingly likely to be Android or iOS.
    const isTouchscreen = useIsTouchscreen();

    return (
        <Button
            color="accent"
            LinkComponent={NoStyleAnchor}
            href="https://ente.io"
        >
            {isTouchscreen ? t("INSTALL") : t("SIGN_UP")}
        </Button>
    );
}

export default GoToEnte;
