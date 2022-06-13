import React from 'react';
import { styled } from '@mui/material';
const LogoImage = styled('img')`
    height: 18px;
    padding: 0 3px;
`;

interface Iprops {
    height?: string;
    width?: string;
}

export function EnteLogo({ height, width }: Iprops) {
    return <LogoImage style={{ width, height }} alt="logo" src="/icon.svg" />;
}
