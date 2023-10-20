import { Button, Stack, Typography } from '@mui/material';
import DialogBoxV2 from 'components/DialogBoxV2';
import EnteButton from 'components/EnteButton';
import { t } from 'i18next';

interface IProps {
    open: boolean;
    onClose: () => void;
    doClose: () => void;
}

const AreYouSureCloseDialog = (props: IProps) => {
    return (
        <>
            <DialogBoxV2
                open={props.open}
                onClose={props.onClose}
                attributes={{
                    title: t('CONFIRM_EDITOR_CLOSE_MESSAGE'),
                }}>
                <Typography>{t('CONFIRM_EDITOR_CLOSE_DESCRIPTION')}</Typography>
                <Stack spacing={'8px'}>
                    <EnteButton
                        type="submit"
                        size="large"
                        color="critical"
                        onClick={props.doClose}>
                        {t('CLOSE')}
                    </EnteButton>
                    <Button
                        size="large"
                        color={'secondary'}
                        onClick={props.onClose}>
                        {t('CANCEL')}
                    </Button>
                </Stack>
            </DialogBoxV2>
        </>
    );
};

export default AreYouSureCloseDialog;
