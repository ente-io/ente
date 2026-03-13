import { Modal } from "@mui/material";
import { LockScreenContents } from "components/app-lock/LockScreenContents";
import { t } from "i18next";

export const LockPage = () => (
    <Modal
        open
        disableEscapeKeyDown
        aria-label={t("app_lock")}
        slotProps={{
            backdrop: {
                sx: (theme) => ({
                    backgroundColor: "secondary.main",
                    ...theme.applyStyles("dark", { backgroundColor: "#000" }),
                }),
            },
        }}
        sx={{ zIndex: "calc(var(--mui-zIndex-tooltip) + 1)" }}
    >
        <LockScreenContents />
    </Modal>
);

export default LockPage;
