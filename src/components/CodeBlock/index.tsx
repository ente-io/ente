import { FreeFlowText } from '../Container';
import React, { useState } from 'react';
import EnteSpinner from '../EnteSpinner';
import { Wrapper, CodeWrapper } from './styledComponents';
import CopyButton from './CopyButton';

type Iprops = React.PropsWithChildren<{
    code: string;
    wordBreak?: 'normal' | 'break-all' | 'keep-all' | 'break-word';
}>;

export const CodeBlock = (props: Iprops) => {
    const [copied, setCopied] = useState<boolean>(false);

    const copyToClipboardHelper = (text: string) => () => {
        navigator.clipboard.writeText(text);
        setCopied(true);
        setTimeout(() => setCopied(false), 1000);
    };

    if (!props.code) {
        return (
            <Wrapper>
                <EnteSpinner />
            </Wrapper>
        );
    }
    return (
        <Wrapper>
            <CodeWrapper>
                <FreeFlowText style={{ wordBreak: props.wordBreak }}>
                    {props.code}
                </FreeFlowText>
            </CodeWrapper>
            <CopyButton
                code={props.code}
                copied={copied}
                copyToClipboardHelper={copyToClipboardHelper}
            />
        </Wrapper>
    );
};
