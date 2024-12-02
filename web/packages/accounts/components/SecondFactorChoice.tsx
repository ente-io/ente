import { FocusVisibleButton } from "@/base/components/mui/FocusVisibleButton";
import type { ModalVisibilityProps } from "@/base/components/utils/modal";
import { Dialog, DialogContent, DialogTitle, Stack } from "@mui/material";
import { t } from "i18next";
import React from "react";

export type SecondFactorType = "totp" | "passkey";

type SecondFactorChoiceProps = ModalVisibilityProps & {
    /**
     * Callback invoked with the selected choice.
     *
     * The dialog will automatically be closed before this callback is invoked.
     */
    onSelect: (factor: SecondFactorType) => void;
};

/**
 * A {@link Dialog} that allow the user to choose which second factor they'd
 * like to verify during login.
 */
export const SecondFactorChoice: React.FC<SecondFactorChoiceProps> = ({
    open,
    onClose,
    onSelect,
}) => (
    <Dialog
        open={open}
        onClose={(_, reason) => {
            if (reason != "backdropClick") onClose();
        }}
        fullWidth
        PaperProps={{ sx: { maxWidth: "360px", padding: "12px" } }}
    >
        <DialogTitle>{t("two_factor")}</DialogTitle>
        <DialogContent>
            <Stack sx={{ gap: "12px" }}>
                <FocusVisibleButton
                    color="accent"
                    onClick={() => {
                        onClose();
                        onSelect("totp");
                    }}
                >
                    {t("totp_login")}
                </FocusVisibleButton>

                <FocusVisibleButton
                    color="accent"
                    onClick={() => {
                        onClose();
                        onSelect("passkey");
                    }}
                >
                    {t("passkey_login")}
                </FocusVisibleButton>
            </Stack>
        </DialogContent>
    </Dialog>
);
