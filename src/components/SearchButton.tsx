import React, { Props } from 'react';
import styled from 'styled-components';

const Wrapper = styled.button<{ open: boolean }>`
    border: none;
    background-color: ${(props) => (!props.open ? '#404040' : '#ff6666')};
    position: fixed;
    z-index: 1;
    bottom: 50px;
    right: 50px;
    width: 60px;
    height: 60px;
    border-radius: 50%;
    color: #fff;
`;
export default function SearchButton(props) {
    return (
        <Wrapper open={props.open} onClick={props.onClick}>
            {!props.open ? (
                <svg
                    xmlns="http://www.w3.org/2000/svg"
                    height={props.height}
                    viewBox={props.viewBox}
                    width={props.width}
                >
                    <path d="M20.49 19l-5.73-5.73C15.53 12.2 16 10.91 16 9.5A6.5 6.5 0 1 0 9.5 16c1.41 0 2.7-.47 3.77-1.24L19 20.49 20.49 19zM5 9.5C5 7.01 7.01 5 9.5 5S14 7.01 14 9.5 11.99 14 9.5 14 5 11.99 5 9.5z"></path>
                </svg>
            ) : (
                <svg
                    xmlns="http://www.w3.org/2000/svg"
                    height={props.height}
                    viewBox={props.viewBox}
                    width={props.width}
                >
                    <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"></path>
                </svg>
            )}
        </Wrapper>
    );
}

SearchButton.defaultProps = {
    height: 35,
    width: 35,
    viewBox: '0 0 25 25',
    open: false,
};
