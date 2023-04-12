import { Typography } from '@mui/material';
import { FlexWrapper } from 'components/Container';
import React from 'react';
import { LegendIndicator } from '../../../styledComponents';

interface Iprops {
    label: string;
    color: string;
}
export function Legend({ label, color }: Iprops) {
    return (
        <FlexWrapper>
            <LegendIndicator sx={{ color }} />
            <Typography variant="mini" fontWeight={'bold'}>
                {label}
            </Typography>
        </FlexWrapper>
    );
}
