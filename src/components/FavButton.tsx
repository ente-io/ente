import React from 'react';
import styled from 'styled-components';

const HeartUI = styled.button<{
    isClick: boolean;
    size: number;
}>`
    width: ${(props) => props.size}px;
    height: ${(props) => props.size}px;
    float: right;
    background: url('/fav-button.png') no-repeat;
    cursor: pointer;
    background-size: cover;
    border: none;
    ${({ isClick, size }) => isClick &&
        `background-position: -${
            28 * size
        }px;transition: background 1s steps(28);`}
`;

export default function FavButton({ isClick, onClick, size }) {
    return <HeartUI isClick={isClick} onClick={onClick} size={size} />;
}
