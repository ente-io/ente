import React, { useState } from 'react';
import constants from 'utils/strings/constants';
import { CopyButtonWrapper } from './styledComponents';
import DoneIcon from '@mui/icons-material/Done';
import ContentCopyIcon from '@mui/icons-material/ContentCopy';
import { Tooltip } from '@mui/material';

export default function CopyButton({ code }) {
    const [copied, setCopied] = useState<boolean>(false);

    const copyToClipboardHelper = (text: string) => () => {
        navigator.clipboard.writeText(text);
        setCopied(true);
        setTimeout(() => setCopied(false), 1000);
    };
    return (
        <Tooltip arrow open={copied} title={constants.COPIED}>
            <CopyButtonWrapper onClick={copyToClipboardHelper(code)}>
                {copied ? (
                    <DoneIcon fontSize="small" />
                ) : (
                    <ContentCopyIcon fontSize="small" />
                )}
            </CopyButtonWrapper>
        </Tooltip>
    );
}
