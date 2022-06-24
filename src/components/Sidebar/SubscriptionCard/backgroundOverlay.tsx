import { Overlay } from 'components/Container';
import React from 'react';
export function BackgroundOverlay() {
    return (
        <Overlay zIndex={-1}>
            <img src="/images/subscription-card-background.png" />
        </Overlay>
    );
}
