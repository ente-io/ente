import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import DoneIcon from "@mui/icons-material/Done";
import { IconButton, Tooltip, type SvgIconProps } from "@mui/material";
import { t } from "i18next";
import { useState } from "react";

interface CopyButtonProps {
    /**
     * The text to copy when the button is clicked.
     */
    text: string;
    /**
     * The size of the icon.
     */
    size?: SvgIconProps["fontSize"];
}

export const CopyButton: React.FC<CopyButtonProps> = ({ text, size }) => {
    const [copied, setCopied] = useState(false);

    const handleClick = () =>
        void navigator.clipboard.writeText(text).then(() => {
            setCopied(true);
            setTimeout(() => setCopied(false), 1000);
        });

    const Icon = copied ? DoneIcon : ContentCopyIcon;

    return (
        <Tooltip arrow open={copied} title={t("copied")}>
            <IconButton onClick={handleClick} color="secondary">
                <Icon fontSize={size} />
            </IconButton>
        </Tooltip>
    );
};
