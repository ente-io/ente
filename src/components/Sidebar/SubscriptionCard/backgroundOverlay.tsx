import { Overlay } from 'components/Container';
import React from 'react';
export function BackgroundOverlay() {
    return (
        <Overlay zIndex={-1}>
            <img
                width="100%"
                height="100%"
                src="/images/subscription-card-background/1x.png"
                srcSet="/images/subscription-card-background/2x.png 2x,
                        /images/subscription-card-background/3x.png 3x"
            />
        </Overlay>
    );
}
