import { Stack, Box, Button, Typography } from '@mui/material';
import Titlebar from 'components/Titlebar';
import { ML_BLOG_LINK } from 'constants/urls';
import { Trans, useTranslation } from 'react-i18next';
import { openLink } from 'utils/common';

export default function EnableMLSearch({
    onClose,
    enableMlSearch,
    onRootClose,
}) {
    const { t } = useTranslation();
    return (
        <Stack spacing={'4px'} py={'12px'}>
            <Titlebar
                onClose={onClose}
                title={t('ML_SEARCH')}
                onRootClose={onRootClose}
            />
            <Stack py={'20px'} px={'8px'} spacing={'32px'}>
                <Box px={'8px'}>
                    {' '}
                    <Typography color="text.secondary">
                        <Trans i18nKey={'ENABLE_ML_SEARCH_DESCRIPTION'}>
                            This will enable on-device machine learning and face
                            search which will start analyzing your uploaded
                            photos locally.
                            <br />
                            <br />
                            For the first run after login or enabling this
                            feature, it will download all images on local device
                            to analyze them. So please only enable this if you
                            are ok with bandwidth and local processing of all
                            images in your photo library.
                            <br />
                            <br />
                            If this is the first time you're enabling this,
                            we'll also ask your permission to process face data.
                        </Trans>
                    </Typography>
                </Box>
                <Stack px={'8px'} spacing={'8px'}>
                    <Button
                        color={'accent'}
                        size="large"
                        onClick={enableMlSearch}>
                        {t('ENABLE')}
                    </Button>
                    <Button
                        color={'secondary'}
                        size="large"
                        onClick={() => openLink(ML_BLOG_LINK, true)}>
                        {t('ML_MORE_DETAILS')}
                    </Button>
                </Stack>
            </Stack>
        </Stack>
    );
}
