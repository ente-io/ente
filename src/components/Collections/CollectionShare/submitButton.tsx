import { FlexWrapper } from 'components/Container';
import SubmitButton, { SubmitButtonProps } from 'components/SubmitButton';
import React from 'react';
export default function CollectionShareSubmitButton(props: SubmitButtonProps) {
    return (
        <FlexWrapper style={{ justifyContent: 'flex-end' }}>
            <SubmitButton {...props} size="medium" inline sx={{ my: 2 }} />
        </FlexWrapper>
    );
}
