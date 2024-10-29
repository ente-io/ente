import type { ModalVisibilityProps } from "@/base/components/utils/modal";
import DialogTitleWithCloseButton from "@ente/shared/components/DialogBox/TitleWithCloseButton";
import { LS_KEYS, getData, setLSUser } from "@ente/shared/storage/localStorage";
import { Dialog, DialogContent, styled } from "@mui/material";
import { t } from "i18next";
import { useEffect, useState } from "react";
import { getTwoFactorStatus } from "services/userService";
import TwoFactorModalManageSection from "./Manage";
import TwoFactorModalSetupSection from "./Setup";

const TwoFactorDialog = styled(Dialog)(({ theme }) => ({
    "& .MuiDialogContent-root": {
        padding: theme.spacing(2, 4),
    },
}));

type Props = ModalVisibilityProps & {
    closeSidebar: () => void;
};

function TwoFactorModal(props: Props) {
    const [isTwoFactorEnabled, setTwoFactorStatus] = useState(false);

    useEffect(() => {
        const isTwoFactorEnabled =
            getData(LS_KEYS.USER).isTwoFactorEnabled ?? false;
        setTwoFactorStatus(isTwoFactorEnabled);
    }, []);

    useEffect(() => {
        if (!props.open) {
            return;
        }
        const main = async () => {
            const isTwoFactorEnabled = await getTwoFactorStatus();
            setTwoFactorStatus(isTwoFactorEnabled);
            await setLSUser({
                ...getData(LS_KEYS.USER),
                isTwoFactorEnabled,
            });
        };
        main();
    }, [props.open]);

    const closeDialog = () => {
        props.onClose();
        props.closeSidebar();
    };

    return (
        <TwoFactorDialog
            maxWidth="xs"
            open={props.open}
            onClose={props.onClose}
        >
            <DialogTitleWithCloseButton onClose={props.onClose}>
                {t("TWO_FACTOR_AUTHENTICATION")}
            </DialogTitleWithCloseButton>
            <DialogContent sx={{ px: 4 }}>
                {isTwoFactorEnabled ? (
                    <TwoFactorModalManageSection closeDialog={closeDialog} />
                ) : (
                    <TwoFactorModalSetupSection closeDialog={closeDialog} />
                )}
            </DialogContent>
        </TwoFactorDialog>
    );
}
export default TwoFactorModal;
