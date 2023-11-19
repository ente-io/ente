import React from 'react';
import { IconButton, InputAdornment } from '@mui/material';
import VisibilityIcon from '@mui/icons-material/Visibility';
import VisibilityOffIcon from '@mui/icons-material/VisibilityOff';

interface Iprops {
    showPassword: boolean;
    handleClickShowPassword: () => void;
    handleMouseDownPassword: (
        event: React.MouseEvent<HTMLButtonElement>
    ) => void;
}
const ShowHidePassword = ({
    showPassword,
    handleClickShowPassword,
    handleMouseDownPassword,
}: Iprops) => (
    <InputAdornment position="end">
        <IconButton
            tabIndex={-1}
            color="secondary"
            aria-label="toggle password visibility"
            onClick={handleClickShowPassword}
            onMouseDown={handleMouseDownPassword}
            edge="end">
            {showPassword ? <VisibilityOffIcon /> : <VisibilityIcon />}
        </IconButton>
    </InputAdornment>
);

export default ShowHidePassword;
