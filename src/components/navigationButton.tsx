import { useState } from 'react';
import styled from 'styled-components';

const SCROLL_SPEED = 2;
export enum SCROLL_DIRECTION {
    LEFT = -1,
    RIGHT = +1,
}
interface Props {
    collectionRef: React.MutableRefObject<HTMLDivElement>;
    scrollDirection: SCROLL_DIRECTION;
}
const Wrapper = styled.div<{ direction: SCROLL_DIRECTION }>`
    margin-${(props) =>
        props.direction === SCROLL_DIRECTION.LEFT ? 'right' : 'left'}: 10px;
    cursor: pointer;
    height: 40px;
    margin-top: 10px;
    ${(props) =>
        props.direction === SCROLL_DIRECTION.RIGHT &&
        `transform:rotate(180deg);`}
    &:hover {
        color:#fff;
    }
`;

const NavigationButton = (props: Props) => {
    const [scrollTimeOut, setScrollTimeOut] = useState<NodeJS.Timeout>(null);
    if (!props.collectionRef?.current) {
        return <div />;
    }
    let {
        clientWidth,
        clientHeight,
        scrollWidth,
        scrollHeight,
    } = props.collectionRef.current;
    if (scrollHeight <= clientHeight && scrollWidth <= clientWidth) {
        return <div />;
    }
    const scrollStart = () =>
        setScrollTimeOut(
            setInterval(function () {
                props.collectionRef.current.scrollLeft +=
                    props.scrollDirection * SCROLL_SPEED;
            }, 0)
        );

    const scrollEnd = () => clearTimeout(scrollTimeOut);

    return (
        <Wrapper
            direction={props.scrollDirection}
            onMouseDown={scrollStart}
            onMouseUp={scrollEnd}
            onTouchStart={scrollStart}
            onTouchEnd={scrollEnd}
        >
            <svg
                xmlns="http://www.w3.org/2000/svg"
                height="40"
                viewBox="0 0 24 24"
                width="24px"
                fill="#000000"
            >
                <path d="M0 0h24v24H0V0z" fill="none" />
                <path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z" />
            </svg>
        </Wrapper>
    );
};
export default NavigationButton;
