import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import DoneIcon from "@mui/icons-material/Done";
import { IconButton, Tooltip, type SvgIconProps } from "@mui/material";
import { t } from "i18next";
import { useCallback, useState } from "react";

interface CopyButtonProps {
    /**
     * The code to copy when the button is clicked.
     */
    code: string;
    /**
     * The button color.
     *
     * - "secondary" maps to the normal "secondary" for icon buttons.
     * - "accentContrastText" is for use over an accented background.
     */
    color: "secondary" | "accentContrastText";
    /**
     * The size of the icon.
     *
     * Default: "small"
     */
    size?: SvgIconProps["fontSize"];
}

export const CopyButton: React.FC<CopyButtonProps> = ({
    code,
    color,
    size = "small",
}) => {
    const [copied, setCopied] = useState(false);

    const handleClick = useCallback(() => {
        void navigator.clipboard.writeText(code).then(() => {
            setCopied(true);
            setTimeout(() => setCopied(false), 1000);
        });
    }, [code]);

    const Icon = copied ? DoneIcon : ContentCopyIcon;

    return (
        <Tooltip
            arrow
            open={copied}
            title={t("copied")}
            slotProps={{ popper: { sx: { zIndex: 2000 } } }}
        >
            <IconButton
                onClick={handleClick}
                {...(color == "secondary" ? { color } : {})}
            >
                <Icon
                    sx={[
                        color == "accentContrastText" && {
                            color: "accent.contrastText",
                        },
                    ]}
                    fontSize={size}
                />
            </IconButton>
        </Tooltip>
    );
};
