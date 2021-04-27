import React from 'react';
import styled from 'styled-components';

const Wrapper = styled.button`
    border: none;
    background-color: #ff6666;
    position: fixed;
    z-index: 1;
    bottom: 20px;
    right: 20px;
    width: 60px;
    height: 60px;
    border-radius: 50%;
    color: #fff;
`;
export default function DeleteBtn(props) {
    return (
        <Wrapper onClick={props.onClick}>
            <svg
                xmlns="http://www.w3.org/2000/svg"
                height={props.height}
                viewBox={props.viewBox}
                width={props.width}
            >
                <path d="M0 0h24v24H0z" fill="none" />
                <path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z" />
            </svg>
        </Wrapper>
    );
}

DeleteBtn.defaultProps = {
    height: 24,
    width: 24,
    viewBox: '0 0 24 24',
};
