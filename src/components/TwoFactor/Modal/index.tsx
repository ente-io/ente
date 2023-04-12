import { useEffect, useState } from 'react';
import { getTwoFactorStatus } from 'services/userService';
import { SetLoading } from 'types/gallery';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { t } from 'i18next';

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
        const isTwoFactorEnabled =
            getData(LS_KEYS.USER).isTwoFactorEnabled ?? false;
        setTwoFactorStatus(isTwoFactorEnabled);
    }, []);

    useEffect(() => {
        if (!props.show) {
            return;
        }
        const main = async () => {
            const isTwoFactorEnabled = await getTwoFactorStatus();
            setTwoFactorStatus(isTwoFactorEnabled);
            setData(LS_KEYS.USER, {
                ...getData(LS_KEYS.USER),
                isTwoFactorEnabled,
            });
        };
        main();
    }, [props.show]);

    const closeDialog = () => {
        props.onHide();
        props.closeSidebar();
    };

    return (
        <TwoFactorDialog maxWidth="xs" open={props.show} onClose={props.onHide}>
            <DialogTitleWithCloseButton onClose={props.onHide}>
                {t('TWO_FACTOR_AUTHENTICATION')}
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
