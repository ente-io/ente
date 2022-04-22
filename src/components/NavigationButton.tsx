import React from 'react';
import styled, { css } from 'styled-components';
import NavigateNext from './icons/NavigateNext';

export enum SCROLL_DIRECTION {
    LEFT = -1,
    RIGHT = +1,
}

const Wrapper = styled.button<{ direction: SCROLL_DIRECTION }>`
    top: 7px;
    height: 50px;
    width: 50px;

    border-radius: 50%;
    background-color: ${({ theme }) => theme.palette.background.paper};
    border: none;
    color: ${({ theme }) => theme.palette.text.primary};
    position: absolute;
    ${(props) =>
        props.direction === SCROLL_DIRECTION.LEFT
            ? css`
                  left: 0;
                  text-align: right;
                  transform: translate(-50%, 0%);
              `
            : css`
                  right: 0;
                  text-align: left;
                  transform: translate(50%, 0%);
              `}

    & > svg {
        ${(props) =>
            props.direction === SCROLL_DIRECTION.LEFT &&
            'transform:rotate(180deg);'}
        border-radius: 50%;
        height: 30px;
        width: 30px;
    }

    &:hover {
        color: #fff;
    }
`;

const NavigationButton = ({ scrollDirection, ...rest }) => (
    <Wrapper direction={scrollDirection} {...rest}>
        <NavigateNext />
    </Wrapper>
);
export default NavigationButton;
