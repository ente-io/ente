import { FreeFlowText } from '../Container';
import React, { useState } from 'react';
import EnteSpinner from '../EnteSpinner';
import { Wrapper, CodeWrapper } from './styledComponents';
import CopyButton from './CopyButton';
import { BoxProps } from '@mui/material';

type Iprops = React.PropsWithChildren<{
    code: string;
    wordBreak?: 'normal' | 'break-all' | 'keep-all' | 'break-word';
}>;

export default function CodeBlock({
    code,
    wordBreak,
    ...props
}: BoxProps<'div', Iprops>) {
    const [copied, setCopied] = useState<boolean>(false);

    const copyToClipboardHelper = (text: string) => () => {
        navigator.clipboard.writeText(text);
        setCopied(true);
        setTimeout(() => setCopied(false), 1000);
    };

    if (!code) {
        return (
            <Wrapper>
                <EnteSpinner />
            </Wrapper>
        );
    }
    return (
        <Wrapper {...props}>
            <CodeWrapper>
                <FreeFlowText style={{ wordBreak: wordBreak }}>
                    {code}
                </FreeFlowText>
            </CodeWrapper>
            <CopyButton
                code={code}
                copied={copied}
                copyToClipboardHelper={copyToClipboardHelper}
            />
        </Wrapper>
    );
}
