import { Stack, Box, Button, Typography } from '@mui/material';
import Titlebar from 'components/Titlebar';
import { Trans } from 'react-i18next';
import { t } from 'i18next';

export default function EnableMap({ onClose, enableMap, onRootClose }) {
    return (
        <Stack spacing={'4px'} py={'12px'}>
            <Titlebar
                onClose={onClose}
                title={t('ENABLE_MAPS')}
                onRootClose={onRootClose}
            />
            <Stack py={'20px'} px={'8px'} spacing={'32px'}>
                <Box px={'8px'}>
                    {' '}
                    <Typography color="text.muted">
                        <Trans i18nKey={'ENABLE_MAP_DESCRIPTION_1'} />
                        <br />
                        <br />

                        <Trans i18nKey={'ENABLE_MAP_DESCRIPTION_2'} />
                        <br />
                        <br />

                        <Trans i18nKey={'ENABLE_MAP_DESCRIPTION_3'} />
                    </Typography>
                </Box>
                <Stack px={'8px'} spacing={'8px'}>
                    <Button color={'accent'} size="large" onClick={enableMap}>
                        {t('ENABLE')}
                    </Button>
                    <Button color={'secondary'} size="large" onClick={onClose}>
                        {t('CANCEL')}
                    </Button>
                </Stack>
            </Stack>
        </Stack>
    );
}
