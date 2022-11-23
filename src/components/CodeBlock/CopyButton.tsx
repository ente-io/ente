import React, { useState } from 'react';
import constants from 'utils/strings/constants';
import DoneIcon from '@mui/icons-material/Done';
import ContentCopyIcon from '@mui/icons-material/ContentCopy';
import {
    IconButton,
    IconButtonProps,
    SvgIconProps,
    Tooltip,
} from '@mui/material';

export default function CopyButton({
    code,
    color,
    size,
}: {
    code: string;
    color?: IconButtonProps['color'];
    size?: SvgIconProps['fontSize'];
}) {
    const [copied, setCopied] = useState<boolean>(false);

    const copyToClipboardHelper = (text: string) => () => {
        navigator.clipboard.writeText(text);
        setCopied(true);
        setTimeout(() => setCopied(false), 1000);
    };
    return (
        <Tooltip
            arrow
            open={copied}
            title={constants.COPIED}
            PopperProps={{ sx: { zIndex: 2000 } }}>
            <IconButton onClick={copyToClipboardHelper(code)} color={color}>
                {copied ? (
                    <DoneIcon fontSize={size ?? 'small'} />
                ) : (
                    <ContentCopyIcon fontSize={size ?? 'small'} />
                )}
            </IconButton>
        </Tooltip>
    );
}
