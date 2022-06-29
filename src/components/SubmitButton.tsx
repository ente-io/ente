import { Button, ButtonProps, CircularProgress } from '@mui/material';
import React, { FC } from 'react';

export interface SubmitButtonProps {
    loading: boolean;
    buttonText: string;

    disabled?: boolean;
}
const SubmitButton: FC<ButtonProps<'button', SubmitButtonProps>> = ({
    loading,
    buttonText,
    disabled,
    sx,
    ...props
}) => {
    return (
        <Button
            size="large"
            variant="contained"
            color="accent"
            type="submit"
            disabled={loading || disabled}
            sx={{ my: 4, ...sx }}
            {...props}>
            {loading ? <CircularProgress size={20} /> : buttonText}
        </Button>
    );
};

export default SubmitButton;
