import { Box, styled, Typography } from '@mui/material';
import React from 'react';
import { convertBytesToGBs, makeHumanReadableStorage } from 'utils/billing';
import { useTranslation } from 'react-i18next';

const MobileSmallBox = styled(Box)`
    display: none;
    @media (max-width: 359px) {
        display: block;
    }
`;

const DefaultBox = styled(Box)`
    display: none;
    @media (min-width: 360px) {
        display: block;
    }
`;
interface Iprops {
    usage: number;
    storage: number;
}
export default function StorageSection({ usage, storage }: Iprops) {
    const { t } = useTranslation();

    return (
        <Box width="100%">
            <Typography variant="body2" color={'text.secondary'}>
                {t('STORAGE')}
            </Typography>
            <DefaultBox>
                <Typography
                    fontWeight={'bold'}
                    sx={{ fontSize: '24px', lineHeight: '30px' }}>
                    {`${makeHumanReadableStorage(usage, { roundUp: true })} ${t(
                        'OF'
                    )} ${makeHumanReadableStorage(storage)} ${t('USED')}`}
                </Typography>
            </DefaultBox>
            <MobileSmallBox>
                <Typography
                    fontWeight={'bold'}
                    sx={{ fontSize: '24px', lineHeight: '30px' }}>
                    {`${convertBytesToGBs(usage)} /  ${convertBytesToGBs(
                        storage
                    )} ${t('GB')} ${t('USED')}`}
                </Typography>
            </MobileSmallBox>
        </Box>
    );
}
