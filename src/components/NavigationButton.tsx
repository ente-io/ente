import React, { useEffect, useLayoutEffect, useState } from 'react';
import styled from 'styled-components';
import NavigateNext from './NavigateNext';

export enum SCROLL_DIRECTION {
    LEFT = -1,
    RIGHT = +1,
}

interface Props {
    scrollDirection: SCROLL_DIRECTION;
}

const Wrapper = styled.button<{ direction: SCROLL_DIRECTION }>`
    height: 40px;
    width: 40px;
    margin-top: 10px;
    background-color: #191919;
    border: none;
    color: #eee;
    z-index: 1;
    position: absolute;
    ${(props) => props.direction === SCROLL_DIRECTION.LEFT ? 'margin-right: 10px;' : 'margin-left: 10px;'}
    ${(props) => props.direction === SCROLL_DIRECTION.LEFT ? 'left: 0;' : 'right: 0;'}

    & > svg {
        ${(props) =>props.direction === SCROLL_DIRECTION.LEFT && `transform:rotate(180deg);`}
        border-radius: 50%;
        height: 30px;
        width: 30px;
    }

    &:hover > svg {
        background-color: #555;
    }

    &:hover {
        color:#fff;
    }

    &::after {
        content: ' ';
        background: linear-gradient(to ${(props) => props.direction === SCROLL_DIRECTION.LEFT ? 'right' : 'left'}, #191919 5%, rgba(255, 255, 255, 0) 80%);
        position: absolute;
        top: 0;
        width: 40px;
        height: 40px;
        ${(props) => props.direction === SCROLL_DIRECTION.LEFT ? 'left: 40px;' : 'right: 40px;'}
    }
`;

const NavigationButton = ({ scrollDirection, ...rest }) => {
    return (
        <Wrapper
            direction={scrollDirection}
            {...rest}
        >
            <NavigateNext />
        </Wrapper>
    );
};
export default NavigationButton;
