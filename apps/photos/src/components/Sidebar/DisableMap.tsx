import { Stack, Box, Button, Typography } from '@mui/material';
import Titlebar from 'components/Titlebar';
import { Trans } from 'react-i18next';
import { t } from 'i18next';

export default function EnableMap({ onClose, disableMap, onRootClose }) {
    return (
        <Stack spacing={'4px'} py={'12px'}>
            <Titlebar
                onClose={onClose}
                title={t('Disable Maps?')}
                onRootClose={onRootClose}
            />
            <Stack py={'20px'} px={'8px'} spacing={'32px'}>
                <Box px={'8px'}>
                    {' '}
                    <Typography color="text.muted">
                        <Trans
                            i18nKey={
                                'This will disable the display of your photos on a world map.'
                            }
                        />
                        <br />
                        <br />
                        <Trans
                            i18nKey={
                                'You can enable this feature anytime from Settings.'
                            }
                        />
                    </Typography>
                </Box>
                <Stack px={'8px'} spacing={'8px'}>
                    <Button
                        color={'critical'}
                        size="large"
                        onClick={disableMap}>
                        {t('DISABLE')}
                    </Button>
                    <Button color={'secondary'} size="large" onClick={onClose}>
                        {t('Cancel')}
                    </Button>
                </Stack>
            </Stack>
        </Stack>
    );
}
