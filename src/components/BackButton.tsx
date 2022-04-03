import React from 'react';
import { IconButton } from './Container';
import LeftArrow from './icons/LeftArrow';

export default function BackButton({ setIsDeduplicating }) {
    return (
        <IconButton
            style={{
                position: 'absolute',
                top: '1em',
                left: '1em',
                zIndex: 10,
            }}
            onClick={() => {
                setIsDeduplicating(false);
            }}>
            <LeftArrow />
        </IconButton>
    );
}
