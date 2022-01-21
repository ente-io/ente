import styled from 'styled-components';
import { IconButton } from './Container';
import CopyIcon from './icons/CopyIcon';
import React, { useState } from 'react';
import { Tooltip, OverlayTrigger } from 'react-bootstrap';
import TickIcon from './icons/TickIcon';
import EnteSpinner from './EnteSpinner';

const Wrapper = styled.div`
    position: relative;
`;
const CopyButtonWrapper = styled(IconButton)`
    position: absolute;
    top: 0px;
    right: 0px;
    background: none !important;
    margin: 10px;
`;

export const CodeWrapper = styled.div<{ height?: string }>`
    display: flex;
    align-items: center;
    justify-content: center;
    background: #1a1919;
    height: ${(props) => props.height};
    padding: 37px 40px 20px 20px;
    color: white;
    margin: 20px 0;
    width: 100%;
`;

const FreeFlowText = styled.div`
    word-wrap: break-word;
    overflow-wrap: break-word;
    min-width: 30%;
    text-align: left;
`;

type Iprops = React.PropsWithChildren<{
    code: string;
    height?: string;
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
            <CodeWrapper height={props?.height || 'auto'}>
                {props.code ? (
                    <FreeFlowText>{props.code}</FreeFlowText>
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
