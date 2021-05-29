import React from 'react';
import styled from 'styled-components';

export const OptionIconWrapper = styled.div`
    display: inline-block;
    opacity: 0;
    font-weight: bold;
    width: 24px;
`;
interface Props {
    onClick: () => void;
}
const OptionIcon = ({onClick}: Props) => (
    <OptionIconWrapper
        onClick={(e) => {
            onClick();
            e.stopPropagation();
        }}
        style={{marginBottom: '2px'}}
    >
        <svg
            xmlns="http://www.w3.org/2000/svg"
            height="20px"
            width="24px"
            viewBox="0 0 24 24"
            fill="#000000"
        >
            <path d="M0 0h24v24H0V0z" fill="none" />
            <path fill="#666" d="M12 8c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z" />
        </svg>
    </OptionIconWrapper>
);
export default OptionIcon;
