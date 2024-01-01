import DialogBoxV2 from '@ente/shared/components/DialogBoxV2';
import EnteButton from '@ente/shared/components/EnteButton';
import { Button, Stack, Typography } from '@mui/material';
import { AppContext } from 'pages/_app';
import { useContext, useState } from 'react';
import { deletePasskey } from 'services/passkeysService';
import { PasskeysContext } from '.';
import { t } from 'i18next';

interface IProps {
    open: boolean;
    onClose: () => void;
}

const DeletePasskeyModal = (props: IProps) => {
    const { isMobile } = useContext(AppContext);
    const { selectedPasskey, setShowPasskeyDrawer } =
        useContext(PasskeysContext);

    const [loading, setLoading] = useState(false);

    const doDelete = async () => {
        if (!selectedPasskey) return;
        setLoading(true);
        try {
            await deletePasskey(selectedPasskey.id);
        } catch (error) {
            console.error(error);
            return;
        } finally {
            setLoading(false);
        }
        props.onClose();
        setShowPasskeyDrawer(false);
    };

    return (
        <DialogBoxV2
            fullWidth
            open={props.open}
            onClose={props.onClose}
            fullScreen={isMobile}
            attributes={{
                title: t('DELETE_PASSKEY'),
                secondary: {
                    action: props.onClose,
                    text: t('CANCEL'),
                },
            }}>
            <Stack spacing={'8px'}>
                <Typography>{t('DELETE_PASSKEY_CONFIRMATION')}</Typography>
                <EnteButton
                    type="submit"
                    size="large"
                    color="critical"
                    loading={loading}
                    onClick={doDelete}>
                    {t('DELETE')}
                </EnteButton>
                <Button
                    size="large"
                    color={'secondary'}
                    onClick={props.onClose}>
                    {t('CANCEL')}
                </Button>
            </Stack>
        </DialogBoxV2>
    );
};

export default DeletePasskeyModal;
