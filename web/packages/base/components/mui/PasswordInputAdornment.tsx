import VisibilityIcon from "@mui/icons-material/Visibility";
import VisibilityOffIcon from "@mui/icons-material/VisibilityOff";
import { IconButton, InputAdornment } from "@mui/material";
import { t } from "i18next";
import React from "react";

interface ShowHidePasswordInputAdornmentProps {
    /**
     * When `true`, the password is being shown.
     */
    showPassword: boolean;
    /**
     * Called when the user wants to toggle the state of {@link showPassword}.
     */
    onToggle: () => void;
}

/**
 * A MUI {@link InputAdornment} that can be used at the trailing edge of a
 * password input field to allow the user to toggle the visibility of the
 * password.
 */
export const ShowHidePasswordInputAdornment: React.FC<
    ShowHidePasswordInputAdornmentProps
> = ({ showPassword, onToggle: onToggle }) => {
    // Prevent password field from losing focus when the input adornment is
    // clicked by ignoring both the mouse up and down events. This is the
    // approach mentioned in the MUI docs.
    // https://mui.com/material-ui/react-text-field/#input-adornments
    const preventDefault = (event: React.MouseEvent<HTMLButtonElement>) => {
        event.preventDefault();
    };

    return (
        <InputAdornment position="end">
            <IconButton
                tabIndex={-1}
                color="secondary"
                aria-label={t("show_or_hide_password")}
                onClick={onToggle}
                onMouseUp={preventDefault}
                onMouseDown={preventDefault}
                edge="end"
            >
                {showPassword ? <VisibilityOffIcon /> : <VisibilityIcon />}
            </IconButton>
        </InputAdornment>
    );
};
