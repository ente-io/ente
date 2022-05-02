import { Button, ButtonProps, CircularProgress } from '@mui/material';
import React, { FC } from 'react';

interface Props {
    loading: boolean;
    buttonText: string;
    inline?: any;
    disabled?: boolean;
}
const SubmitButton: FC<ButtonProps<'button', Props>> = ({
    loading,
    buttonText,
    inline,
    disabled,
}: Props) => {
    return (
        <Button
            sx={{ my: 2 }}
            variant="contained"
            color="success"
            type="submit"
            fullWidth={!inline}
            disabled={loading || disabled}>
            {loading ? <CircularProgress size={25} /> : buttonText}
        </Button>
    );
};

export default SubmitButton;
