import React from 'react';
import styled from 'styled-components';

const Wrapper = styled.button<{ isOpen: boolean }>`
    border: none;
    background-color: #404040;
    position: fixed;
    z-index: 1;
    bottom: 50px;
    display: ${(props) => (!props.isOpen ? 'block' : 'none')};
    right: 50px;
    width: 60px;
    height: 60px;
    border-radius: 50%;
    color: #fff;
`;

export default function SearchButton(props) {
    return (
        <Wrapper isOpen={props.isOpen} onClick={props.onClick}>
            <svg
                xmlns="http://www.w3.org/2000/svg"
                height={props.height}
                viewBox={props.viewBox}
                width={props.width}
            >
                <path d="M20.49 19l-5.73-5.73C15.53 12.2 16 10.91 16 9.5A6.5 6.5 0 1 0 9.5 16c1.41 0 2.7-.47 3.77-1.24L19 20.49 20.49 19zM5 9.5C5 7.01 7.01 5 9.5 5S14 7.01 14 9.5 11.99 14 9.5 14 5 11.99 5 9.5z"></path>
            </svg>
        </Wrapper>
    );
}

SearchButton.defaultProps = {
    height: 35,
    width: 35,
    viewBox: '0 0 25 25',
    open: false,
};
