import ChevronRightIcon from '@mui/icons-material/ChevronRight';
import { FlexWrapper, Overlay } from 'components/Container';
import React from 'react';
export function ClickOverlay({ onClick }) {
    return (
        <Overlay zIndex={2} display="flex">
            <FlexWrapper
                onClick={onClick}
                justifyContent={'flex-end'}
                sx={{ cursor: 'pointer' }}>
                <ChevronRightIcon />
            </FlexWrapper>
        </Overlay>
    );
}
