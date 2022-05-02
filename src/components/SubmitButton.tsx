import { Button, ButtonProps, CircularProgress } from '@mui/material';
import React, { FC } from 'react';

interface Props {
    loading: boolean;
    children: any;
    inline?: any;
    disabled?: boolean;
}
const SubmitButton: FC<ButtonProps<'button', Props>> = ({
    loading,
    children,
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
            {loading ? <CircularProgress size={25} /> : children}
        </Button>
    );
};

export default SubmitButton;
