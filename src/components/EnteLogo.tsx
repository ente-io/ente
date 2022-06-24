import React from 'react';
import { styled } from '@mui/material';

export const LogoImage = styled('img')`
    margin: 3px 0;
`;

interface Iprops {
    height?: string;
    width?: string;
}

export function EnteLogo({ height, width }: Iprops) {
    return (
        <LogoImage
            height={'18px'}
            style={{ width, height }}
            alt="logo"
            src="/images/icon.svg"
        />
    );
}
