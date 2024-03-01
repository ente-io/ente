import { FACE_SEARCH_PRIVACY_POLICY_LINK } from "@ente/shared/constants/urls";
import {
    Button,
    Checkbox,
    DialogProps,
    FormControlLabel,
    FormGroup,
    Link,
    Stack,
    Typography,
} from "@mui/material";
import { EnteDrawer } from "components/EnteDrawer";
import Titlebar from "components/Titlebar";
import { t } from "i18next";
import { useEffect, useState } from "react";
import { Trans } from "react-i18next";
export default function EnableFaceSearch({
    open,
    onClose,
    enableFaceSearch,
    onRootClose,
}) {
    const [acceptTerms, setAcceptTerms] = useState(false);

    useEffect(() => {
        setAcceptTerms(false);
    }, [open]);

    const handleRootClose = () => {
        onClose();
        onRootClose();
    };

    const handleDrawerClose: DialogProps["onClose"] = (_, reason) => {
        if (reason === "backdropClick") {
            handleRootClose();
        } else {
            onClose();
        }
    };
    return (
        <EnteDrawer
            transitionDuration={0}
            open={open}
            onClose={handleDrawerClose}
            BackdropProps={{
                sx: { "&&&": { backgroundColor: "transparent" } },
            }}
        >
            <Stack spacing={"4px"} py={"12px"}>
                <Titlebar
                    onClose={onClose}
                    title={t("ENABLE_FACE_SEARCH_TITLE")}
                    onRootClose={handleRootClose}
                />
                <Stack py={"20px"} px={"8px"} spacing={"32px"}>
                    <Typography color="text.muted" px={"8px"}>
                        <Trans
                            i18nKey={"ENABLE_FACE_SEARCH_DESCRIPTION"}
                            components={{
                                a: (
                                    <Link
                                        target={"_blank"}
                                        href={FACE_SEARCH_PRIVACY_POLICY_LINK}
                                        underline="always"
                                        sx={{
                                            color: "inherit",
                                            textDecorationColor: "inherit",
                                        }}
                                    />
                                ),
                            }}
                        />
                    </Typography>
                    <FormGroup sx={{ width: "100%" }}>
                        <FormControlLabel
                            sx={{
                                color: "text.muted",
                                ml: 0,
                                mt: 2,
                            }}
                            control={
                                <Checkbox
                                    size="small"
                                    checked={acceptTerms}
                                    onChange={(e) =>
                                        setAcceptTerms(e.target.checked)
                                    }
                                />
                            }
                            label={t("FACE_SEARCH_CONFIRMATION")}
                        />
                    </FormGroup>
                    <Stack px={"8px"} spacing={"8px"}>
                        <Button
                            color={"accent"}
                            size="large"
                            disabled={!acceptTerms}
                            onClick={enableFaceSearch}
                        >
                            {t("ENABLE_FACE_SEARCH")}
                        </Button>
                        <Button
                            color={"secondary"}
                            size="large"
                            onClick={onClose}
                        >
                            {t("CANCEL")}
                        </Button>
                    </Stack>
                </Stack>
            </Stack>
        </EnteDrawer>
    );
}
