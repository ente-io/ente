import { Stack, Box, Button, Typography } from '@mui/material';
import Titlebar from 'components/Titlebar';
import { ML_BLOG_LINK } from 'constants/urls';
import { Trans } from 'react-i18next';
import { t } from 'i18next';
import { openLink } from 'utils/common';

export default function EnableMap({ onClose, enableMap, onRootClose }) {
    return (
        <Stack spacing={'4px'} py={'12px'}>
            <Titlebar
                onClose={onClose}
                title={t('MAP')}
                onRootClose={onRootClose}
            />
            <Stack py={'20px'} px={'8px'} spacing={'32px'}>
                <Box px={'8px'}>
                    {' '}
                    <Typography color="text.muted">
                        <Trans
                            i18nKey={
                                'This will show your photos on a worldmap.The map is hosted by OpenStreetMap, and the exact locations of your photos are never shared.You can disable this feature anytime from Settings.'
                            }
                        />
                    </Typography>
                </Box>
                <Stack px={'8px'} spacing={'8px'}>
                    <Button color={'accent'} size="large" onClick={enableMap}>
                        {t('ENABLE')}
                    </Button>
                    <Button
                        color={'secondary'}
                        size="large"
                        onClick={() => openLink(ML_BLOG_LINK, true)}>
                        {t('Learn More')}
                    </Button>
                </Stack>
            </Stack>
        </Stack>
    );
}
