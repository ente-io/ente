import styled from 'styled-components';
import { FreeFlowText, IconButton } from './Container';
import CopyIcon from './icons/CopyIcon';
import React, { useState } from 'react';
import { Tooltip, OverlayTrigger } from 'react-bootstrap';
import TickIcon from './icons/TickIcon';
import EnteSpinner from './EnteSpinner';

const Wrapper = styled.div`
    position: relative;
    margin: 20px 0;
`;
const CopyButtonWrapper = styled(IconButton)`
    position: absolute;
    top: 0px;
    right: 0px;
    background: none !important;
    margin: 10px;
`;

export const CodeWrapper = styled.div`
    display: flex;
    align-items: center;
    justify-content: center;
    background: #1a1919;
    padding: 37px 40px 20px 20px;
    color: white;
    width: 100%;
`;

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

    const RenderCopiedMessage = (props) => {
        const { style, ...rest } = props;
        return (
            <Tooltip
                {...rest}
                style={{ ...style, zIndex: 2001 }}
                id="button-tooltip">
                copied
            </Tooltip>
        );
    };

    return (
        <Wrapper>
            <CodeWrapper>
                {props.code ? (
                    <FreeFlowText style={{ wordBreak: props.wordBreak }}>
                        {props.code}
                    </FreeFlowText>
                ) : (
                    <EnteSpinner />
                )}
            </CodeWrapper>
            {props.code && (
                <OverlayTrigger
                    show={copied}
                    placement="bottom"
                    trigger={'click'}
                    overlay={RenderCopiedMessage}
                    delay={{ show: 200, hide: 800 }}>
                    <CopyButtonWrapper
                        onClick={copyToClipboardHelper(props.code)}
                        style={{
                            background: 'none',
                            ...(copied ? { color: '#51cd7c' } : {}),
                        }}>
                        {copied ? <TickIcon /> : <CopyIcon />}
                    </CopyButtonWrapper>
                </OverlayTrigger>
            )}
        </Wrapper>
    );
};
