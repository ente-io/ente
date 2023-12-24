import DialogBoxV2 from '@ente/shared/components/DialogBoxV2';
import EnteButton from '@ente/shared/components/EnteButton';
import { Button, Stack, Typography } from '@mui/material';
import { AppContext } from 'pages/_app';
import { useContext, useState } from 'react';
import { deletePasskey } from 'services/passkeysService';
import { PasskeysContext } from '.';

interface IProps {
    open: boolean;
    onClose: () => void;
}

const DeletePasskeyModal = (props: IProps) => {
    const { isMobile } = useContext(AppContext);
    const { selectedPasskey } = useContext(PasskeysContext);

    const [loading, setLoading] = useState(false);

    const doDelete = async () => {
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
    };

    return (
        <DialogBoxV2
            fullWidth
            open={props.open}
            onClose={props.onClose}
            fullScreen={isMobile}
            attributes={{
                title: 'Delete Passkey',
                secondary: {
                    action: props.onClose,
                    text: 'Cancel',
                },
            }}>
            <Stack spacing={'8px'}>
                <Typography>
                    Are you sure you want to delete this passkey? This action is
                    irreversible.
                </Typography>
                <EnteButton
                    type="submit"
                    size="large"
                    color="critical"
                    loading={loading}
                    onClick={doDelete}>
                    Delete Passkey
                </EnteButton>
                <Button
                    size="large"
                    color={'secondary'}
                    onClick={props.onClose}>
                    Cancel
                </Button>
            </Stack>
        </DialogBoxV2>
    );
};

export default DeletePasskeyModal;
