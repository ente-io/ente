import { Stack, Box, Button, Typography } from '@mui/material';
import Titlebar from 'components/Titlebar';
import { Trans } from 'react-i18next';
import { t } from 'i18next';

export default function EnableMap({ onClose, enableMap, onRootClose }) {
    return (
        <Stack spacing={'4px'} py={'12px'}>
            <Titlebar
                onClose={onClose}
                title={t('Map Settings')}
                onRootClose={onRootClose}
            />
            <Stack py={'20px'} px={'8px'} spacing={'32px'}>
                <Box px={'8px'}>
                    {' '}
                    <Typography color="text.muted">
                        <Trans
                            i18nKey={
                                'This will show your photos on a worldmap.'
                            }
                        />
                        <br />
                        <br />

                        <Trans
                            i18nKey={
                                'The map is hosted by OpenStreetMap, and the exact locations of your photos are never shared.'
                            }
                        />
                        <br />
                        <br />

                        <Trans
                            i18nKey={
                                'You can disable this feature anytime from Settings.'
                            }
                        />
                    </Typography>
                </Box>
                <Stack px={'8px'} spacing={'8px'}>
                    <Button color={'accent'} size="large" onClick={enableMap}>
                        {t('ENABLE')}
                    </Button>
                    <Button color={'secondary'} size="large" onClick={onClose}>
                        {t('Cancel')}
                    </Button>
                </Stack>
            </Stack>
        </Stack>
    );
}
