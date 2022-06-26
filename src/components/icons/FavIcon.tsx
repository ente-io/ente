import React from 'react';
import { styled } from '@mui/material';
const HeartUI = styled('div')<{
    isActive: boolean;
    size: number;
}>(
    ({ isActive, size }) => `
    width: ${size}px;
    height: ${size}px;
    float: right;
    background: url('/fav-button.png') no-repeat;
    cursor: pointer;
    background-size: cover;
    border: none;
    ${
        isActive &&
        `background-position: -${
            size * 44
        }px;transition: background 1s steps(28);`
    }
`
);

export default function FavIcon({ isActive, size }) {
    return <HeartUI isActive={isActive} size={size} />;
}

FavIcon.defaultProps = {
    size: 44,
};
