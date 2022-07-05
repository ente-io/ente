import React from 'react';
import constants from 'utils/strings/constants';
import { CopyButtonWrapper } from './styledComponents';
import DoneIcon from '@mui/icons-material/Done';
import ContentCopyIcon from '@mui/icons-material/ContentCopy';
import { Tooltip } from '@mui/material';

export default function CopyButton({ code, copied, copyToClipboardHelper }) {
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
