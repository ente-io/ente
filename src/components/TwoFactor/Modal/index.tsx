import React, { useEffect, useState } from 'react';
import { getTwoFactorStatus } from 'services/userService';
import { SetLoading } from 'types/gallery';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import constants from 'utils/strings/constants';
import DialogBox from '../../DialogBox';
import TwoFactorModalSetupSection from './Setup';
import TwoFactorModalManageSection from './Manage';

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
        <DialogBox
            size="xs"
            fullWidth
            open={props.show}
            onClose={props.onHide}
            attributes={{
                title: constants.TWO_FACTOR_AUTHENTICATION,
                staticBackdrop: true,
            }}>
            <>
                {isTwoFactorEnabled ? (
                    <TwoFactorModalManageSection close={close} />
                ) : (
                    <TwoFactorModalSetupSection close={close} />
                )}
            </>
        </DialogBox>
    );
}
export default TwoFactorModal;
