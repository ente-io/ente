import React from 'react';
import styled from 'styled-components';

const Wrapper = styled.button`
    border: none;
    background-color: #2dc262;
    position: fixed;
    z-index: 1;
    bottom: 20px;
    right: 100px;
    width: 60px;
    height: 60px;
    border-radius: 50%;
    color: #fff;
`;
export default function AddToCollectionBtn(props) {
    return (
        <Wrapper onClick={props.onClick}>
            <svg
                xmlns="http://www.w3.org/2000/svg"
                height={props.height}
                viewBox={props.viewBox}
                width={props.width}
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
            >
                <line x1="12" y1="5" x2="12" y2="19"></line>
                <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
        </Wrapper>
    );
}

AddToCollectionBtn.defaultProps = {
    height: 24,
    width: 24,
    viewBox: '0 0 24 24',
};
