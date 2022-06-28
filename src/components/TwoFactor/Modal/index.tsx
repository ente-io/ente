import React, { useEffect, useState } from 'react';
import { getTwoFactorStatus } from 'services/userService';
import { SetLoading } from 'types/gallery';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import constants from 'utils/strings/constants';
import TwoFactorModalSetupSection from './Setup';
import TwoFactorModalManageSection from './Manage';
import { Dialog, DialogContent, styled } from '@mui/material';
import DialogTitleWithCloseButton from 'components/DialogBox/TitleWithCloseButton';

const TwoFactorDialog = styled(Dialog)(({ theme }) => ({
    '& .MuiDialogContent-root': {
        padding: theme.spacing(2, 4),
    },
}));
interface Props {
    show: boolean;
    onHide: () => void;
    setLoading: SetLoading;
    closeSidebar: () => void;
}

function TwoFactorModal(props: Props) {
    const [isTwoFactorEnabled, setTwoFactorStatus] = useState(false);

    useEffect(() => {
        if (!props.show) {
            return;
        }
        const isTwoFactorEnabled =
            getData(LS_KEYS.USER).isTwoFactorEnabled ?? false;
        setTwoFactorStatus(isTwoFactorEnabled);
        const main = async () => {
            const isTwoFactorEnabled = await getTwoFactorStatus();
            setTwoFactorStatus(isTwoFactorEnabled);
            setData(LS_KEYS.USER, {
                ...getData(LS_KEYS.USER),
                isTwoFactorEnabled: false,
            });
        };
        main();
    }, [props.show]);

    const close = () => {
        props.onHide();
        props.closeSidebar();
    };

    return (
        <TwoFactorDialog maxWidth="xs" open={props.show} onClose={props.onHide}>
            <DialogTitleWithCloseButton onClose={props.onHide}>
                {constants.TWO_FACTOR_AUTHENTICATION}
            </DialogTitleWithCloseButton>
            <DialogContent sx={{ px: 4 }}>
                {isTwoFactorEnabled ? (
                    <TwoFactorModalManageSection close={close} />
                ) : (
                    <TwoFactorModalSetupSection close={close} />
                )}
            </DialogContent>
        </TwoFactorDialog>
    );
}
export default TwoFactorModal;
